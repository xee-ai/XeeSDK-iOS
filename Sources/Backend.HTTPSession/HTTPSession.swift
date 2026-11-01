//  HTTPSession.swift
//  XeeSDK
//
//  Created by Xee team.
//

import Foundation

final class HTTPSession: Sendable {
    let configuration: HTTPConfiguration

    private let _responseValidator: HTTPDataResponse.Validator
    private let _lanes: Lanes
    private let _requestSign: Sign?
    private let _failFast = FailFastTimeout()

    typealias Sign = @Sendable (URLRequest, HTTPEndpoint) throws -> URLRequest

    /// One URLSession with its own state and connection.
    private struct Lane: Sendable {
        let session: URLSession
        let state: HTTPSessionState
        let delegate: URLSession.Delegate

        init(_ configuration: HTTPConfiguration) {
            let state = HTTPSessionState()
            let delegate = URLSession.Delegate(sessionState: state, configuration: configuration)
            session = URLSession(configuration: configuration.sessionConfiguration, delegate: delegate, delegateQueue: nil)
            self.state = state
            self.delegate = delegate
        }
    }

    /// The main session and, when reads are hedged, a spare one with its own connection. When the spare answers a slow
    /// read, it becomes the main session for every request, so the next calls do not wait on the connection that stalled;
    /// the old one is let go once its calls end, and a new spare takes its place.
    private final class Lanes: @unchecked Sendable {
        private let lock = NSLock()
        private let configuration: HTTPConfiguration
        private var main: Lane
        private var spare: Lane?
        private(set) var hedgeWins = 0

        init(_ configuration: HTTPConfiguration) {
            self.configuration = configuration
            main = Lane(configuration)
            spare = configuration.hedgeReadsAfter == nil ? nil : Lane(configuration)
        }

        var current: (main: Lane, spare: Lane?) {
            lock.lock()
            defer { lock.unlock() }
            return (main, spare)
        }

        /// The spare answered before `lost` did: it takes over, unless another read already made that change.
        func promoteSpare(over lost: Lane) {
            lock.lock()
            defer { lock.unlock() }
            guard let spare, lost.session === main.session else { return }
            main.session.finishTasksAndInvalidate()
            main = spare
            self.spare = Lane(configuration)
            hedgeWins += 1
        }
    }

    /// How many times the spare connection took over from a stalled one.
    var hedgeWins: Int { _lanes.hedgeWins }

    init(
        configuration: HTTPCodableConfiguration,
        requestSign: Sign? = nil,
        responseValidator: @escaping HTTPDataResponse.Validator = HTTPDataResponse.defaultValidator
    ) {
        self.configuration = configuration
        _requestSign = requestSign
        _responseValidator = responseValidator
        _lanes = Lanes(configuration)
    }

    private typealias Received = (Data, HTTPURLResponse, URLSessionTaskMetrics?)

    /// The answer to `urlRequest`; a quick read that is slow is sent a second time on the spare session.
    private func receive(_ urlRequest: URLRequest, quick: Bool) async throws -> Received {
        let (main, spare) = _lanes.current
        guard quick, let delay = configuration.hedgeReadsAfter, let spare else {
            return try await main.session.data(with: urlRequest, sessionState: main.state)
        }
        let race = try await hedgedRace(
            after: delay,
            first: { try await Sendable_(main.session.data(with: urlRequest, sessionState: main.state)) },
            second: { try await Sendable_(spare.session.data(with: urlRequest, sessionState: spare.state)) }
        )
        if race.secondWon { _lanes.promoteSpare(over: main) }
        return race.value.value
    }

    func perform<Body>(
        _ request: some HTTPRequest,
        withBaseUrl baseUrl: URL,
        withDecoder decoder: @escaping HTTPDecoder<Body>
    ) async throws(HTTPError) -> HTTPResponse<Body> {
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

        Log.request(urlRequest, endpoint: endpoint, session: _lanes.current.main.session.configuration, stamp: stamp)

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
