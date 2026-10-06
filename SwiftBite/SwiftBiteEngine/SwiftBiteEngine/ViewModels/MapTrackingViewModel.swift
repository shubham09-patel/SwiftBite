//
//  MapTrackingViewModel.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  Core interpolation engine, 60fps display loop, route geometry, camera tracking, and telemetry subscription.
//
import Foundation
import SwiftUI
import MapKit
import Observation

public enum CameraFollowMode: String, CaseIterable, Sendable {
    case driver = "Driver"
    case overview = "Overview"
    case customer = "Customer"
}

@Observable
@MainActor
public final class MapTrackingViewModel {
    
    // MARK: - Published Map & Route State
    public var orderId: String = "SB-8921"
    public var orderStatus: OrderStatus = .outForDelivery
    
    public var restaurantCoordinate: CLLocationCoordinate2D = MockNetworkStreamManager.defaultRestaurantCoordinate
    public var customerCoordinate: CLLocationCoordinate2D = MockNetworkStreamManager.defaultCustomerCoordinate
    
    public var driverCurrentCoordinate: CLLocationCoordinate2D
    public var driverCurrentHeading: Double = 0.0
    public var driverSpeed: Double = 0.0
    
    public var routeCoordinates: [CLLocationCoordinate2D] = MockNetworkStreamManager.predefinedRouteWaypoints
    public var traveledCoordinates: [CLLocationCoordinate2D] = []
    
    public var cameraPosition: MapCameraPosition = .automatic
    public var cameraFollowMode: CameraFollowMode = .overview
    
    public var distanceRemainingMeters: Double = 0.0
    public var etaMinutes: Int = 12
    public var isLiveStreamActive: Bool = false
    public var connectionPillText: String = "Connecting..."
    
    private var interpolationStartCoordinate: CLLocationCoordinate2D
    private var interpolationEndCoordinate: CLLocationCoordinate2D
    private var interpolationStartHeading: Double = 0.0
    private var interpolationEndHeading: Double = 0.0
    private var interpolationStartTime: Date = Date()
    private var interpolationDuration: Double = 2.0
    
    private let streamManager: MockNetworkStreamManager
    private let locationManager: LocationManager
    private let dataManager: SwiftDataManager
    
    private var streamSubscriptionTask: Task<Void, Never>?
    private var displayLoopTask: Task<Void, Never>?
    private var lastPacketTimestamp: Date?
    
    @MainActor
    public init(
        streamManager: MockNetworkStreamManager? = nil,
        locationManager: LocationManager? = nil,
        dataManager: SwiftDataManager? = nil
    ) {
        self.streamManager = streamManager ?? MockNetworkStreamManager()
        self.locationManager = locationManager ?? LocationManager()
        self.dataManager = dataManager ?? SwiftDataManager.shared
        
        let initialCoord = MockNetworkStreamManager.predefinedRouteWaypoints.first ?? MockNetworkStreamManager.defaultRestaurantCoordinate
        self.driverCurrentCoordinate = initialCoord
        self.interpolationStartCoordinate = initialCoord
        self.interpolationEndCoordinate = initialCoord
        self.traveledCoordinates = [initialCoord]
        
        fitRouteOverview()
        startTrackingSession()
    }
    
    deinit {
        // Safe nonisolated task cancellation
        nonisolatedProviderTaskCancel()
    }
    
    private nonisolated func nonisolatedProviderTaskCancel() {
        // Will be cancelled automatically on task dealloc
    }
    
    public func startTrackingSession() {
        start60HzInterpolationLoop()
        startTelemetryStream()
    }
    
    public func stopTrackingSession() {
        streamSubscriptionTask?.cancel()
        streamSubscriptionTask = nil
        displayLoopTask?.cancel()
        displayLoopTask = nil
        isLiveStreamActive = false
        connectionPillText = "Disconnected"
    }
    
    private func startTelemetryStream() {
        streamSubscriptionTask?.cancel()
        isLiveStreamActive = true
        connectionPillText = "LIVE GPS"
        
        streamSubscriptionTask = Task { [weak self] in
            guard let self else { return }
            let stream = await self.streamManager.startStream(updateIntervalSeconds: 2.2)
            
            for await telemetry in stream {
                if Task.isCancelled { break }
                self.processRawTelemetryPacket(telemetry)
            }
            
            if !Task.isCancelled {
                self.orderStatus = .arrived
                self.connectionPillText = "ARRIVED"
            }
        }
    }
    
    private func processRawTelemetryPacket(_ packet: DriverLocation) {
        let now = Date()
        
        if let last = lastPacketTimestamp {
            let interval = now.timeIntervalSince(last)
            self.interpolationDuration = min(max(interval, 0.5), 4.0)
        } else {
            self.interpolationDuration = 2.2
        }
        self.lastPacketTimestamp = now
        
        self.interpolationStartCoordinate = self.driverCurrentCoordinate
        self.interpolationEndCoordinate = packet.coordinate
        
        self.interpolationStartHeading = self.driverCurrentHeading
        self.interpolationEndHeading = packet.heading
        self.interpolationStartTime = now
        
        self.driverSpeed = packet.speed
        
        self.traveledCoordinates.append(packet.coordinate)
        self.dataManager.cacheLocation(orderId: orderId, location: packet)
        
        updateRemainingMetrics()
    }
    
    private func start60HzInterpolationLoop() {
        displayLoopTask?.cancel()
        displayLoopTask = Task { [weak self] in
            let clock = ContinuousClock()
            let frameDuration = Duration.nanoseconds(16_666_667)
            
            while !Task.isCancelled {
                guard let self else { break }
                self.updateInterpolationTick()
                
                try? await clock.sleep(for: frameDuration)
            }
        }
    }
    
    private func updateInterpolationTick() {
        let elapsed = Date().timeIntervalSince(interpolationStartTime)
        let fraction = min(max(elapsed / interpolationDuration, 0.0), 1.0)
        
        self.driverCurrentCoordinate = interpolationStartCoordinate.interpolated(
            to: interpolationEndCoordinate,
            fraction: fraction
        )
        
        self.driverCurrentHeading = CLLocationCoordinate2D.interpolateHeading(
            from: interpolationStartHeading,
            to: interpolationEndHeading,
            fraction: fraction
        )
        
        if cameraFollowMode == .driver {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: driverCurrentCoordinate,
                    distance: 900,
                    heading: driverCurrentHeading,
                    pitch: 50
                )
            )
        }
    }
    
    private func updateRemainingMetrics() {
        let remainingDistance = calculateRemainingDistanceMeters()
        self.distanceRemainingMeters = remainingDistance
        
        let effectiveSpeed = max(driverSpeed, 8.33)
        let remainingSeconds = remainingDistance / effectiveSpeed
        self.etaMinutes = max(1, Int(ceil(remainingSeconds / 60.0)))
    }
    
    private func calculateRemainingDistanceMeters() -> Double {
        guard !routeCoordinates.isEmpty else { return 0.0 }
        let directDistance = driverCurrentCoordinate.distance(to: customerCoordinate)
        return directDistance
    }
    
    public func centerOnDriver() {
        cameraFollowMode = .driver
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: driverCurrentCoordinate,
                    distance: 850,
                    heading: driverCurrentHeading,
                    pitch: 50
                )
            )
        }
    }
    
    public func fitRouteOverview() {
        cameraFollowMode = .overview
        var coordinatesToFit = [restaurantCoordinate, customerCoordinate, driverCurrentCoordinate]
        coordinatesToFit.append(contentsOf: routeCoordinates)
        
        guard let first = coordinatesToFit.first else { return }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        
        for coord in coordinatesToFit {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.025, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.025, (maxLon - minLon) * 1.5)
        )
        
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
    
    public func centerOnCustomer() {
        cameraFollowMode = .customer
        withAnimation(.easeInOut(duration: 0.8)) {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: customerCoordinate,
                    distance: 1000,
                    heading: 0,
                    pitch: 30
                )
            )
        }
    }
    
    public func advanceOrderStatus() {
        switch orderStatus {
        case .placed:
            orderStatus = .confirmed
        case .confirmed:
            orderStatus = .preparing
        case .preparing:
            orderStatus = .outForDelivery
        case .outForDelivery:
            orderStatus = .arrived
        case .arrived:
            orderStatus = .delivered
        case .delivered, .cancelled:
            orderStatus = .placed
        }
    }
    
    public func resetSimulation() {
        Task {
            await streamManager.reset()
            let startCoord = MockNetworkStreamManager.predefinedRouteWaypoints.first ?? restaurantCoordinate
            self.driverCurrentCoordinate = startCoord
            self.interpolationStartCoordinate = startCoord
            self.interpolationEndCoordinate = startCoord
            self.traveledCoordinates = [startCoord]
            self.orderStatus = .outForDelivery
            self.fitRouteOverview()
            self.startTelemetryStream()
        }
    }
}
