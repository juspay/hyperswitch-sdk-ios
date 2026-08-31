import Foundation

/// Mirrors VGS `Environment`.
public enum Environment: String {
    case sandbox
    case live

    /// https://<env>.hyperswitch.io — the vault itself is resolved server-side
    /// from the `sdkAuthorization` token sent in the Authorization header.
    internal func baseURL() -> URL {
        URL(string: "https://\(rawValue).hyperswitch.io")!
    }

    /// The JS vault package's environment identifier (VaultConfirm).
    internal var jsName: String {
        switch self {
        case .sandbox: return "sandbox"
        case .live: return "production"
        }
    }
}
