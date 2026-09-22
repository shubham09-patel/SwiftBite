//
//  ActiveOrderTrackerView.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  Root coordinator view integrating interactive MapKit canvas, floating status HUD, and detented sheet.
//
import SwiftUI
import MapKit

public struct ActiveOrderTrackerView: View {
    @State private var trackingViewModel: MapTrackingViewModel
    @State private var cartViewModel: CartViewModel
    @State private var isSheetPresented: Bool = true
    @State private var showingSimulationControls: Bool = false
    
    @MainActor
    public init(
        trackingViewModel: MapTrackingViewModel? = nil,
        cartViewModel: CartViewModel? = nil
    ) {
        self._trackingViewModel = State(initialValue: trackingViewModel ?? MapTrackingViewModel())
        self._cartViewModel = State(initialValue: cartViewModel ?? CartViewModel())
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            // Interactive Map Canvas
            TrackingMapView(viewModel: trackingViewModel)
                .ignoresSafeArea()
            
            // Top HUD Overlay
            floatingTopHUD
            
            // Developer Simulation Overlay
            if showingSimulationControls {
                developerControlOverlay
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            CustomBottomSheet(
                trackingViewModel: trackingViewModel,
                cartViewModel: cartViewModel
            )
            .presentationDetents([.fraction(0.20), .fraction(0.48), .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.48)))
            .interactiveDismissDisabled(true)
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Navigation HUD
    private var floatingTopHUD: some View {
        HStack(spacing: 12) {
            Button { } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(trackingViewModel.isLiveStreamActive ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                    
                    Text(trackingViewModel.connectionPillText)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(trackingViewModel.isLiveStreamActive ? .green : .orange)
                }
                
                Text("Order #\(trackingViewModel.orderId)")
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            Button {
                withAnimation(.spring()) {
                    showingSimulationControls.toggle()
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.purple)
                    .frame(width: 42, height: 42)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
    }
    
    // MARK: - Simulation Control Panel
    private var developerControlOverlay: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Developer Controls")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Button("Close") {
                    withAnimation { showingSimulationControls = false }
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
            
            HStack(spacing: 10) {
                Button("Advance Stage") {
                    trackingViewModel.advanceOrderStatus()
                }
                .buttonStyle(SimulationButtonStyle(color: .blue))
                
                Button("Reset Route") {
                    trackingViewModel.resetSimulation()
                }
                .buttonStyle(SimulationButtonStyle(color: .red))
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 110)
    }
}

private struct SimulationButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
