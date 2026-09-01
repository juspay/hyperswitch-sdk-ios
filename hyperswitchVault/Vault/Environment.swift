import Foundation

/// Mirrors VGS `Environment`. Same shape as Android's
/// `io.hyperswitch.vault.core.Environment`: a case name, the Hyperswitch host
/// piece as rawValue, and the JS vault package's environment identifier.
public enum Environment: String {
    case sandbox = "app"
    case live = "live"
    case integration = "integ"

    /// https://<host piece>.hyperswitch.io — the vault itself is resolved
    /// server-side from the `sdkAuthorization` token sent in the Authorization
    /// header.
    internal func baseURL() -> URL {
        URL(string: "https://\(rawValue).hyperswitch.io")!
    }

    /// The JS vault package's environment identifier (VaultConfirm).
    internal var jsName: String {
        switch self {
        case .sandbox: return "sandbox"
        case .live: return "production"
        case .integration: return "integration"
        }
    }
}
