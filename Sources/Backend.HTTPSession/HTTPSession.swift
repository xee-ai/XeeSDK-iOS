//  HTTPSession.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

final class HTTPSession: Sendable {
    let configuration: HTTPConfiguration

    private let _responseValidator: HTTPDataResponse.Validator
    private let _session: URLSession
    private let _state: HTTPSessionState
    private let _delegate: URLSession.Delegate
    private let _requestSign: Sign?
    private let _failFast = FailFastTimeout()
    /// A second session, so a hedged read gets its own connection instead of queueing behind a stalled one.
    private let _hedge: Lane?

    private struct Lane: Sendable {
        let session: URLSession
        let state: HTTPSessionState
        let delegate: URLSession.Delegate
    }

    private static func lane(_ configuration: HTTPConfiguration) -> Lane {
        let state = HTTPSessionState()
        let delegate = URLSession.Delegate(sessionState: state, configuration: configuration)
        return Lane(session: URLSession(configuration: configuration.sessionConfiguration, delegate: delegate, delegateQueue: nil), state: state, delegate: delegate)
    }

    typealias Sign = @Sendable (URLRequest, HTTPEndpoint) throws -> URLRequest

    init(
        configuration: HTTPCodableConfiguration,
        requestSign: Sign? = nil,
        responseValidator: @escaping HTTPDataResponse.Validator = HTTPDataResponse.defaultValidator
    ) {
        self.configuration = configuration
        _requestSign = requestSign
        _responseValidator = responseValidator
        let state = HTTPSessionState()
        _state = state
        let delegate = URLSession.Delegate(sessionState: state, configuration: configuration)

        _session = URLSession(
            configuration: configuration.sessionConfiguration,
            delegate: delegate,
            delegateQueue: nil
        )
        _delegate = delegate
        _hedge = configuration.hedgeReadsAfter == nil ? nil : Self.lane(configuration)
    }

    private typealias Received = (Data, HTTPURLResponse, URLSessionTaskMetrics?)

    /// The answer to `urlRequest`; a quick read that is slow is sent a second time on the other session.
    private func receive(_ urlRequest: URLRequest, quick: Bool) async throws -> Received {
        let session = _session, state = _state
        guard quick, let delay = configuration.hedgeReadsAfter, let lane = _hedge else {
            return try await session.data(with: urlRequest, sessionState: state)
        }
        return try await hedged(
            after: delay,
            first: { try await Sendable_(session.data(with: urlRequest, sessionState: state)) },
            second: { try await Sendable_(lane.session.data(with: urlRequest, sessionState: lane.state)) }
        ).value
    }

    func perform<Body>(
        _ request: some HTTPRequest,
        withBaseUrl baseUrl: URL,
        withDecoder decoder: @escaping HTTPDecoder<Body>
    ) async throws(HTTPError) -> HTTPResponse<Body> {
        let state = _state
        let stamp = request.stamp
        let endpoint = request.endpoint
        var urlRequest: URLRequest

        do {
            urlRequest = try request.convertToURLRequest(baseUrl: baseUrl, configuration: configuration)
            if request.isQuickRead {
                urlRequest.timeoutInterval = _failFast.timeout(host: urlRequest.url?.host)
            }
            if let _requestSign {
                urlRequest = try _requestSign(urlRequest, request.endpoint)
            }
        } catch {
            let httpError = HTTPError.perform(endpoint, error: error)
            Log.encodingError(httpError, endpoint: endpoint, stamp: stamp)
            throw httpError
        }

        Log.request(urlRequest, endpoint: endpoint, session: _session.configuration, stamp: stamp)

        let dataResponse: HTTPDataResponse
        do {
            let (data, response, metrics) = try await receive(urlRequest, quick: request.isQuickRead)
            dataResponse = HTTPDataResponse(endpoint: endpoint, response: response, metrics: metrics.map(HTTPMetrics.init), data: data)
        } catch {
            let wrap = error as? URLErrorWithMetrics
            if request.isQuickRead, ((wrap?.error ?? error) as? URLError)?.code == .timedOut {
                _failFast.recordTimeout(host: urlRequest.url?.host)
            }
            let httpError = HTTPError.network(endpoint, metrics: wrap?.metrics.map(HTTPMetrics.init), error: wrap?.error ?? error)
            Log.responseError(httpError, request: urlRequest, stamp: stamp, response: nil)
            throw httpError
        }

        if let error = _responseValidator(dataResponse) {
            let httpError = HTTPError.backend(dataResponse, error: error)
            Log.responseError(httpError, request: urlRequest, stamp: stamp, response: dataResponse)
            throw httpError
        }

        let startDecodeTime = DispatchTime.now()

        var bodyResponse: HTTPResponse<Body>
        do {
            bodyResponse = try await decoder(dataResponse, configuration as? HTTPCodableConfiguration, request)
        } catch {
            let httpError = HTTPError.decoding(dataResponse, error: error)
            Log.responseError(httpError, request: urlRequest, stamp: stamp, response: dataResponse)
            throw httpError
        }
        let endDecodeTime = DispatchTime.now()
        bodyResponse = bodyResponse.replaceDecodingTime(start: startDecodeTime, end: endDecodeTime)
        Log.response(dataResponse.replaceMetrics(bodyResponse.metrics), request: urlRequest, stamp: stamp)
        return bodyResponse
    }
}

/// A received answer carried through `hedged`: `URLSessionTaskMetrics` is not `Sendable`, and nothing mutates it.
private struct Sendable_<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}
