//  TimeoutError.swift
//  XeeSDK
//
//  Created by Xee team.
//
//

import Foundation

package struct TimeoutError: LocalizedError {
    package typealias Source = XeeError.Source

    package let errorDescription: String?
    package let source: Source

    init(
        _ seconds: TimeInterval,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.errorDescription = "Task timed out before completion. Timeout: \(seconds) seconds."
        self.source = Source(
            file: file,
            function: function,
            line: line
        )
    }
}
