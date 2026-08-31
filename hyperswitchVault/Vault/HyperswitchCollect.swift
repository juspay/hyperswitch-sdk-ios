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
 * collect.sendData(path: "/tokenize") { response in ... }
 * ```
 *
 * Sensitive inputs are rendered by React Native surfaces inside the fields;
 * this class orchestrates the VGS-shaped API: observing, state tracking,
 * sending data, alias replacement.
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

    private let session: URLSession

    public init(sdkAuthorization: String, environment: Environment) {
        self.sdkAuthorization = sdkAuthorization
        self.environment = environment
        self.session = URLSession(configuration: .default)
    }

    /// Custom backend URL (e.g. for testing).
    public init(sdkAuthorization: String, environment: Environment, customBaseURL: URL?) {
        self.sdkAuthorization = sdkAuthorization
        self.environment = environment
        self.customBaseURL = customBaseURL
        self.session = URLSession(configuration: .default)
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
        let requestId = TokeniseDispatcher.shared.register { json in
            completion(VaultTokeniseResult.parse(json))
        }
        VaultReactNativeController.shared.emitDeviceEvent(
            name: VaultReactNativeController.tokeniseEventName,
            body: [
                "requestId": requestId,
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

    // MARK: - Sending data

    /**
     * Mirrors VGS `sendData(path:extraData:completionHandler:)`.
     *
     * Validates observed fields, packs their current values, POSTs them to the
     * vault and replaces contents with vault aliases on success.
     */
    public func sendData(
        path: String,
        extraData: [String: Any]? = nil,
        completionHandler: @escaping (Response) -> Void
    ) {
        var invalid = [String]()
        var data = [String: String]()

        for field in textFields.allObjects {
            let state = field.currentState
            if state == nil || state?.isValid == false {
                invalid.append(state?.fieldName ?? field.fieldName ?? "unknown")
            } else if let fieldName = state?.fieldName, let text = state?.text {
                data[fieldName] = text
            }
        }

        guard invalid.isEmpty else {
            completionHandler(.failure(-1, nil, nil, VaultError.invalidFields(invalid)))
            return
        }

        var body: [String: Any] = [
            "data": data,
        ]
        extraData?.forEach { body[$0.key] = $0.value }

        let base = customBaseURL ?? environment.baseURL()
        let normalizedPath = path.hasPrefix("/") ? path : "/\(path)"
        guard let url = URL(string: base.absoluteString + normalizedPath) else {
            completionHandler(.failure(-1, nil, nil, VaultError.invalidFields(["<url>"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(sdkAuthorization)", forHTTPHeaderField: "Authorization")
        for (k, v) in customHeaders {
            request.setValue(v, forHTTPHeaderField: k)
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { [weak self] data_, urlResponse, error in
            let code = (urlResponse as? HTTPURLResponse)?.statusCode ?? -1
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    completionHandler(.failure(code, data_, urlResponse, error))
                    return
                }
                if (200..<300).contains(code) {
                    self.replaceFieldsWithAliases(data_)
                    completionHandler(.success(code, data_, urlResponse))
                } else {
                    completionHandler(.failure(code, data_, urlResponse, nil))
                }
            }
        }.resume()
    }

    /**
     * VGS replaces sensitive field contents with vault aliases after a
     * successful tokenization. Expected response contract:
     * `{ "fields": { "<fieldName>": "<alias>" } }`.
     */
    private func replaceFieldsWithAliases(_ data: Data?) {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fields = json["fields"] as? [String: String]
        else { return }

        for field in textFields.allObjects {
            let name = field.currentState?.fieldName ?? field.fieldName
            if let name = name, let alias = fields[name] {
                field.setAlias(alias)
            }
        }
    }
}
