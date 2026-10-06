//
//  DriverLocation.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  Telemetry telemetry snapshot model representing raw and processed driver GPS packets.
//

import Foundation
import CoreLocation

/// Represents a single spatial and kinematic telemetry frame from a delivery driver.
public struct DriverLocation: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let latitude: Double
    public let longitude: Double
    public let heading: Double
    public let speed: Double // in meters per second
    public let altitude: Double?
    public let horizontalAccuracy: Double
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        heading: Double,
        speed: Double,
        altitude: Double? = nil,
        horizontalAccuracy: Double = 5.0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.heading = heading
        self.speed = speed
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.timestamp = timestamp
    }

    /// Computed CoreLocation coordinate representation.
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Speed formatted in kilometers per hour.
    public var speedKmH: Double {
        max(0.0, speed * 3.6)
    }

    /// Speed formatted in miles per hour.
    public var speedMph: Double {
        max(0.0, speed * 2.23694)
    }
}
