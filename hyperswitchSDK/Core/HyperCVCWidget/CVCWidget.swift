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
    private var initialProperties: [String: Any] = [:]
    private var confirmSequence = 0
    private var cvcCallback: ((PaymentResult) -> Void)?
    private var subscribedEventNames: [String]?
    /// Stateless: one React root on the shared host, no session until confirm hands credentials over.
    private var reactManager: RNViewManager { RNViewManager.shared }

    internal var paymentEventListener: PaymentEventListener?

    public init(
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil
    ) {
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
    public init(
        configurationDict: [String: Any]?,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil
    ) {
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

        var nativeConfig = try? configuration?.toDictionary()
        nativeConfig?["subscribedEvents"] = self.subscribedEventNames
        configurationDict?["subscribedEvents"] = self.subscribedEventNames

        let props: [String: Any] = [
            "type": "cvcWidget",
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

    internal func awaitConfirmResult(_ handler: @escaping (PaymentResult) -> Void) {
        cvcCallback = handler
    }

    internal func resolveConfirmResult(_ result: PaymentResult) {
        let handler = cvcCallback
        cvcCallback = nil
        handler?(result)
    }

    func confirm(sdkAuthorization: String, paymentToken: String) {
        guard let surface = rootView?.hostedSurface else {
            resolveConfirmResult(.failed(error: NSError(
                domain: "WIDGET_UNAVAILABLE", code: 0,
                userInfo: ["message": "The CVC widget has no React root."]
            )))
            return
        }
        confirmSequence += 1
        var inner = initialProperties["props"] as? [String: Any] ?? [:]
        inner["cvcConfirm"] = [
            "attempt": confirmSequence,
            "sdkAuthorization": sdkAuthorization,
            "paymentToken": paymentToken,
        ]
        initialProperties["props"] = inner
        surface.properties = initialProperties
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
