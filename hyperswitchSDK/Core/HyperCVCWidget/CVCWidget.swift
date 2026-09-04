//
//  CVCWidget.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Foundation

public class CVCWidget: UIControl {

    private let configuration: PaymentSheet.Configuration?
    private var configurationDict: [String: Any]?
    private var widgetReactTag: NSNumber?
    private var rootView: UIView?
    private var cvcCallback: ((PaymentResult) -> Void)?
    private var subscribedEventNames: [String]?
    private let hyperswitch: Hyperswitch
    private let reactManager = RNViewManager.sharedInstance

    internal var paymentEventListener: PaymentEventListener?

    public init(
        hyperswitch: Hyperswitch,
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil
    ) {
        self.hyperswitch = hyperswitch
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

    //MARK: pass through
    public init(hyperswitch: Hyperswitch, configurationDict: [String: Any]?, subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil)
    {
        self.hyperswitch = hyperswitch
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

        let hyperswitchConfiguration = try? hyperswitch.hyperswitchConfiguration.toDictionary()

        let sdkParams = SDKParams.getSDKParams()

        var nativeConfig = try? configuration?.toDictionary()
        nativeConfig?["subscribedEvents"] = self.subscribedEventNames
        configurationDict?["subscribedEvents"] = self.subscribedEventNames

        let props: [String: Any] = [
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "type": "cvcWidget",
            "sdkParams": sdkParams,
            "configuration": configurationDict ?? nativeConfig as Any,
            "from": (configurationDict != nil) ? "rn" : "nativeWidget",
        ]

        self.rootView = reactManager.widgetViewForModule(
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

    internal func awaitConfirmResult(_ handler: @escaping (PaymentResult) -> Void) {
        cvcCallback = handler
    }

    internal func resolveConfirmResult(_ result: PaymentResult) {
        let handler = cvcCallback
        cvcCallback = nil
        handler?(result)
    }

    /* Returns false when the JS emitter is detached: the confirm can never start,
       so the caller must roll its confirmation registration back. */
    @discardableResult
    func confirm(sdkAuthorization: String, paymentToken: String) -> Bool {
        let payload: [String: Any] = [
            "actionType": "CONFIRM_CVC_PAYMENT",
            "rootTag": self.widgetReactTag ?? -1,
            "sdkAuthorization": sdkAuthorization,
            "paymentToken": paymentToken,
        ]
        return reactManager.hyperModule.emitChecked("triggerWidgetAction", payload)
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
