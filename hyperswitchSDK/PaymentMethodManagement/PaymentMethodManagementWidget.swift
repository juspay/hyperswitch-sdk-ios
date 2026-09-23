//
//  PaymentMethodManagementWidget.swift
//  Hyperswitch
//
//  The embeddable PMM surface: one React root on the PMM host placed anywhere in a
//  merchant layout. Native → JS confirm goes out as `triggerWidgetAction`; the bundle's
//  replies come back by root tag through `SurfaceOwners`.
//

import Foundation
import UIKit

public class PaymentMethodManagementWidget: UIControl {

    private let host: PaymentMethodManagementHost
    private var widgetReactTag: NSNumber?
    private var rootView: UIView?
    private var tokenizeCallback: ((PaymentResult) -> Void)?
    private var subscribedEventNames: [String]?
    internal var paymentEventListener: PaymentEventListener?

    internal init(
        hyperswitchConfiguration: HyperswitchConfiguration,
        sdkAuthorization: String,
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil,
        host: PaymentMethodManagementHost = .shared
    ) {
        self.host = host
        if let subscribe {
            let builder = PaymentEventSubscriptionBuilder()
            subscribe(builder)
            let built = builder.build()
            self.paymentEventListener = built.listener
            self.subscribedEventNames = built.subscription.subscribedEventStrings()
        }
        super.init(frame: .zero)

        let props = PMMProps.make(
            hyperswitchConfiguration: hyperswitchConfiguration,
            sdkAuthorization: sdkAuthorization,
            configuration: configuration,
            subscribedEvents: subscribedEventNames,
            type: PMMProtocol.widgetType,
            from: "nativeWidget"
        )
        commonInit(props: props)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit(props: [String: Any]) {
        let rootView = host.viewForModule(
            PMMProtocol.component,
            initialProperties: ["props": props],
            owner: self
        )
        self.rootView = rootView
        self.widgetReactTag = rootView.surfaceRootTag

        rootView.backgroundColor = .clear

        addSubview(rootView)

        rootView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rootView.topAnchor.constraint(equalTo: topAnchor),
            rootView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rootView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    /// The merchant-driven tokenize (web parity with `hyper.confirmTokenization`):
    /// asks the bundle to run the sheet-equivalent save with whatever is on screen.
    /// The completion fires once per call, when the bundle resolves it; the widget
    /// stays mounted either way.
    public func tokenize(completion: @escaping (PaymentResult) -> Void) {
        self.tokenizeCallback = completion
        host.module.emitTriggerWidgetAction([
            "rootTag": widgetReactTag ?? -1,
            "actionType": PMMProtocol.confirmAction,
        ])
    }
}

extension PaymentMethodManagementWidget: PaymentMethodManagementEventTarget {

    internal func pmmExit(_ result: PaymentResult, reset: Bool) {
        resolveTokenize(result)
    }

    internal func pmmNonTerminalResult(_ result: PaymentResult) {
        resolveTokenize(result)
    }

    internal func pmmPaymentEvent(type: String, payload: [String: Any]) {
        guard let listener = paymentEventListener else { return }
        let event = PaymentEvent(type: type, payload: payload)
        if Thread.isMainThread {
            listener.onPaymentEvent(event)
        } else {
            DispatchQueue.main.async { listener.onPaymentEvent(event) }
        }
    }

    private func resolveTokenize(_ result: PaymentResult) {
        let callback = tokenizeCallback
        tokenizeCallback = nil
        if Thread.isMainThread {
            callback?(result)
        } else {
            DispatchQueue.main.async { callback?(result) }
        }
    }
}
