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
}

@objc(HyperHeadlessImpl)
internal class HyperHeadlessImpl: NSObject {

    internal func attach(to shim: HyperHeadlessShim) {
        shim.attach(impl: self)
    }

    /// Completion signal for one payment's prefetch. The payload itself lives only in the
    /// JS PrefetchCache (shared VM); native just resumes the awaiting session.
    @objc(completePrefetch:)
    internal func completePrefetch(_ data: NSDictionary) {
        let dataDict = data as? [String: Any] ?? [:]
        guard let sdkAuthorization = dataDict["sdkAuthorization"] as? String else { return }
        DispatchQueue.main.async {
            PaymentSession.finishPrefetch(sdkAuthorization, data: dataDict)
        }
    }

    /* Headless requests are keyed by sdkAuthorization; the registries on PaymentSession own
       the pending request, its timeout, and per-authorization confirmation callbacks. */
    @objc(getPaymentSession:paymentIntentData:defaultPaymentMethod:savedPaymentMethods:callback:)
    internal func getPaymentSession(
        _ sdkAuthorization: String,
        _ rnMessage: NSDictionary,
        _ rnMessage2: NSDictionary,
        _ rnMessage3: NSArray,
        _ rnCallback: @escaping ([Any]?) -> Void
    ) {
        PaymentSession.getPaymentSession(
            sdkAuthorization: sdkAuthorization,
            getPaymentMethodData: rnMessage,
            getPaymentMethodData2: rnMessage2,
            getPaymentMethodDataArray: rnMessage3,
            callback: rnCallback
        )
    }

    /* The codegen adapter decomposes the typed PaymentExitResult object into these flat
       params. Keyed by sdkAuthorization; the auth-keyed confirmation registry is the single
       completion channel. */
    @objc(exitHeadless:status:code:message:)
    internal func exitHeadless(_ sdkAuthorization: String, _ status: String, _ code: String?, _ message: String?) {
        DispatchQueue.main.async {
            let result = PaymentResult.from(status: status, code: code, message: message)
            _ = PaymentSession.exitHeadless(sdkAuthorization: sdkAuthorization, result: result)
        }
    }
}
