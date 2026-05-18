//
//  CVCWidget.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Foundation

public class CVCWidget: UIControl {

    private let configuration: PaymentSheet.Configuration?
    private let configurationDict: [String: Any]?
    private var widgetReactTag: NSNumber?
    private var rootView: RCTRootView?
    private var cvcCallback: ((PaymentResult) -> Void)?
    internal var paymentEventListener: PaymentEventListener?
    internal var subscribedEventNames: [String] = []

    public init(configuration: PaymentSheet.Configuration? = nil, subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil) {
        self.configuration = configuration
        self.configurationDict = nil
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

    // pass through
    public init(configurationDict: [String: Any]?, subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil) {
        self.configuration = nil
        self.configurationDict = configurationDict
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

        let sdkParams = SDKParams.getSDKParams()
        let nativeConfig = try? configuration?.toDictionary()

        let props: [String: Any] = [
            "type": "cvcWidget",
            "sdkParams": sdkParams,
            "configuration": configurationDict ?? nativeConfig as Any,
            "subscribedEvents": self.subscribedEventNames,
            "from": (configurationDict != nil) ? "rn" : "nativeWidget",
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

    func confirm(sdkAuthorization: String, paymentToken: String) {
        let payload: [String: Any] = [
            "actionType": "CONFIRM_CVC_PAYMENT",
            "rootTag": self.widgetReactTag ?? -1,
            "sdkAuthorization": sdkAuthorization,
            "paymentToken": paymentToken,
        ]
        self.rootView?.bridge.enqueueJSCall(
            "RCTDeviceEventEmitter",
            method: "emit",
            args: ["triggerWidgetAction", payload],
            completion: nil
        )
    }
}
