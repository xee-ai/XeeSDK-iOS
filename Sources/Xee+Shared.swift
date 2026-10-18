// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Xee+Shared.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 22.09.2024
//

import Foundation

private let log = Log.default

@XeeActor
extension Xee {
    public static var isActivated: Bool { shared != nil }

    private enum Shared {
        case activated(Xee)
        case activating(Task<Xee, Never>)
    }

    private static var shared: Shared?
    static func set(activatingSDK task: Task<Xee, Never>) {
        if shared == nil { shared = .activating(task) }
    }

    static func set(shared sdk: Xee) { shared = .activated(sdk) }

    @XeeActor
    package static var activatedSDK: Xee {
        get async throws(XeeError) {
            switch shared {
            case let .activated(sdk)?:
                return sdk
            case let .activating(task)?:
                return await task.value
            default:
                throw .notActivated()
            }
        }
    }

    static var optionalSDK: Xee? { // TODO: Deprecated
        if case let .activated(sdk)? = shared {
            sdk
        } else {
            nil
        }
    }

    static func withActivatedSDK<T: Sendable>(
        methodName: MethodName,
        logParams: EventParameters? = nil,
        function: StaticString = #function,
        operation: @XeeActor @Sendable @escaping (Xee) async throws(XeeError) -> T
    ) async throws(XeeError) -> T {
        let stamp = Log.stamp

        Xee.trackSystemEvent(XeeSDKMethodRequestParameters(methodName: methodName, stamp: stamp, params: logParams))
        log.verbose("Calling now: \(function) [\(stamp)]  \(methodName): \(logParams?.description ?? "nil")")

        do {
            let result = try await operation(Xee.activatedSDK)
            Xee.trackSystemEvent(XeeSDKMethodResponseParameters(methodName: methodName, stamp: stamp))
            log.verbose("Completed \(function) [\(stamp)] is successful.")
            return result
        } catch {
            Xee.trackSystemEvent(XeeSDKMethodResponseParameters(methodName: methodName, stamp: stamp, error: String(describing: error)))
            log.error("Completed \(function) [\(stamp)] with error: \(error).")
            throw error
        }
    }

    static func withoutSDK<T: Sendable>(
        methodName: MethodName,
        logParams: EventParameters? = nil,
        function: StaticString = #function,
        operation: @XeeActor @Sendable @escaping () async throws(XeeError) -> T
    ) async throws(XeeError) -> T {
        let stamp = Log.stamp

        Xee.trackSystemEvent(XeeSDKMethodRequestParameters(methodName: methodName, stamp: stamp, params: logParams))
        log.verbose("Calling now: \(function) [\(stamp)].  \(methodName): \(logParams?.description ?? "nil")")

        do {
            let result = try await operation()
            Xee.trackSystemEvent(XeeSDKMethodResponseParameters(methodName: methodName, stamp: stamp))
            log.verbose("Completed \(function) [\(stamp)] is successful.")
            return result
        } catch {
            Xee.trackSystemEvent(XeeSDKMethodResponseParameters(methodName: methodName, stamp: stamp, error: error.localizedDescription))
            log.error("Completed \(function) [\(stamp)] with error: \(error).")
            throw error
        }
    }
}
