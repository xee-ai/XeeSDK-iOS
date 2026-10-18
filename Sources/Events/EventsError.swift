// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  EventsError.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 07.10.2022.
//

enum EventsError: Error {
    case sending(XeeError.Source, error: Error)
    case encoding(XeeError.Source, error: Error)
    case decoding(XeeError.Source, error: Error)
}

extension EventsError: CustomStringConvertible {
    var description: String {
        switch self {
        case let .sending(source, error: error):
            "EventsError.sending(\(source), \(error))"
        case let .encoding(source, error: error):
            "EventsError.encoding(\(source), \(error))"
        case let .decoding(source, error: error):
            "EventsError.decoding(\(source), \(error))"
        }
    }
}

extension EventsError {
    var source: XeeError.Source {
        switch self {
        case let .sending(src, _),
             let .encoding(src, _),
             let .decoding(src, _): src
        }
    }

    var isInterrupted: Bool {
        switch self {
        case let .sending(_, error): (error as? HTTPError)?.isCancelled ?? false
        default: false
        }
    }

    var originalError: Error? {
        switch self {
        case let .sending(_, error): error
        case let .encoding(_, error),
             let .decoding(_, error): error
        }
    }
}

extension EventsError {
    static func sending(
        _ error: Error,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        .sending(
            XeeError.Source(
                file: file,
                function: function,
                line: line
            ),
            error: error
        )
    }

    static func encoding(
        _ error: Error,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        .encoding(
            XeeError.Source(
                file: file,
                function: function,
                line: line
            ),
            error: error
        )
    }

    static func decoding(
        _ error: Error,
        file: String = #fileID, function: String = #function, line: UInt = #line
    ) -> Self {
        .decoding(
            XeeError.Source(
                file: file,
                function: function,
                line: line
            ),
            error: error
        )
    }
}
