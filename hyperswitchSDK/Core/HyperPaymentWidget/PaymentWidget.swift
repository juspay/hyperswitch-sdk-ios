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
    private var configurationDict: [String: Any]?
    private var widgetReactTag: NSNumber?
    private var rootView: UIView?
    private var initialProperties: [String: Any] = [:]
    private var confirmSequence = 0
    private var initCallback: ((PaymentResult) -> Void)?
    private var confirmCompletion: ((PaymentResult) -> Void)?
    private var confirmInFlight = false
    private var shouldProceedWithPaymentCallback: ((PaymentRequestData, @escaping (Bool) -> Void) -> Void)?
    private var subscribedEventNames: [String]?
    private var reactManager: RNViewManager { RNViewManager.shared }
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

        let hyperswitchConfiguration = try? paymentSession.hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSession.paymentSessionConfiguration.toDictionary()

        let sdkParams = paymentSession.sdkParams()

        var nativeConfig = try? configuration?.toDictionary()
        nativeConfig?["hideConfirmButton"] = true  // MARK: replace with `displayPayButton`
        nativeConfig?["subscribedEvents"] = subscribedEventNames
        configurationDict?["hideConfirmButton"] = true  // MARK: replace with `displayPayButton`
        configurationDict?["subscribedEvents"] = subscribedEventNames

        let props: [String: Any] = [
            "type": "widgetPaymentSheet",
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
            "sdkParams": sdkParams,
            "configuration": configurationDict ?? nativeConfig as Any,
            "from": (configurationDict != nil) ? "rn" : "nativeWidget",
        ]

        self.initialProperties = ["props": props]
        self.rootView = reactManager.viewForModule(
            "hyperSwitch",
            initialProperties: initialProperties,
            owner: self
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

    public func confirm(completion: ((PaymentResult) -> Void)? = nil) {
        DispatchQueue.main.async {
            guard !self.confirmInFlight else {
                // The confirm in flight keeps its completion; this one is answered at once.
                completion?(
                    .failed(
                        error: Self.error(
                            "ALREADY_IN_PROGRESS",
                            "A confirm is already in progress for this widget"
                        )
                    )
                )
                return
            }
            self.confirmCompletion = completion
            guard let surface = self.rootView?.hostedSurface else {
                self.handleConfirmPaymentResponse(
                    .failed(
                        error: Self.error(
                            "WIDGET_UNAVAILABLE",
                            "The payment widget has no React root."
                        )
                    )
                )
                return
            }
            guard self.paymentSession.reactRuntime.updateIntentAttempt == nil else {
                // The session is between intents: the credentials this would confirm with are
                // about to be replaced, so the confirm would pay the old intent.
                self.handleNonTerminalResult(
                    .failed(
                        error: Self.error(
                            "UPDATE_IN_PROGRESS",
                            "An intent update is in progress; confirm after it completes"
                        )
                    )
                )
                return
            }
            self.confirmInFlight = true
            self.confirmSequence += 1
            var inner = self.initialProperties["props"] as? [String: Any] ?? [:]
            inner["paymentSessionConfig"] = (try? self.paymentSession.paymentSessionConfiguration.toDictionary()) as Any
            inner["widgetConfirm"] = ["attempt": self.confirmSequence]
            self.initialProperties["props"] = inner
            surface.properties = self.initialProperties
        }
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

    internal func handleNonTerminalResult(_ result: PaymentResult) {
        confirmInFlight = false
        let completion = confirmCompletion
        confirmCompletion = nil
        completion?(result)
    }

    internal func handleConfirmPaymentResponse(_ result: PaymentResult) {
        confirmInFlight = false
        let completion = confirmCompletion ?? initCallback
        confirmCompletion = nil
        initCallback = nil
        completion?(result)
        rootView?.removeFromSuperview()
        rootView = nil
        widgetReactTag = nil
    }

    private static func error(_ domain: String, _ message: String) -> NSError {
        .hyperswitch(domain, message)
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
