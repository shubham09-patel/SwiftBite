//
//  LocationManager.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  CoreLocation wrapper providing reactive location and heading streaming using Swift's @Observable.
//

import Foundation
import CoreLocation
import Observation

/// Reactive manager handling customer CoreLocation permissions, live coordinates, and orientation.
@Observable
@MainActor
public final class LocationManager: NSObject {
    private let locationManager = CLLocationManager()

    public var userLocation: CLLocationCoordinate2D?
    public var heading: Double?
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public var isUpdatingLocation: Bool = false
    public var errorMessage: String?

    public override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 5.0 // Updates every 5 meters
        self.locationManager.headingFilter = 2.0  // Updates every 2 degrees
        self.authorizationStatus = locationManager.authorizationStatus
    }

    /// Requests standard when-in-use location permissions.
    public func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Starts streaming device coordinates and compass heading.
    public func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestWhenInUseAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
        isUpdatingLocation = true
    }

    /// Stops tracking device location to conserve battery.
    public func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        isUpdatingLocation = false
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdatingLocation()
            } else if status == .denied || status == .restricted {
                self.stopUpdatingLocation()
                self.errorMessage = "Location permission denied. Enable in Settings for live delivery distance."
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location.coordinate
            self.errorMessage = nil
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            if newHeading.headingAccuracy >= 0 {
                self.heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
        }
    }
}
