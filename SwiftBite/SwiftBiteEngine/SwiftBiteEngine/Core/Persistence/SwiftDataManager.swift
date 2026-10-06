//
//  SwiftDataManager.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  Thread-safe SwiftData persistence service for cart, order records, and telemetry caching.
//

import Foundation
import SwiftData

@MainActor
public final class SwiftDataManager {
    public static let shared = SwiftDataManager(inMemory: false)
    public static let preview = SwiftDataManager(inMemory: true)

    public let container: ModelContainer
    public var context: ModelContext {
        container.mainContext
    }

    public init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                DeliveryCartItem.self,
                DeliveryOrderRecord.self,
                CachedLocationHistory.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
            self.container = try ModelContainer(for: schema, configurations: [configuration])
            
            if inMemory {
                populatePreviewData()
            }
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }

    // MARK: - Cart Operations
    
    public func fetchCartItems() -> [DeliveryCartItem] {
        let descriptor = FetchDescriptor<DeliveryCartItem>(sortBy: [SortDescriptor(\.addedAt, order: .forward)])
        return (try? context.fetch(descriptor)) ?? []
    }

    @discardableResult
    public func addOrIncrementItem(
        name: String,
        itemDescription: String,
        price: Double,
        quantity: Int = 1,
        category: String = "Popular"
    ) -> DeliveryCartItem {
        let existing = fetchCartItems().first { $0.name == name }
        if let existing {
            existing.quantity += quantity
            try? context.save()
            return existing
        } else {
            let newItem = DeliveryCartItem(
                name: name,
                itemDescription: itemDescription,
                price: price,
                quantity: quantity,
                category: category
            )
            context.insert(newItem)
            try? context.save()
            return newItem
        }
    }

    public func updateQuantity(for id: UUID, delta: Int) {
        guard let item = fetchCartItems().first(where: { $0.id == id }) else { return }
        item.quantity += delta
        if item.quantity <= 0 {
            context.delete(item)
        }
        try? context.save()
    }

    public func removeItem(id: UUID) {
        guard let item = fetchCartItems().first(where: { $0.id == id }) else { return }
        context.delete(item)
        try? context.save()
    }

    public func clearCart() {
        for item in fetchCartItems() {
            context.delete(item)
        }
        try? context.save()
    }

    // MARK: - Telemetry History Caching
    
    public func cacheLocation(orderId: String, location: DriverLocation) {
        let history = CachedLocationHistory(
            orderId: orderId,
            latitude: location.latitude,
            longitude: location.longitude,
            heading: location.heading,
            speed: location.speed,
            timestamp: location.timestamp
        )
        context.insert(history)
        try? context.save()
    }

    public func fetchCachedLocations(for orderId: String) -> [CachedLocationHistory] {
        let predicate = #Predicate<CachedLocationHistory> { $0.orderId == orderId }
        let descriptor = FetchDescriptor<CachedLocationHistory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Preview Mock Data Seed
    
    private func populatePreviewData() {
        let sampleItems = [
            DeliveryCartItem(name: "Truffle Burger", itemDescription: "Brioche, double wagyu patty, black truffle mayo", price: 18.50, quantity: 2, category: "Burgers"),
            DeliveryCartItem(name: "Crispy Sweet Potato Fries", itemDescription: "Seasoned with rosemary salt and chili dip", price: 6.99, quantity: 1, category: "Sides"),
            DeliveryCartItem(name: "Artisanal Kombucha", itemDescription: "Organic ginger-lemon probiotic refresher", price: 5.50, quantity: 2, category: "Beverages")
        ]
        sampleItems.forEach { context.insert($0) }
        try? context.save()
    }
}
