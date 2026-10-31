//  Collection+Emptable.swift
//  XeeSDK
//
//  Created by Xee team.
//

extension Collection {
    @inlinable
    var nonEmptyOrNil: Self? { isEmpty ? nil : self }
    @inlinable
    var isNotEmpty: Bool { !isEmpty }
}

extension Optional where Wrapped: Collection {
    @inlinable
    var nonEmptyOrNil: Self { self?.nonEmptyOrNil }
    @inlinable
    var isEmpty: Bool { self?.isEmpty ?? true }
    @inlinable
    var isNotEmpty: Bool { !isEmpty }
}
