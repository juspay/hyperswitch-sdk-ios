import Foundation

/**
 * Redacted snapshot pushed from every JS-rendered vault field. The raw value
 * never crosses the bridge — only flags and (for `card_number`) the PCI-safe
 * 6-digit BIN required for brand lookup. There is no `value`/`text` member.
 */
public struct VaultFieldState: Equatable {
    public let fieldName: String?
    public let fieldType: String?
    public let bin: String?
    public let isEmpty: Bool
    public let isValid: Bool
    public let isRequired: Bool
    public let isFocused: Bool
    public let isTokenized: Bool

    internal init(
        fieldName: String?,
        fieldType: String?,
        bin: String?,
        isEmpty: Bool,
        isValid: Bool,
        isRequired: Bool,
        isFocused: Bool,
        isTokenized: Bool
    ) {
        self.fieldName = fieldName
        self.fieldType = fieldType
        self.bin = bin
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
            bin: bin,
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
        let fieldName = (obj["fieldName"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let bin = (obj["bin"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        return VaultFieldState(
            fieldName: fieldName,
            fieldType: obj["fieldType"] as? String,
            bin: bin,
            isEmpty: (obj["isEmpty"] as? Bool) ?? true,
            isValid: (obj["isValid"] as? Bool) ?? false,
            isRequired: (obj["isRequired"] as? Bool) ?? false,
            isFocused: (obj["isFocused"] as? Bool) ?? false,
            isTokenized: (obj["isTokenized"] as? Bool) ?? false
        )
    }
}
