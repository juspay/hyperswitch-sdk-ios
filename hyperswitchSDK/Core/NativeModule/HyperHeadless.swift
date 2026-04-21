//
//  HyperHeadless.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 06/03/24.
//

import Foundation
import React
import WebKit

@objc(HyperHeadless)
internal class HyperHeadless: RCTEventEmitter {

    internal static var shared: HyperHeadless?

    private var setNativeProps: RCTResponseSenderBlock?
    private var confirmWithDefault: RCTResponseSenderBlock?
    private var defaultPMData: ((NSDictionary?) -> Void)?

    internal override init() {
        super.init()
        HyperHeadless.shared = self
    }

    @objc
    internal override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    @objc
    internal override func supportedEvents() -> [String] {
        return ["test"]
    }

    @objc
    private func confirm(data: [String: Any]) {
        self.sendEvent(withName: "test", body: data)
    }

    @objc
    private func getPaymentSession(
        _ rnMessage: NSDictionary,
        _ rnMessage2: NSDictionary,
        _ rnMessage3: NSArray,
        _ rnCallback: @escaping RCTResponseSenderBlock
    ) {
        PaymentSession.getPaymentSession(
            getPaymentMethodData: rnMessage,
            getPaymentMethodData2: rnMessage2,
            getPaymentMethodDataArray: rnMessage3,
            callback: rnCallback
        )
    }

    @objc
    private func exitHeadless(_ rnMessage: String) {
        PaymentSession.exitHeadless(rnMessage: rnMessage)
    }

    @objc
    private func exitHeadless(_ rootTag: NSNumber, _ rnMessage: String) {
        withWidget(rootTag) { w in
            w.handleConfirmCVCPaymentResponse(rnMessage)
        }
    }
    private func withWidget(_ rootTag: NSNumber, _ block: @escaping (CVCWidget) -> Void) {
        RCTGetUIManagerQueue().async {
            self.bridge.uiManager.addUIBlock { _, viewRegistry in
                guard let view = viewRegistry?[rootTag] else { return }
                var current: UIView? = view
                while let v = current {
                    if let widget = v as? CVCWidget {
                        block(widget)
                        return
                    }
                    current = v.superview
                }
            }
        }
    }
}
