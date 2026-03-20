//
//  WidgetLauncher.swift
//  Hyperswitch
//
//  Created by Shivam Nan on 20/03/26.
//

import Foundation

/// Protocol for receiving ready state callbacks from widgets
public protocol WidgetReadyCallback {
    func onReady(isReady: Bool)
}

/// Protocol for receiving payment results from widgets
public protocol WidgetResultCallback {
    func onResult(status: String, message: String?, code: String?)
}

/// Manages widget callbacks similar to Android's WidgetLauncher
public class WidgetLauncher {
    
    // MARK: - Static Callbacks
    
    /// Callback for widget ready state - used by ExpressCheckout, Card, etc.
    internal static var onCurrentPaymentReady: ((Bool) -> Void)?
    
    /// Callbacks for specific widget types
    internal static var onCurrentCardResult: WidgetResultCallback?
    internal static var onCurrentExpressCheckoutResult: WidgetResultCallback?
    
    // MARK: - Public Methods
    
    /// Called when widget reports ready state
    /// - Parameter isReady: Whether the widget is ready for interaction
    public static func onPaymentReadyCallback(isReady: Bool) {
        onCurrentPaymentReady?(isReady)
    }
    
    /// Called when widget reports payment result
    /// - Parameters:
    ///   - widgetType: Type of widget (card, expressCheckout, etc.)
    ///   - paymentResult: JSON string containing status, message, and code
    public static func onPaymentResultCallback(widgetType: String, paymentResult: String) {
        guard let data = paymentResult.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return
        }
        
        let status = json["status"] ?? ""
        let message = json["message"]
        let code = json["code"]
        
        switch widgetType.lowercased() {
        case "card":
            onCurrentCardResult?.onResult(status: status, message: message, code: code)
        case "expresscheckout", "express_checkout":
            onCurrentExpressCheckoutResult?.onResult(status: status, message: message, code: code)
        default:
            print("WidgetLauncher: Unknown widget type: \(widgetType)")
        }
    }
    
    /// Resets all callbacks
    public static func resetCallbacks() {
        onCurrentPaymentReady = nil
        onCurrentCardResult = nil
        onCurrentExpressCheckoutResult = nil
    }
}

// MARK: - Widget Types

public enum WidgetType: String {
    case card = "card"
    case expressCheckout = "expressCheckout"
    case googlePay = "google_pay"
    case applePay = "apple_pay"
    case payPal = "paypal"
    case samsungPay = "samsung_pay"
}
