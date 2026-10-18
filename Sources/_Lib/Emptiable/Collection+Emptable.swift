// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Collection+Emptable.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 27.07.2025.
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
