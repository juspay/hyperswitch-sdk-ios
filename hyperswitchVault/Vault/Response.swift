import Foundation

/// Mirrors VGS `Response` / `Collector.sendData(...)` completion payload.
public enum Response {
    /// Request to vault succeeded.
    /// - Parameters: HTTP status, raw body, raw URL response.
    case success(Int, Data?, URLResponse?)

    /// Request failed (network or validation).
    case failure(Int, Data?, URLResponse?, Error?)
}

/// Local (pre-network) validation error, mirrors VGS pre-send field errors.
public enum VaultError: Error, LocalizedError {
    case invalidFields([String])

    public var errorDescription: String? {
        switch self {
        case .invalidFields(let names):
            return "Invalid or empty required fields: \(names.joined(separator: ", "))"
        }
    }
}
