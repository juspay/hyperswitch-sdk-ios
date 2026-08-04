//
//  HyperHeadless.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

import Foundation
import UIKit
import WebKit

@objc(HyperHeadlessShim)
internal protocol HyperHeadlessShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: HyperHeadlessImpl)
    @objc(viewForRootTag:)
    func view(forRootTag rootTag: NSNumber) -> UIView?
}

@objc(HyperHeadlessImpl)
internal class HyperHeadlessImpl: NSObject {

    private weak var activeSession: PaymentSession?
    private var headlessCompletion: ((PaymentSessionHandler) -> Void)?
    private var completion: ((PaymentResult) -> Void)?
    private var hasResponded = false

    private weak var shim: HyperHeadlessShim?

    internal func attach(to shim: HyperHeadlessShim) {
        shim.attach(impl: self)
        DispatchQueue.main.async {
            self.shim = shim
        }
    }

    internal func begin(session: PaymentSession, completion: @escaping (PaymentSessionHandler) -> Void) {
        hasResponded = false
        headlessCompletion = completion
        activeSession = session
    }

    private func safeResolve(
        _ callback: @escaping ([Any]?) -> Void,
        _ result: [Any],
        _ resultHandler: @escaping (PaymentResult) -> Void
    ) {
        guard !hasResponded else {
            print("Warning: Attempt to resolve callback more than once")
            resultHandler(.failed(error: NSError(domain: "Not Initialised", code: 0, userInfo: ["message": "An error has occurred."])))
            return
        }
        hasResponded = true
        callback(result)
    }

    @objc(getPaymentSession:paymentIntentData:defaultPaymentMethod:savedPaymentMethods:callback:)
    internal func getPaymentSession(
        _ rootTag: NSNumber,
        _ rnMessage: NSDictionary,
        _ rnMessage2: NSDictionary,
        _ rnMessage3: NSArray,
        _ rnCallback: @escaping ([Any]?) -> Void
    ) {
        DispatchQueue.main.async {
            self.hasResponded = false
            let handler = PaymentSessionHandler(
                getCustomerDefaultSavedPaymentMethodData: {
                    return HyperHeadlessImpl.decodePaymentMethodData(rnMessage)
                },
                getCustomerLastUsedPaymentMethodData: {
                    return HyperHeadlessImpl.decodePaymentMethodData(rnMessage2)
                },
                getCustomerSavedPaymentMethodData: {
                    var array = [PaymentMethod]()
                    for i in 0..<rnMessage3.count {
                        if let map = rnMessage3[i] as? NSDictionary {
                            switch HyperHeadlessImpl.decodePaymentMethodData(map) {
                            case .success(let paymentMethod):
                                array.append(paymentMethod)
                            case .failure(_):
                                continue
                            }
                        }
                    }
                    if array.isEmpty {
                        return .failure(
                            PMError(
                                code: "01",
                                message: "No default type found"
                            )
                        )
                    }
                    return .success(array)

                },
                confirmWithCustomerDefaultPaymentMethod: { cvc, resultHandler in
                    if let paymentToken = rnMessage["payment_token"] as? String {
                        self.completion = resultHandler
                        var map = [String: Any]()
                        map["paymentToken"] = paymentToken
                        map["cvc"] = cvc
                        self.safeResolve(rnCallback, [map], resultHandler)
                    }
                },
                confirmWithCustomerLastUsedPaymentMethod: { cvc, resultHandler in
                    if let paymentToken = rnMessage2["payment_token"] as? String {
                        cvc.awaitConfirmResult(resultHandler)
                        cvc.confirm(
                            sdkAuthorization: self.activeSession?.paymentSessionConfiguration.sdkAuthorization ?? "",
                            paymentToken: paymentToken
                        )
                    }
                },
                confirmWithCustomerPaymentToken: { paymentToken, cvc, resultHandler in
                    self.completion = resultHandler
                    var map = [String: Any]()
                    map["paymentToken"] = paymentToken
                    map["cvc"] = cvc
                    self.safeResolve(rnCallback, [map], resultHandler)
                }
            )
            self.headlessCompletion?(handler)
        }
    }

    @objc(exitHeadless:result:)
    internal func exitHeadless(_ rootTag: NSNumber, _ rnMessage: String) {
        DispatchQueue.main.async {
            let result = Self.paymentResult(from: rnMessage)

            if let widget = self.cvcWidget(forRootTag: rootTag) {
                widget.resolveConfirmResult(result)
                return
            }
            self.completion?(result)
        }
    }

    private func cvcWidget(forRootTag rootTag: NSNumber) -> CVCWidget? {
        return shim?.view(forRootTag: rootTag)?.nearestAncestor(ofType: CVCWidget.self)
    }

    private static func paymentResult(from rnMessage: String) -> PaymentResult {
        let unknown = PaymentResult.failed(
            error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
        )

        guard let data = rnMessage.data(using: .utf8),
            let message = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: String],
            let status = message["status"]
        else {
            return unknown
        }

        switch status {
        case "cancelled":
            return .canceled(data: status)
        case "failed", "requires_payment_method":
            let code = message["code"] ?? ""
            let domain = code.isEmpty ? "UNKNOWN_ERROR" : code
            let errorMessage = message["message"] ?? "An error has occurred."
            return .failed(error: NSError(domain: domain, code: 0, userInfo: ["message": errorMessage]))
        default:
            return .completed(data: status)
        }
    }

    private static func decodePaymentMethodData(_ readableMap: NSDictionary) -> Result<PaymentMethod, PMError> {
        if let jsonData = try? JSONSerialization.data(withJSONObject: readableMap),
            let paymentMethod = try? JSONDecoder().decode(PaymentMethod.self, from: jsonData)
        {
            return .success(paymentMethod)
        } else {
            return .failure(
                PMError(
                    code: readableMap["code"] as? String ?? "01",
                    message: readableMap["message"] as? String ?? "No default type found"
                )
            )
        }
    }
}
