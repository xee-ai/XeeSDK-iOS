// Derived from Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.)
//
//  SK2ProductsManager.swift
//  XeeSDK
//
//  Created by Aleksei Valiano on 03.10.2024
//

import Foundation

private let log = Log.sk2ProductManager

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
actor SK2ProductsManager {
    private let apiKeyPrefix: String
    private let storage: BackendProductInfoStorage
    private let session: Backend.MainExecutor

    private var products = [String: SK2Product]()
    private let sk2ProductsFetcher = SK2ProductFetcher()

    init(apiKeyPrefix: String, session: Backend.MainExecutor, storage: BackendProductInfoStorage) {
        self.apiKeyPrefix = apiKeyPrefix
        self.session = session
        self.storage = storage
        Task {
            try? await prefetchAllProducts(maxRetries: Int.max)
        }
    }

    private var fetchingAllProducts = false

    func storeProductInfo(productInfo: [BackendProductInfo]) async {
        await storage.set(productInfo: productInfo)
    }

    func getProductInfo(vendorId: String) async -> BackendProductInfo? {
        await storage.productInfo(by: vendorId)
    }

    private func prefetchAllProducts(maxRetries: Int) async throws(XeeError) {
        guard !fetchingAllProducts else { return }
        defer { fetchingAllProducts = false }
        fetchingAllProducts = true

        do throws(HTTPError) {
            let response = try await self.session.fetchProductInfo(apiKeyPrefix: apiKeyPrefix, maxRetries: maxRetries)
            await storage.set(allProductInfo: response)
            let allProductVendorIds = await Set(storage.allProductVendorIds ?? [])
            _ = try? await fetchSK2Products(ids: allProductVendorIds)
        } catch {
            throw error.asXeeError
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
extension SK2ProductsManager {
    func fetchSK2ProductsInSameOrder(ids productIds: [String], fetchPolicy: ProductsFetchPolicy = .default) async throws(XeeError) -> [SK2Product] {
        let products = try await fetchSK2Products(ids: Set(productIds), fetchPolicy: fetchPolicy)

        return productIds.compactMap { id in
            products.first { $0.id == id }
        }
    }

    func fetchSK2Product(id productId: String, fetchPolicy: ProductsFetchPolicy = .default, retryCount: Int = 3) async throws(XeeError) -> SK2Product {
        do throws(XeeError) {
            let products = try await fetchSK2Products(ids: Set([productId]), fetchPolicy: fetchPolicy, retryCount: retryCount)

            guard let product = products.first else {
                throw StoreKitManagerError.noProductIDsFound().asXeeError
            }

            return product
        } catch {
            log.error("fetch SK2Product \(productId) error: \(error)")
            throw error
        }
    }

    func fetchSK2Products(ids productIds: Set<String>, fetchPolicy: ProductsFetchPolicy = .default, retryCount: Int = 3)
        async throws(XeeError) -> [SK2Product]
    {
        guard productIds.isNotEmpty else {
            throw StoreKitManagerError.noProductIDsFound().asXeeError
        }

        if fetchPolicy == .returnCacheDataElseLoad {
            let products = productIds.compactMap { self.products[$0] }
            if products.count == productIds.count {
                return products
            }
        }

        let products = try await sk2ProductsFetcher.fetchProducts(ids: productIds, retryCount: retryCount)

        guard products.isNotEmpty else {
            throw StoreKitManagerError.noProductIDsFound().asXeeError
        }

        products.forEach { self.products[$0.id] = $0 }

        return products
    }
}
