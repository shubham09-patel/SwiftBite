//
//  DriverAnnotationView.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  High-performance animated delivery partner marker with dynamic radar pulse and heading orientation.
//

import SwiftUI

public struct DriverAnnotationView: View {
    public let heading: Double
    public let speedMps: Double
    public let isLive: Bool
    
    @State private var isPulsing: Bool = false
    
    public init(heading: Double, speedMps: Double = 0.0, isLive: Bool = true) {
        self.heading = heading
        self.speedMps = speedMps
        self.isLive = isLive
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            // Speed indicator badge pill
            if speedMps > 1.0 {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                    Text("\(Int(speedMps * 3.6)) km/h")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Driver Vehicle Marker with Radar Rings
            ZStack {
                // Expanding radar pulse wave
                if isLive {
                    Circle()
                        .stroke(Color.purple.opacity(isPulsing ? 0.0 : 0.6), lineWidth: isPulsing ? 1.0 : 4.0)
                        .frame(width: isPulsing ? 68 : 42, height: isPulsing ? 68 : 42)
                        .scaleEffect(isPulsing ? 1.25 : 0.9)
                        .animation(
                            .easeOut(duration: 1.6).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }
                
                // Soft glow halo
                Circle()
                    .fill(Color.purple.opacity(0.25))
                    .frame(width: 52, height: 52)
                
                // Outer circle badge
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.08, green: 0.08, blue: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.purple, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: Color.purple.opacity(0.5), radius: 8, x: 0, y: 4)
                
                // Directional arrow indicating heading
                Image(systemName: "location.north.fill")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.cyan)
                    .offset(y: -18)
                    .rotationEffect(.degrees(heading))
                
                // Vehicle Delivery Partner Icon
                Image(systemName: "bicycle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    .rotationEffect(.degrees(heading))
            }
            .frame(width: 70, height: 70)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        DriverAnnotationView(heading: 45, speedMps: 9.5, isLive: true)
    }
}
