//
//  PaymentMethodModuleImpl.swift
//  Hyperswitch
//
//  Dedicated TurboModule impl for the payment-methods session's JS runtime — kept separate
//  from HyperModuleImpl so that payment-method events never depend on the main SDK's event bus.
//

import Foundation

@objc(PaymentMethodModuleShim)
internal protocol PaymentMethodModuleShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: PaymentMethodModuleImpl)
    @objc(emitEventWithName:payload:)
    func emitEvent(name: String, payload: [String: Any])
}

@objc(PaymentMethodModuleImpl)
internal class PaymentMethodModuleImpl: NSObject {

    private weak var shim: PaymentMethodModuleShim?

    /// Pending `CardForm.tokenise()` completions, keyed by the requesting form's surface
    /// rootTag — one tokenise may be in flight per form at a time. Resolved when JS answers
    /// via `returnTokenResult`.
    private var pendingTokeniseCallbacks: [Int: ([String: Any]?) -> Void] = [:]
    private let lock = NSLock()

    internal func attach(to shim: PaymentMethodModuleShim) {
        shim.attach(impl: self)
        onMain {
            self.shim = shim
        }
    }

    internal func emit(_ name: String, _ payload: [String: Any]) {
        onMain {
            self.shim?.emitEvent(name: name, payload: payload)
        }
    }

    internal func registerTokeniseCallback(rootTag: Int, completion: @escaping ([String: Any]?) -> Void) {
        lock.lock()
        pendingTokeniseCallbacks[rootTag] = completion
        lock.unlock()
    }

    @objc(resolveTokeniseCallbackWithRootTag:result:)
    internal func resolveTokeniseCallback(rootTag: NSInteger, result: NSDictionary?) {
        lock.lock()
        let callback = pendingTokeniseCallbacks.removeValue(forKey: rootTag)
        lock.unlock()
        callback?(result as? [String: Any])
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}
