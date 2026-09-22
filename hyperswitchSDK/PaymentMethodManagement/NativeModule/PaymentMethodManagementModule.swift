//
//  PaymentMethodManagementModule.swift
//  Hyperswitch
//
//  The contract between the hyperswitch-payment-method-management bundle and its native owners. Mirrors the
//  payments `HyperModule` API surface, PMM-scoped: a sheet or widget root resolves by
//  root tag through `SurfaceOwners`, so nothing here tracks surfaces itself.
//

import Foundation
import React

/// The one component the pmm bundle registers.
internal enum PMMProtocol {
    static let component = "hyperPMM"

    static let sheetType = "paymentMethodsManagement"
    static let widgetType = "widgetPaymentMethodsManagement"

    static let confirmAction = "CONFIRM_PAYMENT_ACTION"
    static let triggerWidgetActionEvent = "triggerWidgetAction"
}

/// The native owner of a PMM root: what the bundle says about that root lands here.
internal protocol PaymentMethodManagementEventTarget: AnyObject {
    /// JS says the surface is finished. A sheet dismisses; a widget resolves its
    /// pending `tokenize` and stays mounted.
    func pmmExit(_ result: PaymentResult, reset: Bool)
    /// A merchant-driven tokenize was refused (e.g. form validation): the surface
    /// stays mounted for retry; a sheet has nothing to do with these.
    func pmmNonTerminalResult(_ result: PaymentResult)
    /// Merchant payment-event subscription dispatch.
    func pmmPaymentEvent(type: String, payload: [String: Any])
}

@objc(PaymentMethodManagementModuleShim)
internal protocol PaymentMethodManagementModuleShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: PaymentMethodManagementModuleImpl)
    @objc(emitEventWithName:payload:)
    func emitEvent(name: String, payload: [String: Any])
    @objc(surfaceForRootTag:)
    func surface(forRootTag rootTag: NSNumber) -> AnyObject?
}

@objc(PaymentMethodManagementModuleImpl)
internal final class PaymentMethodManagementModuleImpl: NSObject {

    private weak var shim: PaymentMethodManagementModuleShim?

    internal func attach(to shim: PaymentMethodManagementModuleShim) {
        shim.attach(impl: self)
        onMain { self.shim = shim }
    }

    /// Native → JS. The merchant's `tokenize` call reaches the bundle only once the
    /// widget has mounted and subscribed, which a tapped tokenize implies.
    internal func emitTriggerWidgetAction(_ payload: [String: Any]) {
        onMain { self.shim?.emitEvent(name: PMMProtocol.triggerWidgetActionEvent, payload: payload) }
    }

    // MARK: JS → native (spec methods on `HyperPMMModule`)

    @objc(exitPaymentMethodManagement:result:reset:)
    internal func exitPaymentMethodManagement(_ rootTag: NSNumber, _ result: String, _ reset: Bool) {
        let parsed = Self.parseExitResult(result)
        guard let target = owner(of: rootTag) else { return }
        onMain { target.pmmExit(parsed, reset: reset) }
    }

    @objc(notifyWidgetPaymentResult:status:code:message:)
    internal func notifyWidgetPaymentResult(_ rootTag: NSNumber, _ status: String, _ code: String?, _ message: String?) {
        let parsed = PaymentResult.from(status: status, code: code, message: message)
        guard let target = owner(of: rootTag) else { return }
        onMain { target.pmmNonTerminalResult(parsed) }
    }

    @objc(emitPaymentEvent:eventType:payload:)
    internal func emitPaymentEvent(_ rootTag: NSNumber, _ eventType: String, _ payload: NSDictionary) {
        let map = (payload as? [String: Any]) ?? [:]
        guard let target = owner(of: rootTag) else { return }
        onMain { target.pmmPaymentEvent(type: eventType, payload: map) }
    }

    // MARK: Routing

    /// A root tag names its surface and the surface carries its owner, so a call finds
    /// its sheet or widget without anything here keeping track of them.
    private func owner(of rootTag: NSNumber) -> PaymentMethodManagementEventTarget? {
        guard let surface = shim?.surface(forRootTag: rootTag) else { return nil }
        return SurfaceOwners.owner(of: surface) as? PaymentMethodManagementEventTarget
    }

    private static func parseExitResult(_ rnMessage: String) -> PaymentResult {
        let json = (try? JSONSerialization.jsonObject(with: Data(rnMessage.utf8))) as? [String: Any]
        return PaymentResult.from(
            status: json?["status"] as? String ?? "failed",
            code: json?["code"] as? String,
            message: json?["message"] as? String
        )
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}
