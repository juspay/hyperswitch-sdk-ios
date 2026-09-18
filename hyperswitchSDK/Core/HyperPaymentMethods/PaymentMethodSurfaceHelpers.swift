//
//  PaymentMethodSurfaceHelpers.swift
//  hyperswitch
//
//  React-surface helpers local to the payment-method session SDK. Separate from the
//  main SDK's helpers in `RNViewManager.swift` so this SDK stays self-contained as
//  its own library (it must not reach into the main SDK's native-module sources).
//

import Foundation
import React
import React_RCTAppDelegate

extension UIView {
    /// The surface object behind a root view from `viewForModule`, if it is one.
    internal var pmHostedSurface: (any RCTSurfaceProtocol)? {
        (self as? RCTSurfaceHostingProxyRootView)?.surface
    }

    internal var pmSurfaceRootTag: NSNumber? {
        pmHostedSurface.map { NSNumber(value: $0.rootTag) }
    }
}
