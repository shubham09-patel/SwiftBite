//
//  OrderStatus.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  State machine lifecycle representing the progression of a food delivery order.
//

import Foundation
import SwiftUI

/// Defines the operational lifecycle states of an active delivery order.
public enum OrderStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case placed
    case confirmed
    case preparing
    case outForDelivery
    case arrived
    case delivered
    case cancelled

    public var id: String { rawValue }

    /// Human-readable title for UI headers and Live Activities.
    public var title: String {
        switch self {
        case .placed:
            return "Order Placed"
        case .confirmed:
            return "Order Confirmed"
        case .preparing:
            return "Kitchen is Preparing"
        case .outForDelivery:
            return "Driver is on the way"
        case .arrived:
            return "Driver has Arrived"
        case .delivered:
            return "Order Delivered"
        case .cancelled:
            return "Order Cancelled"
        }
    }

    /// Secondary status detail.
    public var subtitle: String {
        switch self {
        case .placed:
            return "Waiting for restaurant confirmation"
        case .confirmed:
            return "Restaurant accepted your order"
        case .preparing:
            return "Chef is crafting your delicious meal"
        case .outForDelivery:
            return "Your delivery partner is en route to you"
        case .arrived:
            return "Please meet your driver at the entrance"
        case .delivered:
            return "Enjoy your meal! Rate your experience"
        case .cancelled:
            return "This order has been cancelled"
        }
    }

    /// SF Symbol icon name.
    public var systemImageName: String {
        switch self {
        case .placed:
            return "doc.text.fill"
        case .confirmed:
            return "checkmark.circle.fill"
        case .preparing:
            return "fork.knife.circle.fill"
        case .outForDelivery:
            return "bicycle.circle.fill"
        case .arrived:
            return "figure.walk.motion"
        case .delivered:
            return "bag.fill.badge.checkmark"
        case .cancelled:
            return "xmark.octagon.fill"
        }
    }

    /// Progress percentage between 0.0 and 1.0 for progress gauges.
    public var progressFraction: Double {
        switch self {
        case .placed:
            return 0.10
        case .confirmed:
            return 0.25
        case .preparing:
            return 0.50
        case .outForDelivery:
            return 0.75
        case .arrived:
            return 0.90
        case .delivered:
            return 1.00
        case .cancelled:
            return 0.00
        }
    }

    /// Color representation for SwiftUI badge and map accents.
    public var tintColor: Color {
        switch self {
        case .placed:
            return .blue
        case .confirmed:
            return .teal
        case .preparing:
            return .orange
        case .outForDelivery:
            return .purple
        case .arrived:
            return .green
        case .delivered:
            return .mint
        case .cancelled:
            return .red
        }
    }

    /// Whether tracking the driver on the map is active.
    public var isTrackingActive: Bool {
        self == .outForDelivery || self == .arrived
    }
}
