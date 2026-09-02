import Foundation

/**
 * Merchant per-field options — the React Native vault's `fieldOptions` /
 * `cardNumberOptions` / `cvcOptions` contract.
 *
 * `appearance` decides *how the field looks*; `options` decides *which
 * visual elements exist*. Per-field extras (`brandIconMode` is card-number
 * only, `cvcIcon` is cvc only) are simply absent from the dictionary when
 * not set — the JS side owns the defaults.
 */
public struct VaultFieldOptions {

    public enum LabelBehavior: String {
        case none = "none"
        case `static` = "static"
        case floating = "floating"
    }

    public enum ErrorDisplay: String {
        case none = "none"
        case inline = "inline"
    }

    public enum CvcIcon: String {
        case none = "none"
        case `default` = "default"
    }

    public var placeholder: String?
    public var label: String?
    public var labelBehavior: LabelBehavior?
    public var errorDisplay: ErrorDisplay?
    public var accessibilityLabel: String?
    public var accessibilityHint: String?
    public var testID: String?
    /// Card-number field only. Falls back to `appearance.brandIconMode`, then `hidden`.
    public var brandIconMode: VaultAppearance.BrandIconMode?
    /// CVC field only.
    public var cvcIcon: CvcIcon?
    /**
     * Renders the field as a bare input — no label, icons, box or inline
     * error UI. Wins over the other options; accessibility text and masking
     * survive. Technical details in the RN vault's field-options docs.
     */
    public var unstyled: Bool?
    /// Per-slot styles; a style never turns an element on.
    public var styles: VaultFieldStyles?

    public init(
        placeholder: String? = nil,
        label: String? = nil,
        labelBehavior: LabelBehavior? = nil,
        errorDisplay: ErrorDisplay? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        testID: String? = nil,
        brandIconMode: VaultAppearance.BrandIconMode? = nil,
        cvcIcon: CvcIcon? = nil,
        unstyled: Bool? = nil,
        styles: VaultFieldStyles? = nil
    ) {
        self.placeholder = placeholder
        self.label = label
        self.labelBehavior = labelBehavior
        self.errorDisplay = errorDisplay
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.testID = testID
        self.brandIconMode = brandIconMode
        self.cvcIcon = cvcIcon
        self.unstyled = unstyled
        self.styles = styles
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = placeholder { out["placeholder"] = v }
        if let v = label { out["label"] = v }
        if let v = labelBehavior { out["labelBehavior"] = v.rawValue }
        if let v = errorDisplay { out["errorDisplay"] = v.rawValue }
        if let v = accessibilityLabel { out["accessibilityLabel"] = v }
        if let v = accessibilityHint { out["accessibilityHint"] = v }
        if let v = testID { out["testID"] = v }
        if let v = brandIconMode { out["brandIconMode"] = v.rawValue }
        if let v = cvcIcon { out["cvcIcon"] = v.rawValue }
        if let v = unstyled { out["unstyled"] = v }
        if let v = styles, !v.isEmpty { out["styles"] = v.dict }
        return out
    }

    /// Returns a copy with each unset member taken from `base`.
    public func merged(over base: VaultFieldOptions?) -> VaultFieldOptions {
        guard let base else { return self }
        var out = self
        if out.placeholder == nil { out.placeholder = base.placeholder }
        if out.label == nil { out.label = base.label }
        if out.labelBehavior == nil { out.labelBehavior = base.labelBehavior }
        if out.errorDisplay == nil { out.errorDisplay = base.errorDisplay }
        if out.accessibilityLabel == nil { out.accessibilityLabel = base.accessibilityLabel }
        if out.accessibilityHint == nil { out.accessibilityHint = base.accessibilityHint }
        if out.testID == nil { out.testID = base.testID }
        if out.brandIconMode == nil { out.brandIconMode = base.brandIconMode }
        if out.cvcIcon == nil { out.cvcIcon = base.cvcIcon }
        if out.unstyled == nil { out.unstyled = base.unstyled }
        let mergedStyles = out.styles?.merged(over: base.styles) ?? base.styles
        out.styles = mergedStyles
        return out
    }
}
