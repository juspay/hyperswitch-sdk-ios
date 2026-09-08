//
//  PaymentMethodManagementWidget.swift
//  hyperswitch
//
//  Created by Shivam Nan on 18/10/24.
//

import Foundation
import UIKit

public class PaymentMethodManagementWidget: UIControl {

    private let paymentSession: PaymentSession
    private let configuration: PaymentSheet.Configuration?
    private var widgetReactTag: NSNumber?
    private var rootView: UIView?
    private var confirmCallback: ((PaymentResult) -> Void)?
    private var subscribedEventNames: [String]?
    private var reactManager: RNViewManager { paymentSession.reactManager }
    internal var paymentEventListener: PaymentEventListener?

    public init(
        paymentSession: PaymentSession,
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil
    ) {
        self.paymentSession = paymentSession
        self.configuration = configuration
        if let subscribe {
            let builder = PaymentEventSubscriptionBuilder()
            subscribe(builder)
            let (subscription, listener) = builder.build()
            self.paymentEventListener = listener
            self.subscribedEventNames = subscription.subscribedEventStrings()
        }
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {

        let hyperswitchConfiguration = try? paymentSession.hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSession.paymentSessionConfiguration.toDictionary()

        let sdkParams = SDKParams.getSDKParams()

        var configuration = try? self.configuration?.toDictionary()
        configuration?["subscribedEvents"] = subscribedEventNames

        let props: [String: Any] = [
            "type": "widgetPaymentMethodsManagement",
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
            "sdkParams": sdkParams,
            "configuration": configuration as Any,
            "from": "nativeWidget",
        ]

        self.rootView = reactManager.viewForModule(
            "hyperSwitch",
            initialProperties: ["props": props]
        )
        if let rootView = self.rootView {
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
    }

    public func confirm(completion: @escaping (PaymentResult) -> Void) {
        self.confirmCallback = completion
        let payload: [String: Any] = [
            "rootTag": self.widgetReactTag ?? -1,
            "actionType": "CONFIRM_PAYMENT_ACTION",
        ]
        reactManager.hyperModule.emit("triggerWidgetAction", payload)
    }


    internal func handlePaymentResult(_ result: PaymentResult) {
        confirmCallback?(result)
        confirmCallback = nil
    }

    internal func dispatchPaymentEvent(type: String, payload: [String: Any]) {
        guard let listener = paymentEventListener else { return }
        let event = PaymentEvent(type: type, payload: payload)
        if Thread.isMainThread {
            listener.onPaymentEvent(event)
        } else {
            DispatchQueue.main.async { listener.onPaymentEvent(event) }
        }
    }
}
