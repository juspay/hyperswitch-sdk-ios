//
//  PaymentWidget.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Combine
import Foundation

public class PaymentWidget: UIControl {

    private let paymentSession: PaymentSession
    private let configuration: PaymentSheet.Configuration?
    private var configurationDict: [String: Any]?
    private var widgetReactTag: NSNumber?
    private var rootView: RCTRootView?
    private var confirmCallback: ((PaymentResult) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    internal var paymentEventListener: PaymentEventListener?
    internal var subscribedEventNames: [String] = []

    public init(
        paymentSession: PaymentSession,
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil
    ) {
        self.paymentSession = paymentSession
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

    public init(
        paymentSession: PaymentSession,
        configurationDict: [String: Any]?,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil
    ) {
        self.paymentSession = paymentSession
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

        let hyperParams = HyperParams.getHyperParams()

        var nativeConfig = try? configuration?.toDictionary()
        nativeConfig?["hideConfirmButton"] = true
        configurationDict?["hideConfirmButton"] = true

        var config: [String: Any] = configurationDict ?? nativeConfig ?? [:]
        config["subscribedEvents"] = self.subscribedEventNames

        var sdkParams = hyperParams
        sdkParams["sessionId"] = ""
        sdkParams["confirm"] = false

        let props: [String: Any] = [
            "type": "widgetPaymentSheet",
            "hyperswitchConfig": [
                "publishableKey": APIClient.shared.publishableKey as Any,
                "profileId": APIClient.shared.profileId as Any,
            ],
            "paymentSessionConfig": [
                "sdkAuthorization": paymentSession.sdkAuthorization as Any,
            ],
            "sdkParams": sdkParams,
            "configuration": config,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customLogUrl": APIClient.shared.customLogUrl as Any,
            "customParams": APIClient.shared.customParams as Any,
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

        paymentSession.updateIntentDidStart
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                let payload: [String: Any] = ["rootTag": self.widgetReactTag ?? -1]
                self.rootView?.bridge.enqueueJSCall(
                    "RCTDeviceEventEmitter",
                    method: "emit",
                    args: ["updateIntentInit", payload],
                    completion: nil
                )
            }
            .store(in: &cancellables)

        paymentSession.updateIntentDidComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sdkAuthorization in
                guard let self = self else { return }
                let payload: [String: Any] = [
                    "rootTag": self.widgetReactTag ?? -1,
                    "sdkAuthorization": sdkAuthorization,
                ]
                self.rootView?.bridge.enqueueJSCall(
                    "RCTDeviceEventEmitter",
                    method: "emit",
                    args: ["updateIntentComplete", payload],
                    completion: nil
                )
            }
            .store(in: &cancellables)
    }

    public func confirm(resolve: @escaping (PaymentResult) -> Void) {
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

    internal func handleUpdateIntentEvent(type: String, result: String) {
        switch type {
        case "UPDATE_INTENT_INIT_RETURNED":
            paymentSession.updateIntentInitReturned.send(result)
        case "UPDATE_INTENT_COMPLETE_RETURNED":
            paymentSession.updateIntentCompleteReturned.send(result)
        default:
            break
        }
    }

    internal func handleConfirmPaymentResponse(_ result: PaymentResult) {
        confirmCallback?(result)
        confirmCallback = nil
        cancellables.removeAll()
        rootView?.removeFromSuperview()
        rootView = nil
        widgetReactTag = nil
    }
}
