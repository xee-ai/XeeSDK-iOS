//  XeeConfiguration.TransactionFinishBehavior.swift
//  XeeSD
//
//  Created by Xee team.
//

public extension XeeConfiguration {
    enum TransactionFinishBehavior: Sendable {
        public static let `default` = TransactionFinishBehavior.auto
        case auto
        case manual
    }
}
