//
//  PaymentMethodSession.swift
//  hyperswitch
//
//  A payment-method session (pmsInstance) with its own dedicated RN host.
//

import Foundation
import UIKit

/// A payment-method session created via
/// `Hyperswitch.initPaymentMethodSession(sdkAuthorization:configuration:)`.
///
/// Every instance owns a **separate React Native host** — it instantiates its own
/// `RNViewManager` (a dedicated `RCTReactNativeFactory`) instead of using
/// `RNViewManager.sharedInstance`, so every payment-method session runs on its own
/// JS runtime, isolated from the main payment SDK and from other sessions.
///
/// Follow the `PaymentSession` pattern: create one session per `sdkAuthorization`
/// and bind UI widgets through `createCardForm()`.
public class PaymentMethodSession {

    internal let sdkAuthorization: String
    internal let configuration: PaymentMethodSessionConfiguration
    internal let hyperswitchConfiguration: HyperswitchConfiguration?

    /// Dedicated RN host for this session — never the shared manager.
    internal let reactManager: RNViewManager

    internal init(
        sdkAuthorization: String,
        configuration: PaymentMethodSessionConfiguration,
        hyperswitchConfiguration: HyperswitchConfiguration?
    ) {
        self.sdkAuthorization = sdkAuthorization
        self.configuration = configuration
        self.hyperswitchConfiguration = hyperswitchConfiguration
        self.reactManager = RNViewManager()
    }

    /// Creates a `CardForm` instance backed by an empty RN view on this session's host.
    public func createCardForm() -> CardForm {
        return CardForm(session: self)
    }

    /// Session payload handed to every RN surface of this session:
    /// `session = { sdk_auth = ..., vault_type = ..., vault_data = ... }`
    internal var sessionProps: [String: Any] {
        var props: [String: Any] = ["sdk_auth": sdkAuthorization]
        if let vaultType = configuration.vaultType {
            props["vault_type"] = vaultType
        }
        if let vaultData = configuration.vaultData {
            props["vault_data"] = vaultData
        }
        return props
    }

    /// Full launch props for an RN surface owned by this session, mirroring
    /// `PaymentWidget`'s prop structure with an additional `session` payload.
    internal func launchProps(type: String, configuration: [String: Any]?) -> [String: Any] {
        let hyperswitchConfiguration = try? hyperswitchConfiguration?.toDictionary()
        let sdkParams = SDKParams.getSDKParams()

        return [
            "type": type,
            "from": "nativeWidget",
            "configuration": configuration as Any,
            "session": sessionProps,
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "sdkParams": sdkParams,
        ]
    }
}
