//
//  CustomBottomSheet.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  Interactive multi-detent sheet with order lifecycle stepper, driver card, and dynamic cart breakdown.
//

import SwiftUI

public struct CustomBottomSheet: View {
    @Bindable var trackingViewModel: MapTrackingViewModel
    @Bindable var cartViewModel: CartViewModel
    
    @State private var promoInput: String = ""
    @State private var showingPromoField: Bool = false
    
    public init(trackingViewModel: MapTrackingViewModel, cartViewModel: CartViewModel) {
        self.trackingViewModel = trackingViewModel
        self.cartViewModel = cartViewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Peek Header Section: Order Status & Live ETA
                statusHeaderSection
                
                // Animated Step Progress Bar
                stepperSection
                
                // Driver Information & Contact Card
                driverCardSection
                
                Divider()
                    .padding(.horizontal)
                
                // Active Cart Breakdown & Item Counter
                cartItemsSection
                
                // Dynamic Bill Receipt & Tip Selector
                billSummarySection
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    // MARK: - Header Section
    
    private var statusHeaderSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(trackingViewModel.orderStatus.tintColor)
                        .frame(width: 8, height: 8)
                    Text(trackingViewModel.orderStatus.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Text(trackingViewModel.orderStatus.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // ETA Pill Badge
            VStack(alignment: .trailing, spacing: 2) {
                Text(trackingViewModel.orderStatus == .arrived ? "ARRIVED" : "\(trackingViewModel.etaMinutes) MIN")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.purple)
                
                Text("Estimated Arrival")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Stepper Progress Bar
    
    private var stepperSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    // Filled Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(trackingViewModel.orderStatus.progressFraction), height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: trackingViewModel.orderStatus.progressFraction)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text("Confirmed")
                    .font(.caption2)
                    .foregroundColor(trackingViewModel.orderStatus.progressFraction >= 0.25 ? .primary : .secondary)
                Spacer()
                Text("Kitchen")
                    .font(.caption2)
                    .foregroundColor(trackingViewModel.orderStatus.progressFraction >= 0.50 ? .primary : .secondary)
                Spacer()
                Text("En Route")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(trackingViewModel.orderStatus.progressFraction >= 0.75 ? .purple : .secondary)
                Spacer()
                Text("Delivered")
                    .font(.caption2)
                    .foregroundColor(trackingViewModel.orderStatus.progressFraction >= 1.00 ? .green : .secondary)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Driver Information Card
    
    private var driverCardSection: some View {
        HStack(spacing: 14) {
            // Driver Avatar
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                    .foregroundColor(.gray.opacity(0.7))
                
                // Verified checkmark
                Circle()
                    .fill(Color.blue)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            // Name & Vehicle
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Marcus Vance")
                        .font(.system(size: 16, weight: .bold))
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Text("4.9")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                
                Text("EV Scooter • KA-01-EV-8842")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Call & Message Action Buttons
            HStack(spacing: 10) {
                Button {
                    // Simulate messaging action
                } label: {
                    Image(systemName: "message.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.purple)
                        .frame(width: 40, height: 40)
                        .background(Color.purple.opacity(0.12))
                        .clipShape(Circle())
                }
                
                Button {
                    // Simulate direct phone call action
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.green)
                        .frame(width: 40, height: 40)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Cart Items Breakdown
    
    private var cartItemsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Order (\(cartViewModel.totalItemCount) items)")
                    .font(.headline)
                Spacer()
                Button("Add Items") {
                    cartViewModel.addItem(name: "Crispy Churros", description: "Cinnamon sugar, dulce de leche", price: 7.00, category: "Desserts")
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
            
            ForEach(cartViewModel.items) { item in
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.system(size: 15, weight: .semibold))
                        Text("$\(String(format: "%.2f", item.price)) each")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Quantity Modifier Stepper
                    HStack(spacing: 12) {
                        Button {
                            cartViewModel.decrement(item: item)
                        } label: {
                            Image(systemName: item.quantity == 1 ? "trash" : "minus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(item.quantity == 1 ? .red : .primary)
                                .frame(width: 28, height: 28)
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .clipShape(Circle())
                        }
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 14, weight: .bold))
                            .frame(minWidth: 16)
                        
                        Button {
                            cartViewModel.increment(item: item)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 28, height: 28)
                                .background(Color(uiColor: .tertiarySystemBackground))
                                .clipShape(Circle())
                        }
                    }
                    .padding(4)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(Capsule())
                    
                    Text("$\(String(format: "%.2f", item.totalPrice))")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Bill Receipt & Tip Selector
    
    private var billSummarySection: some View {
        VStack(spacing: 12) {
            // Tip Selection Bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Tip your delivery hero")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    tipButton(title: "10%", percentage: 0.10)
                    tipButton(title: "15%", percentage: 0.15)
                    tipButton(title: "20%", percentage: 0.20)
                    tipButton(title: "Custom", percentage: nil)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Financial Breakdown Rows
            receiptRow(title: "Subtotal", amount: cartViewModel.subtotal)
            receiptRow(title: "Delivery Fee", amount: cartViewModel.deliveryFee)
            receiptRow(title: "Service Fee (5%)", amount: cartViewModel.serviceFee)
            receiptRow(title: "Estimated Taxes", amount: cartViewModel.tax)
            receiptRow(title: "Tip", amount: cartViewModel.tipAmount)
            
            if cartViewModel.discountAmount > 0 {
                HStack {
                    Text("Promo (\(cartViewModel.appliedPromoCode ?? ""))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                    Text("-$\(String(format: "%.2f", cartViewModel.discountAmount))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            Divider()
            
            // Grand Total
            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text("$\(String(format: "%.2f", cartViewModel.grandTotal))")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Component Helpers
    
    private func receiptRow(title: String, amount: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text("$\(String(format: "%.2f", amount))")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private func tipButton(title: String, percentage: Double?) -> some View {
        let isSelected = cartViewModel.selectedTipPercentage == percentage
        return Button {
            if let p = percentage {
                cartViewModel.selectTipPercentage(p)
            } else {
                cartViewModel.setCustomTip(5.00)
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color(uiColor: .tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
