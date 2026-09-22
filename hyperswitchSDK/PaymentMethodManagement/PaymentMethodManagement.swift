//
//  PaymentMethodManagement.swift
//  Hyperswitch
//
//  Merchant-facing entry into Payment Methods Management.
//

import Foundation
import UIKit

public struct PaymentMethodManagementConfiguration {
    internal let sdkAuthorization: String

    /// [sdkAuthorization] comes from your server's payment method session.
    public init(sdkAuthorization: String) {
        self.sdkAuthorization = sdkAuthorization
    }
}

/// The props envelope a PMM surface starts with — same shape the payments surfaces use.
internal enum PMMProps {
    static func make(
        hyperswitchConfiguration: HyperswitchConfiguration,
        sdkAuthorization: String,
        configuration: PaymentSheet.Configuration?,
        subscribedEvents: [String]?,
        type: String,
        from: String?
    ) -> [String: Any] {
        var configurationDict = try? configuration?.toDictionary()
        configurationDict?["subscribedEvents"] = subscribedEvents

        var props: [String: Any] = [
            "type": type,
            "hyperswitchConfig": (try? hyperswitchConfiguration.toDictionary()) as Any,
            "paymentSessionConfig": ["sdkAuthorization": sdkAuthorization],
            "sdkParams": SDKParams.getSDKParams(),
            "configuration": configurationDict as Any,
        ]
        if let from = from {
            props["from"] = from
        }
        return props
    }
}

/// A payment method management session: the place PMM sheets and widgets come from.
/// Use from the main thread.
public final class PaymentMethodManagement {

    private let hyperswitchConfiguration: HyperswitchConfiguration
    private let sessionConfiguration: PaymentMethodManagementConfiguration
    private let host: PaymentMethodManagementHost

    internal init(
        hyperswitchConfiguration: HyperswitchConfiguration,
        configuration: PaymentMethodManagementConfiguration,
        host: PaymentMethodManagementHost = .shared
    ) {
        self.hyperswitchConfiguration = hyperswitchConfiguration
        self.sessionConfiguration = configuration
        self.host = host
    }

    // MARK: Sheet

    /// Presents the management sheet modally over [viewController]. The completion
    /// fires once, when the sheet exits.
    public func present(
        from viewController: UIViewController,
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil,
        completion: @escaping (PaymentResult) -> Void
    ) {
        var subscribedEvents: [String]? = nil
        var listener: PaymentEventListener? = nil
        if let subscribe {
            let builder = PaymentEventSubscriptionBuilder()
            subscribe(builder)
            let built = builder.build()
            subscribedEvents = built.subscription.subscribedEventStrings()
            listener = built.listener
        }
        let props = PMMProps.make(
            hyperswitchConfiguration: hyperswitchConfiguration,
            sdkAuthorization: sessionConfiguration.sdkAuthorization,
            configuration: configuration,
            subscribedEvents: subscribedEvents,
            type: PMMProtocol.sheetType,
            from: nil
        )
        let sheet = PaymentMethodManagementSheet(
            host: host,
            props: props,
            paymentEventListener: listener,
            completion: completion
        )
        sheet.present(from: viewController)
    }

    // MARK: Widget

    /// An embeddable management view. Drive its save with `tokenize(completion:)`
    /// (web parity with `hyper.confirmTokenization`) from any merchant-owned button;
    /// the view stays mounted for retry until a result resolves.
    public func widget(
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil
    ) -> PaymentMethodManagementWidget {
        PaymentMethodManagementWidget(
            hyperswitchConfiguration: hyperswitchConfiguration,
            sdkAuthorization: sessionConfiguration.sdkAuthorization,
            configuration: configuration,
            subscribe: subscribe,
            host: host
        )
    }
}

extension Hyperswitch {

    /// Starts the PMM engine loading, so the first surface does not wait for it.
    public func initPaymentMethodManagement(
        configuration: PaymentMethodManagementConfiguration
    ) -> PaymentMethodManagement {
        PaymentMethodManagementHost.shared.warmUp()
        return PaymentMethodManagement(hyperswitchConfiguration: hyperswitchConfiguration, configuration: configuration)
    }
}
