//
//  HyperVaultModule.swift
//  HyperswitchVault
//
//  Swift backing for the new-arch HyperVaultModule TurboModule. Called from
//  HyperVaultModule.mm, which forwards NativeHyperVaultModuleSpec here.
//

import Foundation

@objc(HyperVaultModuleImpl)
public final class HyperVaultModuleImpl: NSObject {

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
}
