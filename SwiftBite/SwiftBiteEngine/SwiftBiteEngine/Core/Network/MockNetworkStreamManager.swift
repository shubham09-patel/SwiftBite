//
//  MockNetworkStreamManager.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  Simulates real-time server-sent WebSocket telemetry packets using Swift AsyncStream.
//
import Foundation
import CoreLocation

/// Actor-isolated telemetry server simulator delivering discrete GPS packets over an AsyncStream.
public actor MockNetworkStreamManager {
    
    // MARK: - Simulation Constants & Route Coordinates
    
    public static let defaultRestaurantCoordinate = CLLocationCoordinate2D(latitude: 37.7915, longitude: -122.4010)
    public static let defaultCustomerCoordinate = CLLocationCoordinate2D(latitude: 37.7650, longitude: -122.4180)
    
    public static let predefinedRouteWaypoints: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.7915, longitude: -122.4010),
        CLLocationCoordinate2D(latitude: 37.7892, longitude: -122.4015),
        CLLocationCoordinate2D(latitude: 37.7865, longitude: -122.4042),
        CLLocationCoordinate2D(latitude: 37.7830, longitude: -122.4080),
        CLLocationCoordinate2D(latitude: 37.7795, longitude: -122.4118),
        CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4140),
        CLLocationCoordinate2D(latitude: 37.7718, longitude: -122.4155),
        CLLocationCoordinate2D(latitude: 37.7682, longitude: -122.4168),
        CLLocationCoordinate2D(latitude: 37.7650, longitude: -122.4180)
    ]
    
    // MARK: - State Management
    
    private var isRunning: Bool = false
    private var isPaused: Bool = false
    private var currentSegmentIndex: Int = 0
    private var segmentProgressFraction: Double = 0.0
    private var continuation: AsyncStream<DriverLocation>.Continuation?
    private var loopTask: Task<Void, Never>?
    
    public init() {}
    
    deinit {
        loopTask?.cancel()
        continuation?.finish()
    }
    
    // MARK: - Public Streaming API
    
    /// Initiates a new telemetry stream emitting real-time GPS packets.
    public func startStream(updateIntervalSeconds: Double = 2.0) -> AsyncStream<DriverLocation> {
        stopStream()
        
        return AsyncStream { continuation in
            // Dedicated background task execution to prevent UI thread starvation
            Task.detached(priority: .utility) { [weak self] in
                await self?.setContinuation(continuation, interval: updateIntervalSeconds)
            }
        }
    }
    
    private func setContinuation(_ cont: AsyncStream<DriverLocation>.Continuation, interval: Double) {
        self.continuation = cont
        self.isRunning = true
        self.isPaused = false
        self.currentSegmentIndex = 0
        self.segmentProgressFraction = 0.0
        
        cont.onTermination = { @Sendable [weak self] _ in
            Task.detached(priority: .utility) { [weak self] in
                await self?.cleanup()
            }
        }
        
        startEmissionLoop(interval: interval)
    }
    
    public func pause() {
        isPaused = true
    }
    
    public func resume() {
        isPaused = false
    }
    
    public func stopStream() {
        cleanup()
    }
    
    public func reset() {
        currentSegmentIndex = 0
        segmentProgressFraction = 0.0
    }
    
    // MARK: - Simulation Loop
    
    private func startEmissionLoop(interval: Double) {
        loopTask?.cancel()
        
        // Detached background task with .utility priority guarantees NO Main Thread interference
        loopTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                // Fetch state safely
                let running = await self.isRunning
                guard running else { break }
                
                let paused = await self.isPaused
                if !paused {
                    if let telemetry = await self.generateNextPacket() {
                        await self.continuation?.yield(telemetry)
                    } else {
                        await self.continuation?.finish()
                        break
                    }
                }
                
                // Add realistic packet arrival jitter (e.g. ±200ms)
                let jitter = Double.random(in: -0.2...0.2)
                let actualSleep = max(0.5, interval + jitter)
                
                // Modern Clock-based Task sleep (Efficient & Thread safe)
                try? await Task.sleep(for: .seconds(actualSleep))
            }
        }
    }
    
    private func generateNextPacket() -> DriverLocation? {
        let waypoints = Self.predefinedRouteWaypoints
        guard waypoints.count >= 2 else { return nil }
        
        guard currentSegmentIndex < waypoints.count - 1 else {
            let last = waypoints.last!
            return DriverLocation(
                latitude: last.latitude,
                longitude: last.longitude,
                heading: 0.0,
                speed: 0.0,
                timestamp: Date()
            )
        }
        
        // Progress through current segment: step ~15% per tick
        segmentProgressFraction += 0.15
        if segmentProgressFraction >= 1.0 {
            segmentProgressFraction = 0.0
            currentSegmentIndex += 1
        }
        
        let targetStart = waypoints[min(currentSegmentIndex, waypoints.count - 2)]
        let targetEnd = waypoints[min(currentSegmentIndex + 1, waypoints.count - 1)]
        
        let interpolatedCoord = targetStart.interpolated(to: targetEnd, fraction: segmentProgressFraction)
        let bearing = targetStart.bearing(to: targetEnd)
        
        // Minor realistic urban GPS jitter
        let latJitter = Double.random(in: -0.000015...0.000015)
        let lonJitter = Double.random(in: -0.000015...0.000015)
        let simulatedSpeed = Double.random(in: 8.5...12.5)
        
        return DriverLocation(
            latitude: interpolatedCoord.latitude + latJitter,
            longitude: interpolatedCoord.longitude + lonJitter,
            heading: bearing,
            speed: simulatedSpeed,
            altitude: 15.0,
            horizontalAccuracy: Double.random(in: 3.5...6.0),
            timestamp: Date()
        )
    }
    
    private func cleanup() {
        isRunning = false
        isPaused = false
        loopTask?.cancel()
        loopTask = nil
        continuation = nil
    }
}
