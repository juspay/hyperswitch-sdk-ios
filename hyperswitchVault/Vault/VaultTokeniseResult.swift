import Foundation

/**
 * Outcome of HyperswitchCollect.tokenise(completion:).
 *
 * Mirrors the JS vault package's `vaultSubmitResult` serialization
 * ({status, token?, error?}) one-to-one, so a natively-driven tokenise and a
 * merchant-RN submit() report identically.
 */
public enum VaultTokeniseResult: Equatable {
    case success(token: String)
    case validationError(code: String, message: String)
    case notReady(code: String, message: String)
    case error(code: String, message: String)

    internal static func parse(_ json: String) -> VaultTokeniseResult {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return .error(code: "unknown_outcome", message: "We could not confirm your card.")
        }
        let error = obj["error"] as? [String: Any]
        let code = (error?["code"] as? String) ?? ""
        let message = (error?["message"] as? String) ?? ""
        switch (obj["status"] as? String) ?? "" {
        case "success":
            return .success(token: (obj["token"] as? String) ?? "")
        case "validation_error":
            return .validationError(code: code, message: message)
        case "not_ready":
            return .notReady(code: code, message: message)
        default:
            return .error(code: code, message: message)
        }
    }
}
