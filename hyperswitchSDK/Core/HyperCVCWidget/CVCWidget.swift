//
//  CVCWidget.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Foundation

public class CVCWidget: UIControl {

    private let paymentSession: PaymentSession
    private let configuration: PaymentSheet.Configuration
    private var widgetReactTag: NSNumber?
    private var rootView: RCTRootView?
    private var cvcCallback: RCTResponseSenderBlock?

    init(paymentSession: PaymentSession, configuration: PaymentSheet.Configuration) {
        self.paymentSession = paymentSession
        self.configuration = configuration
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {

        let hyperParams = HyperParams.getHyperParams()

        let props: [String: Any] = [
            "configuration": configuration.toDictionary() as Any,
            "type": "cvcWidget",
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

    func confirm(paymentToken: String, paymentMethodId: String, resolve: @escaping RCTResponseSenderBlock) {
        self.cvcCallback = resolve
        let payload: [String: Any] = [
            "actionType": "CONFIRM_CVC_PAYMENT",
            "rootTag": self.widgetReactTag ?? -1,
            "paymentToken": paymentToken,
            "paymentMethodId": paymentMethodId,
        ]
        self.rootView?.bridge.enqueueJSCall(
            "RCTDeviceEventEmitter",
            method: "emit",
            args: ["triggerWidgetAction", payload],
            completion: nil
        )
    }

    internal func handleConfirmCVCPaymentResponse(_ result: String) {
        cvcCallback?([result])
        cvcCallback = nil
    }
}
