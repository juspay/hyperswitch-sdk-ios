//
//  PaymentWidget.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Foundation

public class PaymentWidget: UIControl {

    private let paymentSession: PaymentSession
    private let configuration: PaymentSheet.Configuration?
    private let configurationDict: [String: Any]?
    private var widgetReactTag: NSNumber?
    private var rootView: RCTRootView?
    private var initCallback: ((PaymentResult) -> Void)?
    private var confirmCallback: ((PaymentResult) -> Void)?

    init(paymentSession: PaymentSession, configuration: PaymentSheet.Configuration? = nil, completion: ((PaymentResult) -> Void)? = nil) {
        self.paymentSession = paymentSession
        self.configuration = configuration
        self.configurationDict = nil
        self.initCallback = completion
        super.init(frame: .zero)
        commonInit()
    }

    // pass through
    init(paymentSession: PaymentSession, configuration: [String: Any]? = nil, completion: ((PaymentResult) -> Void)? = nil) {
        self.paymentSession = paymentSession
        self.configuration = nil
        self.configurationDict = configuration
        self.initCallback = completion
        super.init(frame: .zero)
        commonInit()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {

        let hyperParams = HyperParams.getHyperParams()

        let props: [String: Any] = [
            "configuration": configurationDict ?? configuration?.toDictionary() as Any,
            "type": "widgetPaymentSheet",
            "sdkAuthorization": paymentSession.sdkAuthorization as Any,
            "publishableKey": APIClient.shared.publishableKey as Any,
            "profileId": APIClient.shared.profileId as Any,
            "hyperParams": hyperParams,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customLogUrl": APIClient.shared.customLogUrl as Any,
            "customParams": APIClient.shared.customParams as Any,
        ]

        self.rootView = RNViewManager.sharedInstance.widgetViewForModule(
            "hyperSwitch",
            initialProperties: ["props": props]
        )
        if let rootView = self.rootView {
            self.widgetReactTag = rootView.reactTag

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

    func confirm(resolve: @escaping (PaymentResult) -> Void) {
        self.confirmCallback = resolve
        let payload: [String: Any] = [
            "rootTag": self.widgetReactTag ?? -1,
            "actionType": "CONFIRM_PAYMENT_ACTION",
        ]
        self.rootView?.bridge.enqueueJSCall(
            "RCTDeviceEventEmitter",
            method: "emit",
            args: ["triggerWidgetAction", payload],
            completion: nil
        )
    }

    internal func handleConfirmPaymentResponse(_ result: PaymentResult) {
        if let confirmCallback {
            confirmCallback(result)
        } else {
            initCallback?(result)
        }
        confirmCallback = nil
        initCallback = nil
        rootView?.removeFromSuperview()
        rootView = nil
        widgetReactTag = nil
    }
}
