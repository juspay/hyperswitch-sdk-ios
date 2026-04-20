//
//  WidgetAction.swift
//  Hyperswitch
//
//  Copyright © 2026 Hyperswitch. All rights reserved.
//

import Foundation

/// Each action represents a distinct callback pathway through the
/// WidgetResponseRegistry.
internal enum WidgetAction {
    /// One-shot callback for a confirm payment request.
    /// Registered when `confirmPayment` is invoked, consumed on response.
    case confirmPayment

    /// Passive event listener for payment result notifications.
    /// Registered at widget mount, stays active for the widget's lifetime.
    case paymentEvent

    /// Other cases like: updateIntent, subscription events
    /// For CVC widget
    case confirmCVCPayment

    case widgetEvent
}
