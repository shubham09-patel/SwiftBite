//
//  CLLocationCoordinate2D+Interpolation.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  High-precision spatial geodesy and angular interpolation algorithms.
//

import Foundation
import CoreLocation

// MARK: - Equatable & Hashable Retroactive Conformance
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        abs(lhs.latitude - rhs.latitude) < 0.000001 && abs(lhs.longitude - rhs.longitude) < 0.000001
    }
}

extension CLLocationCoordinate2D: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

// MARK: - Coordinate Spatial Math & Smooth Interpolation
public extension CLLocationCoordinate2D {
    
    private static let earthRadiusMeters: Double = 6_371_000.0
    
    /// Computes the great-circle distance in meters between this coordinate and another using the Haversine formula.
    func distance(to destination: CLLocationCoordinate2D) -> CLLocationDistance {
        let lat1Rad = latitude * .pi / 180.0
        let lon1Rad = longitude * .pi / 180.0
        let lat2Rad = destination.latitude * .pi / 180.0
        let lon2Rad = destination.longitude * .pi / 180.0
        
        let deltaLat = lat2Rad - lat1Rad
        let deltaLon = lon2Rad - lon1Rad
        
        let a = sin(deltaLat / 2.0) * sin(deltaLat / 2.0) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLon / 2.0) * sin(deltaLon / 2.0)
        
        let c = 2.0 * atan2(sqrt(a), sqrt(max(0.0, 1.0 - a)))
        return Self.earthRadiusMeters * c
    }
    
    /// Computes the initial forward bearing (azimuth in degrees, 0..<360) from this coordinate to destination.
    func bearing(to destination: CLLocationCoordinate2D) -> Double {
        let lat1Rad = latitude * .pi / 180.0
        let lat2Rad = destination.latitude * .pi / 180.0
        let deltaLonRad = (destination.longitude - longitude) * .pi / 180.0
        
        let y = sin(deltaLonRad) * cos(lat2Rad)
        let x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLonRad)
        
        let radiansBearing = atan2(y, x)
        let degreesBearing = radiansBearing * 180.0 / .pi
        return (degreesBearing + 360.0).truncatingRemainder(dividingBy: 360.0)
    }
    
    /// Computes a high-precision spherical linear intermediate coordinate (slerp) between self and destination.
    /// - Parameters:
    ///   - destination: The target coordinate.
    ///   - fraction: The interpolation fraction in `0.0 ... 1.0`.
    /// - Returns: Smoothly interpolated coordinate along the great circle.
    func interpolated(to destination: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
        let t = min(max(fraction, 0.0), 1.0)
        
        // Fast path for endpoints
        if t == 0.0 { return self }
        if t == 1.0 { return destination }
        
        let distanceMeters = distance(to: destination)
        if distanceMeters < 0.1 {
            // Micro-distance fallback to flat planar linear interpolation to avoid division by zero
            return CLLocationCoordinate2D(
                latitude: latitude + (destination.latitude - latitude) * t,
                longitude: longitude + (destination.longitude - longitude) * t
            )
        }
        
        let delta = distanceMeters / Self.earthRadiusMeters
        let sinDelta = sin(delta)
        
        guard sinDelta > 0.000001 else {
            return self
        }
        
        let lat1 = latitude * .pi / 180.0
        let lon1 = longitude * .pi / 180.0
        let lat2 = destination.latitude * .pi / 180.0
        let lon2 = destination.longitude * .pi / 180.0
        
        let a = sin((1.0 - t) * delta) / sinDelta
        let b = sin(t * delta) / sinDelta
        
        let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
        let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
        let z = a * sin(lat1) + b * sin(lat2)
        
        let finalLat = atan2(z, sqrt(x * x + y * y))
        let finalLon = atan2(y, x)
        
        return CLLocationCoordinate2D(
            latitude: finalLat * 180.0 / .pi,
            longitude: finalLon * 180.0 / .pi
        )
    }
    
    /// Interpolates heading/bearing smoothly across the 0/360 degree boundary without visual spin jumps.
    /// - Parameters:
    ///   - fromBearing: Current bearing in degrees (0..<360).
    ///   - toBearing: Target bearing in degrees (0..<360).
    ///   - fraction: Normalized progress (0.0 ... 1.0).
    /// - Returns: Shortest angular path bearing in degrees.
    static func interpolateHeading(from fromBearing: Double, to toBearing: Double, fraction: Double) -> Double {
        let t = min(max(fraction, 0.0), 1.0)
        
        // Normalize angular delta to [-180, +180]
        var delta = (toBearing - fromBearing).truncatingRemainder(dividingBy: 360.0)
        if delta > 180.0 {
            delta -= 360.0
        } else if delta < -180.0 {
            delta += 360.0
        }
        
        var result = fromBearing + delta * t
        result = result.truncatingRemainder(dividingBy: 360.0)
        if result < 0 {
            result += 360.0
        }
        return result
    }
}
