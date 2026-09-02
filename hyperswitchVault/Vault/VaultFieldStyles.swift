import UIKit

/**
 * A view-style slot of `VaultFieldStyles`. Typed subset of the React Native
 * `ViewStyle` keys the JS vault surfaces accept under
 * `configuration.options.styles.{root,container,accessory}` — keys not listed
 * here are deliberately not settable from native.
 *
 * Numeric values are points; colors are converted with the same alpha-first
 * hex the appearance tokens use (see `UIColor.hexString`).
 */
public struct VaultViewStyle {

    public var backgroundColor: UIColor?
    public var width: CGFloat?
    public var height: CGFloat?
    public var marginTop: CGFloat?
    public var marginBottom: CGFloat?
    public var marginStart: CGFloat?
    public var marginEnd: CGFloat?

    public init(
        backgroundColor: UIColor? = nil,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        marginTop: CGFloat? = nil,
        marginBottom: CGFloat? = nil,
        marginStart: CGFloat? = nil,
        marginEnd: CGFloat? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.width = width
        self.height = height
        self.marginTop = marginTop
        self.marginBottom = marginBottom
        self.marginStart = marginStart
        self.marginEnd = marginEnd
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = backgroundColor { out["backgroundColor"] = v.hexString }
        if let v = width { out["width"] = v }
        if let v = height { out["height"] = v }
        if let v = marginTop { out["marginTop"] = v }
        if let v = marginBottom { out["marginBottom"] = v }
        if let v = marginStart { out["marginStart"] = v }
        if let v = marginEnd { out["marginEnd"] = v }
        return out
    }

    internal var isEmpty: Bool {
        backgroundColor == nil && width == nil && height == nil &&
            marginTop == nil && marginBottom == nil &&
            marginStart == nil && marginEnd == nil
    }
}

/**
 * A text-style slot of `VaultFieldStyles`. Typed subset of the React Native
 * `TextStyle` keys accepted under
 * `configuration.options.styles.{input,placeholder,label,error}`.
 *
 * `fontWeight` takes a React Native weight string: "normal", "bold" or a
 * hundred-step value "100"…"900". `textAlign` takes "auto", "left", "right",
 * "center" or "justify".
 */
public struct VaultTextStyle {

    public var color: UIColor?
    public var backgroundColor: UIColor?
    public var fontSize: CGFloat?
    public var fontFamily: String?
    public var fontWeight: String?
    public var letterSpacing: CGFloat?
    public var textAlign: String?

    public init(
        color: UIColor? = nil,
        backgroundColor: UIColor? = nil,
        fontSize: CGFloat? = nil,
        fontFamily: String? = nil,
        fontWeight: String? = nil,
        letterSpacing: CGFloat? = nil,
        textAlign: String? = nil
    ) {
        self.color = color
        self.backgroundColor = backgroundColor
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.fontWeight = fontWeight
        self.letterSpacing = letterSpacing
        self.textAlign = textAlign
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = color { out["color"] = v.hexString }
        if let v = backgroundColor { out["backgroundColor"] = v.hexString }
        if let v = fontSize { out["fontSize"] = v }
        if let v = fontFamily { out["fontFamily"] = v }
        if let v = fontWeight { out["fontWeight"] = v }
        if let v = letterSpacing { out["letterSpacing"] = v }
        if let v = textAlign { out["textAlign"] = v }
        return out
    }

    internal var isEmpty: Bool {
        color == nil && backgroundColor == nil && fontSize == nil &&
            fontFamily == nil && fontWeight == nil && letterSpacing == nil &&
            textAlign == nil
    }
}

/**
 * Per-slot styles for one vault field — the React Native vault's
 * `CardFieldStyles.fieldStyles` contract, travelling under
 * `configuration.options.styles`.
 *
 * Field **options** decide whether an element exists; these styles decide how
 * it looks — setting a style slot never turns the element on. `accessory` is
 * the brand-icon/glyph container; the expiry field has no accessory element.
 */
public struct VaultFieldStyles {

    public var root: VaultViewStyle?
    public var container: VaultViewStyle?
    public var input: VaultTextStyle?
    public var placeholder: VaultTextStyle?
    public var label: VaultTextStyle?
    public var error: VaultTextStyle?
    public var accessory: VaultViewStyle?

    public init(
        root: VaultViewStyle? = nil,
        container: VaultViewStyle? = nil,
        input: VaultTextStyle? = nil,
        placeholder: VaultTextStyle? = nil,
        label: VaultTextStyle? = nil,
        error: VaultTextStyle? = nil,
        accessory: VaultViewStyle? = nil
    ) {
        self.root = root
        self.container = container
        self.input = input
        self.placeholder = placeholder
        self.label = label
        self.error = error
        self.accessory = accessory
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = root, !v.isEmpty { out["root"] = v.dict }
        if let v = container, !v.isEmpty { out["container"] = v.dict }
        if let v = input, !v.isEmpty { out["input"] = v.dict }
        if let v = placeholder, !v.isEmpty { out["placeholder"] = v.dict }
        if let v = label, !v.isEmpty { out["label"] = v.dict }
        if let v = error, !v.isEmpty { out["error"] = v.dict }
        if let v = accessory, !v.isEmpty { out["accessory"] = v.dict }
        return out
    }

    internal var isEmpty: Bool {
        (root?.isEmpty ?? true) && (container?.isEmpty ?? true) &&
            (input?.isEmpty ?? true) && (placeholder?.isEmpty ?? true) &&
            (label?.isEmpty ?? true) && (error?.isEmpty ?? true) &&
            (accessory?.isEmpty ?? true)
    }

    /// Returns a copy with each unset slot taken from `base`.
    public func merged(over base: VaultFieldStyles?) -> VaultFieldStyles {
        guard let base else { return self }
        var out = self
        if out.root == nil { out.root = base.root }
        if out.container == nil { out.container = base.container }
        if out.input == nil { out.input = base.input }
        if out.placeholder == nil { out.placeholder = base.placeholder }
        if out.label == nil { out.label = base.label }
        if out.error == nil { out.error = base.error }
        if out.accessory == nil { out.accessory = base.accessory }
        return out
    }
}
