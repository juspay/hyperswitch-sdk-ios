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
    private var headlessCompletion: ((any PaymentSessionHandler) -> Void)?
    private var completion: ((PaymentResult) -> Void)?
    private var hasResponded = false

    private weak var shim: HyperHeadlessShim?

    internal func attach(to shim: HyperHeadlessShim) {
        shim.attach(impl: self)
        DispatchQueue.main.async {
            self.shim = shim
        }
    }

    internal func begin(session: PaymentSession, completion: @escaping (any PaymentSessionHandler) -> Void) {
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
            let handler = PaymentSessionHandlerImpl(
                defaultMethod: rnMessage,
                lastUsedMethod: rnMessage2,
                allMethods: rnMessage3,
                sdkAuthorization: { [weak self] in
                    self?.activeSession?.paymentSessionConfiguration.sdkAuthorization ?? ""
                },
                resolveToken: { [weak self] paymentToken, cvc, resultHandler in
                    guard let self = self else { return }
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

    @objc(exitHeadless:status:code:message:)
    internal func exitHeadless(_ rootTag: NSNumber, _ status: String, _ code: String?, _ message: String?) {
        DispatchQueue.main.async {
            let result = PaymentResult.from(status: status, code: code, message: message)

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

    internal static func decodePaymentMethodData(_ readableMap: NSDictionary) -> Result<PaymentMethod, PMError> {
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

// MARK: - PaymentSessionHandlerImpl

internal final class PaymentSessionHandlerImpl: PaymentSessionHandler {

    private let defaultMethod: NSDictionary
    private let lastUsedMethod: NSDictionary
    private let allMethods: NSArray
    private let sdkAuthorization: () -> String
    private let resolveToken: (_ paymentToken: String, _ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void

    init(
        defaultMethod: NSDictionary,
        lastUsedMethod: NSDictionary,
        allMethods: NSArray,
        sdkAuthorization: @escaping () -> String,
        resolveToken: @escaping (_ paymentToken: String, _ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    ) {
        self.defaultMethod = defaultMethod
        self.lastUsedMethod = lastUsedMethod
        self.allMethods = allMethods
        self.sdkAuthorization = sdkAuthorization
        self.resolveToken = resolveToken
    }

    func getCustomerDefaultSavedPaymentMethodData() -> Result<PaymentMethod, PMError> {
        HyperHeadlessImpl.decodePaymentMethodData(defaultMethod)
    }

    func getCustomerLastUsedPaymentMethodData() -> Result<PaymentMethod, PMError> {
        HyperHeadlessImpl.decodePaymentMethodData(lastUsedMethod)
    }

    func getCustomerSavedPaymentMethodData() -> Result<[PaymentMethod], PMError> {
        var methods = [PaymentMethod]()
        for i in 0..<allMethods.count {
            if let map = allMethods[i] as? NSDictionary,
                case .success(let method) = HyperHeadlessImpl.decodePaymentMethodData(map)
            {
                methods.append(method)
            }
        }
        if methods.isEmpty {
            return .failure(PMError(code: "01", message: "No default type found"))
        }
        return .success(methods)
    }

    func confirmWithCustomerDefaultPaymentMethod(cvc: String?, resultHandler: @escaping (PaymentResult) -> Void) {
        confirm(token: defaultMethod["payment_token"] as? String, cvc: cvc, resultHandler: resultHandler)
    }

    func confirmWithCustomerLastUsedPaymentMethod(cvc: String?, resultHandler: @escaping (PaymentResult) -> Void) {
        confirm(token: lastUsedMethod["payment_token"] as? String, cvc: cvc, resultHandler: resultHandler)
    }

    func confirmWithCustomerPaymentToken(paymentToken: String, cvc: String?, resultHandler: @escaping (PaymentResult) -> Void) {
        resolveToken(paymentToken, cvc, resultHandler)
    }

    func confirmWithCustomerDefaultPaymentMethod(cvcWidget: CVCWidget, resultHandler: @escaping (PaymentResult) -> Void) {
        confirm(widget: cvcWidget, token: defaultMethod["payment_token"] as? String, resultHandler: resultHandler)
    }

    func confirmWithCustomerLastUsedPaymentMethod(cvcWidget: CVCWidget, resultHandler: @escaping (PaymentResult) -> Void) {
        confirm(widget: cvcWidget, token: lastUsedMethod["payment_token"] as? String, resultHandler: resultHandler)
    }

    private func confirm(token: String?, cvc: String?, resultHandler: @escaping (PaymentResult) -> Void) {
        guard let token = token else {
            resultHandler(.failed(error: Self.noTokenError))
            return
        }
        resolveToken(token, cvc, resultHandler)
    }

    private func confirm(widget: CVCWidget, token: String?, resultHandler: @escaping (PaymentResult) -> Void) {
        guard let token = token else {
            resultHandler(.failed(error: Self.noTokenError))
            return
        }
        widget.awaitConfirmResult(resultHandler)
        widget.confirm(sdkAuthorization: sdkAuthorization(), paymentToken: token)
    }

    private static let noTokenError = NSError(
        domain: "NO_PAYMENT_TOKEN",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "The selected payment method has no payment token."]
    )
}
