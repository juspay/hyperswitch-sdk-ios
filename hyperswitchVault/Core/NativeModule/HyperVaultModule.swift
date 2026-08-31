//
//  HyperVaultModule.swift
//  HyperswitchVault
//
//  Bridge for JS -> native vault field-state pushes (src/vault/fields/BaseTextInput.js).
//

import Foundation
import React

@objc(HyperVaultModule)
public final class HyperVaultModule: NSObject {

    @objc
    public static func requiresMainQueueSetup() -> Bool {
        return false
    }

    @objc(updateFieldState:state:)
    public func updateFieldState(_ rootTag: NSNumber, state: String) {
        VaultStateStore.shared.update(rootTag: rootTag, json: state)
    }

    /// Aggregated, redacted states pushed by the JS vault package, keyed by
    /// field type (updateVaultFieldStates contract, mirrors Android).
    @objc(updateVaultFieldStates:)
    public func updateVaultFieldStates(_ statesJson: String) {
        VaultStateStore.shared.updateFieldStates(statesJson)
    }

    /// The JS answer to a native tokenise() broadcast; resolves the pending
    /// collector completion via TokeniseDispatcher.
    @objc(submitTokeniseResult:resultJson:)
    public func submitTokeniseResult(_ requestId: NSNumber, resultJson: String) {
        TokeniseDispatcher.shared.resolve(id: requestId.intValue, json: resultJson)
    }
}
