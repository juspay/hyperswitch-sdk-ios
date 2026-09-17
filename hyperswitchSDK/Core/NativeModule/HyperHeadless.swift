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
    @objc(surfaceForRootTag:)
    func surface(forRootTag rootTag: NSNumber) -> AnyObject?
}

/// Stateless: every call names the surface it comes from by root tag, and the
/// owner of that surface handles it.
@objc(HyperHeadlessImpl)
internal class HyperHeadlessImpl: NSObject {

    private weak var shim: HyperHeadlessShim?

    internal func attach(to shim: HyperHeadlessShim) {
        shim.attach(impl: self)
        DispatchQueue.main.async {
            self.shim = shim
        }
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
            guard let attempt = self.owner(forRootTag: rootTag) as? HeadlessAttempt else {
                print("HyperHeadless: getPaymentSession has no owner for rootTag \(rootTag)")
                return
            }
            attempt.onPaymentSession(
                defaultMethod: rnMessage,
                lastUsedMethod: rnMessage2,
                allMethods: rnMessage3,
                callback: rnCallback
            )
        }
    }

    @objc(exitHeadless:status:code:message:)
    internal func exitHeadless(_ rootTag: NSNumber, _ status: String, _ code: String?, _ message: String?) {
        DispatchQueue.main.async {
            let result = PaymentResult.from(status: status, code: code, message: message)
            switch self.owner(forRootTag: rootTag) {
            case let attempt as HeadlessAttempt:
                attempt.onExit(result)
            case let widget as CVCWidget:
                widget.resolveConfirmResult(result)
            default:
                print("HyperHeadless: exitHeadless has no owner for rootTag \(rootTag)")
            }
        }
    }

    /// Main thread. Root tag → surface object → owner.
    private func owner(forRootTag rootTag: NSNumber) -> AnyObject? {
        guard let surface = shim?.surface(forRootTag: rootTag) else { return nil }
        return SurfaceOwners.owner(of: surface)
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

// MARK: - HeadlessAttempt

/// Owner of one saved-payment-methods surface. Holds exactly what that surface's
/// replies need: the merchant completion (fired once), the latest JS confirm
/// callback (JS registers a fresh one after every confirm) and at most one
/// pending result handler. Main thread.
internal final class HeadlessAttempt {

    private let sdkAuthorization: () -> String
    private let onHandler: (any PaymentSessionHandler) -> Void
    private var jsCallback: (([Any]?) -> Void)?
    private var handlerDelivered = false
    private var pendingResult: ((PaymentResult) -> Void)?

    internal init(
        sdkAuthorization: @escaping () -> String,
        onHandler: @escaping (any PaymentSessionHandler) -> Void
    ) {
        self.sdkAuthorization = sdkAuthorization
        self.onHandler = onHandler
    }

    internal func onPaymentSession(
        defaultMethod: NSDictionary,
        lastUsedMethod: NSDictionary,
        allMethods: NSArray,
        callback: @escaping ([Any]?) -> Void
    ) {
        jsCallback = callback
        guard !handlerDelivered else { return }
        handlerDelivered = true
        let handler = PaymentSessionHandlerImpl(
            defaultMethod: defaultMethod,
            lastUsedMethod: lastUsedMethod,
            allMethods: allMethods,
            sdkAuthorization: sdkAuthorization,
            resolveToken: { [weak self] paymentToken, cvc, resultHandler in
                DispatchQueue.main.async {
                    guard let self = self else {
                        resultHandler(.failed(error: Self.error("SESSION_CLOSED", "The payment session was closed")))
                        return
                    }
                    self.confirm(paymentToken: paymentToken, cvc: cvc, resultHandler: resultHandler)
                }
            }
        )
        onHandler(handler)
    }

    private func confirm(paymentToken: String, cvc: String?, resultHandler: @escaping (PaymentResult) -> Void) {
        guard pendingResult == nil else {
            resultHandler(.failed(error: Self.error("ALREADY_IN_PROGRESS", "Payment confirmation already in progress for this handler")))
            return
        }
        // A React callback can be invoked once; JS registers a new one after each confirm.
        guard let callback = jsCallback else {
            resultHandler(.failed(error: Self.error("Not Initialised", "An error has occurred.")))
            return
        }
        jsCallback = nil
        pendingResult = resultHandler
        var map: [String: Any] = ["paymentToken": paymentToken]
        map["cvc"] = cvc
        callback([map])
    }

    internal func onExit(_ result: PaymentResult) {
        let handler = pendingResult
        pendingResult = nil
        handler?(result)
    }

    /// The surface is going away: fail whatever is still waiting on it.
    internal func cancel() {
        jsCallback = nil
        onExit(.failed(error: Self.error("CANCELLED", "The saved payment methods session was replaced or closed")))
    }

    private static func error(_ domain: String, _ message: String) -> NSError {
        NSError(domain: domain, code: 0, userInfo: ["message": message])
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
        let sdkAuthorization = sdkAuthorization()
        DispatchQueue.main.async {
            widget.awaitConfirmResult(resultHandler)
            widget.confirm(sdkAuthorization: sdkAuthorization, paymentToken: token)
        }
    }

    private static let noTokenError = NSError(
        domain: "NO_PAYMENT_TOKEN",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "The selected payment method has no payment token."]
    )
}
