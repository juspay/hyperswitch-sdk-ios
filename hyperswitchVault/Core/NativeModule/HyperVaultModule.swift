//
//  HyperVaultModule.swift
//  HyperswitchVault
//
//  Swift backing for the new-arch HyperVaultModule TurboModule. Called from
//  HyperVaultModule.mm, which forwards NativeHyperVaultModuleSpec here.
//

import Foundation

/**
 * Swift-side handle for the codegen HyperVaultModule TurboModule: the ObjC
 * bridge (HyperVaultModule.mm) conforms to this protocol; VaultReactDelegate
 * factory-creates the .mm instance and attaches it to the Impl singleton
 * (twin of the main SDK's HyperModuleShim / RNFactoryDelegate wiring).
 */
@objc(HyperVaultModuleShim)
public protocol HyperVaultModuleShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: HyperVaultModuleImpl)
    @objc(emitVaultTokeniseEventWithSdkAuthorization:environment:)
    func emitVaultTokeniseEvent(sdkAuthorization: String?, environment: String?)
}

@objc(HyperVaultModuleImpl)
public final class HyperVaultModuleImpl: NSObject {

    private weak var shim: HyperVaultModuleShim?

    /// Aggregated, redacted states pushed by the JS vault package, keyed by
    /// field type (updateVaultFieldStates contract, mirrors Android).
    @objc(updateVaultFieldStates:)
    public func updateVaultFieldStates(_ statesJson: String) {
        VaultStateStore.shared.updateFieldStates(statesJson)
    }

    @objc(updateFieldState:state:)
    public func updateFieldState(_ rootTag: NSNumber, state: String) {
        VaultStateStore.shared.update(rootTag: rootTag, json: state)
    }

    /// The JS answer to a native tokenise() broadcast; resolves the pending
    /// collector completion via TokeniseDispatcher.
    @objc(returnTokenizedValue:)
    public func returnTokenizedValue(_ resultJson: String) {
        TokeniseDispatcher.shared.resolve(resultJson)
    }

    // MARK: - Native → JS typed request broadcast (the answer channel is the
    // returnTokenizedValue TurboModule method above; this emit funnel is the
    // vault twin of the main SDK's HyperModuleImpl.emit → shim chain).

    internal func attach(to shim: HyperVaultModuleShim) {
        shim.attach(impl: self)
        onMain {
            self.shim = shim
        }
    }

    /// Broadcasts the tokenise request over the codegen-typed onVaultTokenise
    /// EventEmitter. Fire-and-forget: if no JS surface claims it, the
    /// TokeniseDispatcher 30s net still fires the merchant's completion.
    internal func emitVaultTokenise(_ request: VaultTokeniseRequest) {
        onMain {
            self.shim?.emitVaultTokeniseEvent(
                sdkAuthorization: request.sdkAuthorization,
                environment: request.environment
            )
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
