//
//  CartViewModel.swift
//  SwiftBiteEngine
//
//  Created for SwiftBiteEngine Real-Time Tracking Engine.
//  Dynamic cart calculations, tip selection, promo code validation, and SwiftData synchronization.
//
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
public final class CartViewModel {
    
    // MARK: - State Properties
    
    public var items: [DeliveryCartItem] = []
    public var deliveryFee: Double = 3.99
    public var serviceFeeRate: Double = 0.05 // 5% platform fee
    public var taxRate: Double = 0.0825     // 8.25% municipal tax
    public var selectedTipPercentage: Double? = 0.15 // Default 15% tip
    public var customTipAmount: Double = 0.0
    public var appliedPromoCode: String?
    public var discountAmount: Double = 0.0
    public var promoErrorMessage: String?
    
    private let dataManager: SwiftDataManager
    
    @MainActor
    public init(dataManager: SwiftDataManager? = nil) {
        self.dataManager = dataManager ?? .shared
        refreshCart()
    }
    
    // MARK: - Financial Calculations
    
    /// Sum of all line item prices.
    public var subtotal: Double {
        items.reduce(0.0) { $0 + $1.totalPrice }
    }
    
    /// Calculated platform service fee.
    public var serviceFee: Double {
        subtotal * serviceFeeRate
    }
    
    /// Calculated sales tax.
    public var tax: Double {
        (subtotal + serviceFee) * taxRate
    }
    
    /// Tip calculation based on selected percentage or custom amount.
    public var tipAmount: Double {
        if let percentage = selectedTipPercentage {
            return subtotal * percentage
        } else {
            return customTipAmount
        }
    }
    
    /// Final billable total.
    public var grandTotal: Double {
        max(0.0, subtotal + deliveryFee + serviceFee + tax + tipAmount - discountAmount)
    }
    
    /// Total quantity of all items in cart.
    public var totalItemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    // MARK: - Cart Mutations
    
    /// Refreshes local items from the persistent SwiftData store.
    public func refreshCart() {
        self.items = dataManager.fetchCartItems()
    }
    
    /// Increments item count.
    public func increment(item: DeliveryCartItem) {
        dataManager.updateQuantity(for: item.id, delta: 1)
        refreshCart()
    }
    
    /// Decrements item count, removing if reaching 0.
    public func decrement(item: DeliveryCartItem) {
        dataManager.updateQuantity(for: item.id, delta: -1)
        refreshCart()
    }
    
    /// Deletes item completely from cart.
    public func remove(item: DeliveryCartItem) {
        dataManager.removeItem(id: item.id)
        refreshCart()
    }
    
    /// Adds or increments an item.
    public func addItem(name: String, description: String, price: Double, category: String = "Popular") {
        dataManager.addOrIncrementItem(name: name, itemDescription: description, price: price, category: category)
        refreshCart()
    }
    
    /// Clears all cart items.
    public func clear() {
        dataManager.clearCart()
        refreshCart()
    }
    
    // MARK: - Tips & Promo Actions
    
    public func selectTipPercentage(_ percentage: Double) {
        self.selectedTipPercentage = percentage
        self.customTipAmount = 0.0
    }
    
    public func setCustomTip(_ amount: Double) {
        self.selectedTipPercentage = nil
        self.customTipAmount = max(0.0, amount)
    }
    
    public func applyPromo(code: String) {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !cleaned.isEmpty else { return }
        
        if cleaned == "SWIFTBITE" {
            discountAmount = 5.00
            appliedPromoCode = cleaned
            promoErrorMessage = nil
        } else if cleaned == "VIP50" {
            discountAmount = subtotal * 0.50
            appliedPromoCode = cleaned
            promoErrorMessage = nil
        } else {
            promoErrorMessage = "Invalid or expired promo code"
        }
    }
    
    public func removePromo() {
        appliedPromoCode = nil
        discountAmount = 0.0
        promoErrorMessage = nil
    }
}
