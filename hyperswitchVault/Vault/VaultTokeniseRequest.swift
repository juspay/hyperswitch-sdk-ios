//
//  VaultTokeniseRequest.swift
//  HyperswitchVault
//
//  Typed native → JS tokenise broadcast payload (request channel).
//
//  Single Swift source of truth for the `hsVaultTokenise` event contract;
//  the JS decoder lives in
//  hyperswitch-client-core/src/vault/VaultTokenise.res
//  (types in src/specs/NativeHyperVaultModule.ts),
//  the Kotlin peer in VaultTokeniseRequest.kt — keep all three in sync.
//

import Foundation

struct VaultTokeniseRequest {

    /// Base64 JSON carrying payment_method_session_id; nil = the claiming
    /// surface falls back to its own sdkAuthorization.
    let sdkAuthorization: String?

    /// "sandbox" | "integration" | "production"; nil = surface fallback.
    let environment: String?

    init(sdkAuthorization: String? = nil, environment: String? = nil) {
        self.sdkAuthorization = sdkAuthorization
        self.environment = environment
    }

    /// Wire shape: a JSON object; absent members are simply not encoded.
    /// Travels on the codegen EventEmitter named `onVaultTokenise` — the
    /// `onVaultTokenise` property in src/specs/NativeHyperVaultModule.ts.
    var dictionary: [String: Any] {
        var body: [String: Any] = [:]
        if let sdkAuthorization = sdkAuthorization {
            body["sdkAuthorization"] = sdkAuthorization
        }
        if let environment = environment {
            body["environment"] = environment
        }
        return body
    }
}
