import Foundation

/// Mirrors VGS `TextField.State`. Pushed from every JS-rendered vault field via
/// HyperVaultModule, keyed by surface root tag.
public struct VaultFieldState: Equatable {
    public let fieldName: String?
    public let fieldType: String?
    /// Current value (raw input, or the vault alias after tokenization).
    public let text: String
    public let isEmpty: Bool
    public let isValid: Bool
    public let isRequired: Bool
    public let isFocused: Bool
    public let isTokenized: Bool

    internal init(
        fieldName: String?,
        fieldType: String?,
        text: String,
        isEmpty: Bool,
        isValid: Bool,
        isRequired: Bool,
        isFocused: Bool,
        isTokenized: Bool
    ) {
        self.fieldName = fieldName
        self.fieldType = fieldType
        self.text = text
        self.isEmpty = isEmpty
        self.isValid = isValid
        self.isRequired = isRequired
        self.isFocused = isFocused
        self.isTokenized = isTokenized
    }

    internal func withFieldName(_ name: String?) -> VaultFieldState {
        VaultFieldState(
            fieldName: name ?? fieldName,
            fieldType: fieldType,
            text: text,
            isEmpty: isEmpty,
            isValid: isValid,
            isRequired: isRequired,
            isFocused: isFocused,
            isTokenized: isTokenized
        )
    }

    internal static func parse(_ json: String) -> VaultFieldState? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return parse(obj)
    }

    internal static func parse(_ obj: [String: Any]) -> VaultFieldState? {
        let text = (obj["value"] as? String) ?? ""
        let fieldName = (obj["fieldName"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        return VaultFieldState(
            fieldName: fieldName,
            fieldType: obj["fieldType"] as? String,
            text: text,
            isEmpty: (obj["isEmpty"] as? Bool) ?? text.isEmpty,
            isValid: (obj["isValid"] as? Bool) ?? !text.isEmpty,
            isRequired: (obj["isRequired"] as? Bool) ?? false,
            isFocused: (obj["isFocused"] as? Bool) ?? false,
            isTokenized: (obj["isTokenized"] as? Bool) ?? false
        )
    }
}
