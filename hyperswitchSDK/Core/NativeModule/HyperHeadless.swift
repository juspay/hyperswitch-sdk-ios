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
        _ rootTag: NSNumber,
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
    private func exitHeadless(_ rootTag: NSNumber, _ rnMessage: String) {
        PaymentSession.exitHeadless(rnMessage: rnMessage)
    }

    private func paymentResult(from rnMessage: String) -> PaymentResult {
        guard let data = rnMessage.data(using: .utf8) else {
            return .failed(
                error: NSError(
                    domain: "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": "An error has occurred."]
                )
            )
        }

        do {
            guard let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                return .failed(
                    error: NSError(
                        domain: "UNKNOWN_ERROR",
                        code: 0,
                        userInfo: ["message": "An error has occurred."]
                    )
                )
            }

            let status = jsonDictionary["status"]

            if status == "failed" || status == "requires_payment_method" {
                let error = NSError(
                    domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": jsonDictionary["message"] ?? "An error has occurred."]
                )
                return .failed(error: error)
            } else if status == "cancelled" {
                return .canceled(data: "cancelled")
            } else {
                return .completed(data: status ?? "failed")
            }
        } catch {
            return .failed(
                error: NSError(
                    domain: "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": "An error has occurred."]
                )
            )
        }
    }
}
