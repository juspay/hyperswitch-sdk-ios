import Foundation

/// Mirrors VGS `VGSConfiguration`: links a text field to its collector.
public final class VaultConfiguration {

    /// Collector which owns this field (weak, like VGS).
    public weak var collector: HyperswitchCollect?

    /// Name the field value is submitted under (mirrors VGS `fieldName`).
    public var fieldName: String = ""

    public var isRequired: Bool = true

    /// Theme tokens for the JS-rendered input — travels under `configuration.appearance`.
    public var appearance: VaultAppearance?

    /// Per-field options — travels under `configuration.options`.
    public var options: VaultFieldOptions?

    public convenience init(collector: HyperswitchCollect, fieldName: String) {
        self.init(collector: collector, fieldName: fieldName, isRequired: true)
    }

    public init(collector: HyperswitchCollect, fieldName: String, isRequired: Bool = true) {
        self.collector = collector
        self.fieldName = fieldName
        self.isRequired = isRequired
    }
}
