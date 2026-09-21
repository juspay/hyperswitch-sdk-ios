//
//  PaymentMethodsModule.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

import Foundation
import React

/// The contract with the Payment Methods bundle. Mirrors `hosted/protocol.ts` in
/// hyperswitch-client-core; the two are told apart from a mismatch by `version`.
internal enum PaymentMethodsProtocol {
    static let version = 1

    static let formComponent = "HyperPaymentMethodsForm"
    static let fieldComponent = "HyperPaymentMethodsField"

    static let formType = "paymentMethodsForm"
    static let fieldType = "paymentMethodsField"

    enum FieldEvent {
        static let ready = "PM_FIELD_READY"
        static let change = "PM_FIELD_CHANGE"
        static let focus = "PM_FIELD_FOCUS"
        static let blur = "PM_FIELD_BLUR"
        static let layout = "PM_LAYOUT"
        static let error = "PM_FIELD_ERROR"
    }

    enum FormEvent {
        static let ready = "PM_FORM_READY"
        static let change = "PM_FORM_CHANGE"
        static let error = "PM_FORM_ERROR"
        static let commandResult = "PM_COMMAND_RESULT"
    }
}

/// The native owner of a Payment Methods root: what the bundle says about that root lands here.
internal protocol PaymentMethodsEventTarget: AnyObject {
    func paymentMethodsEvent(_ name: String, payload: [String: Any])
}

@objc(PaymentMethodsModuleShim)
internal protocol PaymentMethodsModuleShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: PaymentMethodsModuleImpl)
    @objc(emitCommand:)
    func emitCommand(_ payload: [String: Any])
    @objc(surfaceForRootTag:)
    func surface(forRootTag rootTag: NSNumber) -> AnyObject?
}

@objc(PaymentMethodsModuleImpl)
internal final class PaymentMethodsModuleImpl: NSObject {

    private weak var shim: PaymentMethodsModuleShim?

    internal func attach(to shim: PaymentMethodsModuleShim) {
        shim.attach(impl: self)
        onMain { self.shim = shim }
    }

    /// Reaches the bundle only once it has subscribed, which it does as it loads. A form
    /// therefore holds its commands until its own root has been heard from.
    internal func send(command: [String: Any]) {
        onMain { self.shim?.emitCommand(command) }
    }

    @objc(emitFieldEvent:eventName:payload:)
    internal func emitFieldEvent(_ rootTag: NSNumber, _ eventName: String, _ payload: NSDictionary) {
        deliver(rootTag, eventName, payload)
    }

    @objc(emitFormEvent:eventName:payload:)
    internal func emitFormEvent(_ rootTag: NSNumber, _ eventName: String, _ payload: NSDictionary) {
        deliver(rootTag, eventName, payload)
    }

    /// A root tag names its surface and the surface carries its owner, so an event finds
    /// its form or field without anything here keeping track of them.
    private func deliver(_ rootTag: NSNumber, _ eventName: String, _ payload: NSDictionary) {
        let map = (payload as? [String: Any]) ?? [:]
        onMain {
            guard let surface = self.shim?.surface(forRootTag: rootTag),
                  let target = SurfaceOwners.owner(of: surface) as? PaymentMethodsEventTarget
            else { return }
            target.paymentMethodsEvent(eventName, payload: map)
        }
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}
