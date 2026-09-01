import UIKit

/**
 * HyperswitchCollect
 *
 * VGS-compatible entry point of the Hyperswitch Vault iOS SDK
 * (pod `hyperswitch-vault-sdk-ios`).
 *
 * ```swift
 * let collect = HyperswitchCollect(sdkAuthorization: "sdk_...", environment: .sandbox)
 * cardField.configuration = VaultConfiguration(collector: collect, fieldName: "card_number")
 * expDateField.configuration = VaultConfiguration(collector: collect, fieldName: "exp_date")
 * cvcField.configuration = VaultConfiguration(collector: collect, fieldName: "cvc")
 * collect.tokenise { result in ... }
 * ```
 *
 * Sensitive inputs are rendered by React Native surfaces inside the fields;
 * this class orchestrates the VGS-shaped API: observing, state tracking,
 * tokenization. Raw card values never cross the bridge into native.
 */
public final class HyperswitchCollect {

    /// Hyperswitch Vault SDK authorization token (identifies the vault).
    public let sdkAuthorization: String
    public let environment: Environment
    public var customBaseURL: URL?

    /// Observed secure fields (weak, like VGS's storage).
    internal let textFields = NSHashTable<HyperswitchTextField>(options: .weakMemory)

    /// Mirrors VGS `customHeaders`.
    public var customHeaders: [String: String] = [:]

    public init(sdkAuthorization: String, environment: Environment) {
        self.sdkAuthorization = sdkAuthorization
        self.environment = environment
    }

    /// Custom backend URL (e.g. for testing).
    public init(sdkAuthorization: String, environment: Environment, customBaseURL: URL?) {
        self.sdkAuthorization = sdkAuthorization
        self.environment = environment
        self.customBaseURL = customBaseURL
    }

    // MARK: - Tokenise

    /**
     * Broadcasts a tokenise request to all JS vault field surfaces. The CVC
     * field surface answers with the collected states of every field, read
     * from the shared JS registry (src/vault/registry.js); the raw per-state
     * native layer (updateFieldState) is untouched.
     */
    public func tokenise() {
        VaultReactNativeController.shared.emitDeviceEvent(
            name: VaultReactNativeController.tokeniseEventName,
            body: nil
        )
    }

    /**
     * Tokenises the values of every observed field and reports the outcome
     * on the main thread.
     *
     * The broadcast is claimed by exactly one mounted JS vault surface, which
     * runs the payment-method-session confirm from the shared JS registry and
     * answers with the vaultSubmitResult JSON; the TokeniseDispatcher timeout
     * guarantees `completion` fires even when no surface is mounted.
     */
    public func tokenise(completion: @escaping (VaultTokeniseResult) -> Void) {
        TokeniseDispatcher.shared.register { json in
            completion(VaultTokeniseResult.parse(json))
        }
        VaultReactNativeController.shared.emitDeviceEvent(
            name: VaultReactNativeController.tokeniseEventName,
            body: [
                "sdkAuthorization": sdkAuthorization,
                "environment": environment.jsName,
            ]
        )
    }

    // MARK: - Observing (VGS: fields register through VGSConfiguration)

    internal func observeTextField(_ field: HyperswitchTextField) {
        textFields.add(field)
    }

    internal func unObserveTextField(_ field: HyperswitchTextField) {
        textFields.remove(field)
    }

    // MARK: - State

    /// Mirrors VGS `collect.getStates` — latest known state of observed fields.
    public func getStates() -> [VaultFieldState] {
        textFields.allObjects.compactMap { $0.currentState }
    }

}
