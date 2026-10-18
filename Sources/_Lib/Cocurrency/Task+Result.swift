// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  Task+Result.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 08.10.2025.
//

package extension Task where Failure == Never {
    @inlinable
    static func asResultTask<T, E: Error>(
        priority: TaskPriority? = nil,
        xeeResult operation: sending @escaping @isolated(any) () async throws(E) -> T
    ) -> Task<Result<T, E>, Never> where Success == Result<T, E> {
        Task<Result<T, E>, Never>(priority: priority, operation: {
            do throws(E) {
                return try .success(await operation())
            } catch {
                return .failure(error)
            }
        })
    }

    @inlinable
    static func detachedAsResultTask<T, E: Error>(
        priority: TaskPriority? = nil,
        xeeResult operation: sending @escaping @isolated(any) () async throws(E) -> T
    ) -> Task<Result<T, E>, Never> where Success == Result<T, E> {
        Task<Result<T, E>, Never>.detached(priority: priority, operation: {
            do throws(E) {
                return try .success(await operation())
            } catch {
                return .failure(error)
            }
        })
    }
}
