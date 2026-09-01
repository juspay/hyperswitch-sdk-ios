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
    private var rootView: UIView?
    private var initCallback: ((PaymentResult) -> Void)?
    private var shouldProceedWithPaymentCallback: ((PaymentRequestData, @escaping (Bool) -> Void) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    private var subscribedEventNames: [String]?
    private let reactManager = RNViewManager.sharedInstance
    internal var paymentEventListener: PaymentEventListener?

    public init(
        paymentSession: PaymentSession,
        configuration: PaymentSheet.Configuration? = nil,
        completion: @escaping ((PaymentResult) -> Void),
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
        self.initCallback = completion
        super.init(frame: .zero)
        commonInit()
    }

    public init(
        paymentSession: PaymentSession,
        configurationDict: [String: Any]?,
        completion: @escaping ((PaymentResult) -> Void),
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
        self.initCallback = completion
        super.init(frame: .zero)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func shouldProceedWithPayment(_ callback: @escaping (PaymentRequestData, @escaping (Bool) -> Void) -> Void) {
        self.shouldProceedWithPaymentCallback = callback
    }

    private func commonInit() {

        paymentSession.registerWidget(self)

        let hyperswitchConfiguration = try? paymentSession.hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSession.paymentSessionConfiguration.toDictionary()

        let sdkParams = SDKParams.getSDKParams()

        var nativeConfig = try? configuration?.toDictionary()
        nativeConfig?["hideConfirmButton"] = true  // MARK: replace with `displayPayButton`
        nativeConfig?["subscribedEvents"] = subscribedEventNames
        configurationDict?["hideConfirmButton"] = true  // MARK: replace with `displayPayButton`
        configurationDict?["subscribedEvents"] = subscribedEventNames

        var props: [String: Any] = [
            "type": "widgetPaymentSheet",
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
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

        paymentSession.updateIntentDidStart
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                let payload: [String: Any] = ["rootTag": self.widgetReactTag ?? -1]
                self.reactManager.hyperModule.emit("updateIntentInit", payload)
            }
            .store(in: &cancellables)

        paymentSession.updateIntentDidComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self = self else { return }
                // Payload is intentionally sdkAuthorization-only: JS resolves the fresh
                // intent data from its own PrefetchCache on the shared bridge.
                let payload: [String: Any] = [
                    "rootTag": self.widgetReactTag ?? -1,
                    "sdkAuthorization": update.sdkAuthorization,
                ]
                self.reactManager.hyperModule.emit("updateIntentComplete", payload)
            }
            .store(in: &cancellables)
    }

    deinit {
        paymentSession.unregisterWidget(self)
    }

    public func confirm() {
        let payload: [String: Any] = [
            "rootTag": self.widgetReactTag ?? -1,
            "actionType": "CONFIRM_PAYMENT_ACTION",
        ]
        reactManager.hyperModule.emit("triggerWidgetAction", payload)
    }

    internal func handleShouldProceedWithPayment(payload: String, callback: @escaping (Bool) -> Void) {
        if shouldProceedWithPaymentCallback == nil {
            callback(true)
        } else {
            if let data = payload.data(using: .utf8),
                let paymentRequestData = try? JSONDecoder().decode(PaymentRequestData.self, from: data)
            {
                shouldProceedWithPaymentCallback?(paymentRequestData, callback)
            }
        }
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
        paymentSession.unregisterWidget(self)
        paymentSession.handlePaymentResult(result)
        initCallback?(result)
        initCallback = nil
        cancellables.removeAll()
        rootView?.removeFromSuperview()
        rootView = nil
        widgetReactTag = nil
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
