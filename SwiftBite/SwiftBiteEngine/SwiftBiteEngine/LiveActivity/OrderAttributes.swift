//
//  OrderAttributes.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  ActivityKit attributes contract defining immutable order metadata and mutable live content state.
//

import Foundation
import ActivityKit

/// ActivityKit configuration attributes driving Dynamic Island and Lock Screen widgets.
public struct OrderDeliveryAttributes: ActivityAttributes {
    
    /// Dynamic state refreshed via background pushes or local updates.
    public struct ContentState: Codable, Hashable, Sendable {
        public var status: OrderStatus
        public var driverName: String
        public var driverVehicleNumber: String
        public var driverCoordinateLat: Double
        public var driverCoordinateLng: Double
        public var etaMinutes: Int
        public var progressFraction: Double
        public var distanceRemainingMeters: Double
        
        public init(
            status: OrderStatus,
            driverName: String,
            driverVehicleNumber: String,
            driverCoordinateLat: Double,
            driverCoordinateLng: Double,
            etaMinutes: Int,
            progressFraction: Double,
            distanceRemainingMeters: Double
        ) {
            self.status = status
            self.driverName = driverName
            self.driverVehicleNumber = driverVehicleNumber
            self.driverCoordinateLat = driverCoordinateLat
            self.driverCoordinateLng = driverCoordinateLng
            self.etaMinutes = etaMinutes
            self.progressFraction = progressFraction
            self.distanceRemainingMeters = distanceRemainingMeters
        }
    }

    // MARK: - Fixed Static Attributes
    
    public var orderId: String
    public var restaurantName: String
    public var deliveryAddress: String
    public var itemCount: Int
    public var totalAmount: Double
    
    public init(
        orderId: String,
        restaurantName: String,
        deliveryAddress: String,
        itemCount: Int,
        totalAmount: Double
    ) {
        self.orderId = orderId
        self.restaurantName = restaurantName
        self.deliveryAddress = deliveryAddress
        self.itemCount = itemCount
        self.totalAmount = totalAmount
    }
}
