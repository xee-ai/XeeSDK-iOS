//  Result+async.swift
//  XeeSDK
//
//  Created by Xee team.
//

package extension Result {
    @inlinable
    static func from(_ body: sending @escaping @isolated(any) () async throws(Failure) -> Success) async -> Self where Success: Sendable {
        do throws(Failure) {
            return try .success(await body())
        } catch {
            return .failure(error)
        }
    }
}
