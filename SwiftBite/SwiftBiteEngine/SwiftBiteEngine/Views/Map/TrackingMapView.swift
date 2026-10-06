//
//  TrackingMapView.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  SwiftUI MapKit canvas rendering real-time route polylines, origin, destination, and animated driver annotations.
//

import SwiftUI
import MapKit

public struct TrackingMapView: View {
    @Bindable var viewModel: MapTrackingViewModel
    
    public init(viewModel: MapTrackingViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: $viewModel.cameraPosition) {
                // Planned Route Polyline (dashed or subtle background track)
                if viewModel.routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: viewModel.routeCoordinates)
                        .stroke(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                }
                
                // Traveled Route Polyline (vibrant delivery progress)
                if viewModel.traveledCoordinates.count >= 2 {
                    MapPolyline(coordinates: viewModel.traveledCoordinates)
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                        )
                }
                
                // Restaurant / Pick-up Pin Annotation
                Annotation("Bistro Gourmet", coordinate: viewModel.restaurantCoordinate) {
                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 38, height: 38)
                                .shadow(color: .orange.opacity(0.4), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "fork.knife")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Restaurant")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                
                // Customer / Delivery Home Annotation
                Annotation("Delivery Home", coordinate: viewModel.customerCoordinate) {
                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 38, height: 38)
                                .shadow(color: .green.opacity(0.4), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "house.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("You")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                
                // Real-time Interpolated Driver Vehicle Marker
                Annotation("Delivery Partner", coordinate: viewModel.driverCurrentCoordinate) {
                    DriverAnnotationView(
                        heading: viewModel.driverCurrentHeading,
                        speedMps: viewModel.driverSpeed,
                        isLive: viewModel.isLiveStreamActive
                    )
                }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            
            // Floating Camera Action Quick-Buttons
            VStack(spacing: 12) {
                Button {
                    viewModel.centerOnDriver()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(viewModel.cameraFollowMode == .driver ? .purple : .primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                
                Button {
                    viewModel.fitRouteOverview()
                } label: {
                    Image(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.cameraFollowMode == .overview ? .purple : .primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                
                Button {
                    viewModel.centerOnCustomer()
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(viewModel.cameraFollowMode == .customer ? .purple : .primary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 170) // Elevate above bottom sheet peek detent
        }
    }
}
//#Preview {
//        
//        TrackingMapView()
//    
//}
