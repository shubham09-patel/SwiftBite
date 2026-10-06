//
//  DeliveryItem.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  SwiftData schemas for persistent cart state, historical receipts, and offline location breadcrumbs.
//

import Foundation
import SwiftData

/// Represents an active item in the customer's cart stored locally via SwiftData.
@Model
public final class DeliveryCartItem {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var itemDescription: String
    public var price: Double
    public var quantity: Int
    public var category: String
    public var imageUrl: String?
    public var addedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        itemDescription: String = "",
        price: Double,
        quantity: Int = 1,
        category: String = "Main",
        imageUrl: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.itemDescription = itemDescription
        self.price = price
        self.quantity = quantity
        self.category = category
        self.imageUrl = imageUrl
        self.addedAt = addedAt
    }

    /// Calculated total line item price.
    public var totalPrice: Double {
        price * Double(quantity)
    }
}

/// Persistent record of an order placed by the user.
@Model
public final class DeliveryOrderRecord {
    @Attribute(.unique) public var id: UUID
    public var orderId: String
    public var restaurantName: String
    public var restaurantAddress: String
    public var deliveryAddress: String
    public var totalAmount: Double
    public var statusRawValue: String
    public var itemCount: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        orderId: String,
        restaurantName: String,
        restaurantAddress: String,
        deliveryAddress: String,
        totalAmount: Double,
        statusRawValue: String,
        itemCount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.orderId = orderId
        self.restaurantName = restaurantName
        self.restaurantAddress = restaurantAddress
        self.deliveryAddress = deliveryAddress
        self.totalAmount = totalAmount
        self.statusRawValue = statusRawValue
        self.itemCount = itemCount
        self.createdAt = createdAt
    }
}

/// Offline telemetry breadcrumb cache for telemetry audits and analytics.
@Model
public final class CachedLocationHistory {
    @Attribute(.unique) public var id: UUID
    public var orderId: String
    public var latitude: Double
    public var longitude: Double
    public var heading: Double
    public var speed: Double
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        orderId: String,
        latitude: Double,
        longitude: Double,
        heading: Double,
        speed: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.orderId = orderId
        self.latitude = latitude
        self.longitude = longitude
        self.heading = heading
        self.speed = speed
        self.timestamp = timestamp
    }
}
