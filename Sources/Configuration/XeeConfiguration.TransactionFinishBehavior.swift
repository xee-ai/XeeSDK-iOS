//  XeeConfiguration.TransactionFinishBehavior.swift
//  XeeSD
//
//  Created by Aleksei Valiano on 07.09.2025.
//

public extension XeeConfiguration {
    enum TransactionFinishBehavior: Sendable {
        public static let `default` = TransactionFinishBehavior.auto
        case auto
        case manual
    }
}
