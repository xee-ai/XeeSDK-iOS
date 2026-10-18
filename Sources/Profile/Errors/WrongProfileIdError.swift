// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  WrongProfileIdError.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 05.09.2025.
//

import Foundation

struct WrongProfileIdError: Error {
    let source: XeeError.Source
    init(
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.source = XeeError.Source(file: file, function: function, line: line)
    }
}

extension WrongProfileIdError: CustomStringConvertible {
    var description: String {
        "WrongProfileError(\(source))"
    }
}
