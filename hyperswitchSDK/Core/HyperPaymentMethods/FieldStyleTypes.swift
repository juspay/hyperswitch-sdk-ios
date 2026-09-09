//
//  FieldStyleTypes.swift
//  Hyperswitch
//
//  Mirrors the payment-methods package's `FieldStyles`/`Appearance`/`FieldOptions` types
//  (`core/types.ts`) so native can express the same customization surface with real typed
//  structs instead of raw dictionaries. Every `toDictionary()` below produces exactly the
//  JSON shape the JS side expects at `configuration.styles` / `configuration.options` /
//  `configuration.appearance.variables`.
//

import UIKit

/// A ViewStyle-shaped slot (`root`, `container`, `accessory`).
public struct ViewStyleProps {
    public var backgroundColor: UIColor?
    public var borderRadius: CGFloat?
    public var borderWidth: CGFloat?
    public var borderColor: UIColor?
    public var padding: CGFloat?
    public var height: CGFloat?

    public init(
        backgroundColor: UIColor? = nil,
        borderRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        borderColor: UIColor? = nil,
        padding: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.borderRadius = borderRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.padding = padding
        self.height = height
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let backgroundColor { dict["backgroundColor"] = backgroundColor.hexString }
        if let borderRadius { dict["borderRadius"] = borderRadius }
        if let borderWidth { dict["borderWidth"] = borderWidth }
        if let borderColor { dict["borderColor"] = borderColor.hexString }
        if let padding { dict["padding"] = padding }
        if let height { dict["height"] = height }
        return dict
    }

    var isEmpty: Bool { toDictionary().isEmpty }
}

/// A TextStyle-shaped slot (`input`, `placeholder`, `label`, `error`).
public struct TextStyleProps {
    public var color: UIColor?
    public var fontSize: CGFloat?

    public init(color: UIColor? = nil, fontSize: CGFloat? = nil) {
        self.color = color
        self.fontSize = fontSize
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let color { dict["color"] = color.hexString }
        if let fontSize { dict["fontSize"] = fontSize }
        return dict
    }

    var isEmpty: Bool { toDictionary().isEmpty }
}

/// Mirrors `FieldStyles` — every style slot a field can be given.
public struct FieldStyles {
    public var root: ViewStyleProps?
    public var container: ViewStyleProps?
    public var input: TextStyleProps?
    public var placeholder: TextStyleProps?
    public var label: TextStyleProps?
    public var error: TextStyleProps?
    public var accessory: ViewStyleProps?

    public init(
        root: ViewStyleProps? = nil,
        container: ViewStyleProps? = nil,
        input: TextStyleProps? = nil,
        placeholder: TextStyleProps? = nil,
        label: TextStyleProps? = nil,
        error: TextStyleProps? = nil,
        accessory: ViewStyleProps? = nil
    ) {
        self.root = root
        self.container = container
        self.input = input
        self.placeholder = placeholder
        self.label = label
        self.error = error
        self.accessory = accessory
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let root, !root.isEmpty { dict["root"] = root.toDictionary() }
        if let container, !container.isEmpty { dict["container"] = container.toDictionary() }
        if let input, !input.isEmpty { dict["input"] = input.toDictionary() }
        if let placeholder, !placeholder.isEmpty { dict["placeholder"] = placeholder.toDictionary() }
        if let label, !label.isEmpty { dict["label"] = label.toDictionary() }
        if let error, !error.isEmpty { dict["error"] = error.toDictionary() }
        if let accessory, !accessory.isEmpty { dict["accessory"] = accessory.toDictionary() }
        return dict
    }

    var isEmpty: Bool { toDictionary().isEmpty }
}

/// Mirrors `BrandIconMode`.
public enum BrandIconMode: String {
    case standard
    case animated
    case hidden
    case hideGeneric
}

/// Mirrors `CvcIconDisplay`.
public enum CvcIconDisplay: String {
    case hidden
    case `default`
}

/// Mirrors `LabelBehavior`.
public enum LabelBehavior: String {
    case above
    case floating
    case never
}

/// Mirrors `ErrorDisplay`.
public enum ErrorDisplay: String {
    case none
    case colorOnly
    case inline
}

/// Mirrors `FieldOptions` — non-style per-field configuration. `cardBrandIcon` is only
/// honored on the `cardNumber` field, `cvcIcon` only on `cardCvc` (same as the JS side).
public struct FieldOptions {
    public var label: String?
    public var labelBehavior: LabelBehavior?
    public var errorDisplay: ErrorDisplay?
    public var unstyled: Bool?
    public var accessibilityLabel: String?
    public var accessibilityHint: String?
    public var cardBrandIcon: BrandIconMode?
    public var cvcIcon: CvcIconDisplay?

    public init(
        label: String? = nil,
        labelBehavior: LabelBehavior? = nil,
        errorDisplay: ErrorDisplay? = nil,
        unstyled: Bool? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        cardBrandIcon: BrandIconMode? = nil,
        cvcIcon: CvcIconDisplay? = nil
    ) {
        self.label = label
        self.labelBehavior = labelBehavior
        self.errorDisplay = errorDisplay
        self.unstyled = unstyled
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.cardBrandIcon = cardBrandIcon
        self.cvcIcon = cvcIcon
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let label { dict["label"] = label }
        if let labelBehavior { dict["labelBehavior"] = labelBehavior.rawValue }
        if let errorDisplay { dict["errorDisplay"] = errorDisplay.rawValue }
        if let unstyled { dict["unstyled"] = unstyled }
        if let accessibilityLabel { dict["accessibilityLabel"] = accessibilityLabel }
        if let accessibilityHint { dict["accessibilityHint"] = accessibilityHint }
        if let cardBrandIcon { dict["cardBrandIcon"] = cardBrandIcon.rawValue }
        if let cvcIcon { dict["cvcIcon"] = cvcIcon.rawValue }
        return dict
    }

    var isEmpty: Bool { toDictionary().isEmpty }
}

/// Mirrors `AppearanceVariables` — flat theming primitives forwarded to a vault's own
/// native/webview rendering. Only honored by the `hyperswitch` vault adapter today; other
/// vault types ignore fields they don't support. Set on `PaymentMethodSession.createCardForm`
/// (session-level — there's no per-field equivalent, matching the JS `Appearance.variables`
/// shape it mirrors).
public struct AppearanceVariables {
    public var colorPrimary: UIColor?
    public var colorText: UIColor?
    public var colorDanger: UIColor?
    public var colorTextPlaceholder: UIColor?
    public var colorBackground: UIColor?
    public var borderColor: UIColor?
    public var borderRadius: CGFloat?
    public var borderWidth: CGFloat?
    public var fontFamily: String?
    public var fontScale: CGFloat?
    public var inputFieldHeight: CGFloat?
    public var gap: CGFloat?
    public var placeholderTextSizeAdjust: CGFloat?
    public var errorTextSizeAdjust: CGFloat?
    public var errorMessageSpacing: CGFloat?
    public var cardBrandIcon: BrandIconMode?

    public init(
        colorPrimary: UIColor? = nil,
        colorText: UIColor? = nil,
        colorDanger: UIColor? = nil,
        colorTextPlaceholder: UIColor? = nil,
        colorBackground: UIColor? = nil,
        borderColor: UIColor? = nil,
        borderRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        fontFamily: String? = nil,
        fontScale: CGFloat? = nil,
        inputFieldHeight: CGFloat? = nil,
        gap: CGFloat? = nil,
        placeholderTextSizeAdjust: CGFloat? = nil,
        errorTextSizeAdjust: CGFloat? = nil,
        errorMessageSpacing: CGFloat? = nil,
        cardBrandIcon: BrandIconMode? = nil
    ) {
        self.colorPrimary = colorPrimary
        self.colorText = colorText
        self.colorDanger = colorDanger
        self.colorTextPlaceholder = colorTextPlaceholder
        self.colorBackground = colorBackground
        self.borderColor = borderColor
        self.borderRadius = borderRadius
        self.borderWidth = borderWidth
        self.fontFamily = fontFamily
        self.fontScale = fontScale
        self.inputFieldHeight = inputFieldHeight
        self.gap = gap
        self.placeholderTextSizeAdjust = placeholderTextSizeAdjust
        self.errorTextSizeAdjust = errorTextSizeAdjust
        self.errorMessageSpacing = errorMessageSpacing
        self.cardBrandIcon = cardBrandIcon
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let colorPrimary { dict["colorPrimary"] = colorPrimary.hexString }
        if let colorText { dict["colorText"] = colorText.hexString }
        if let colorDanger { dict["colorDanger"] = colorDanger.hexString }
        if let colorTextPlaceholder { dict["colorTextPlaceholder"] = colorTextPlaceholder.hexString }
        if let colorBackground { dict["colorBackground"] = colorBackground.hexString }
        if let borderColor { dict["borderColor"] = borderColor.hexString }
        if let borderRadius { dict["borderRadius"] = borderRadius }
        if let borderWidth { dict["borderWidth"] = borderWidth }
        if let fontFamily { dict["fontFamily"] = fontFamily }
        if let fontScale { dict["fontScale"] = fontScale }
        if let inputFieldHeight { dict["inputFieldHeight"] = inputFieldHeight }
        if let gap { dict["gap"] = gap }
        if let placeholderTextSizeAdjust { dict["placeholderTextSizeAdjust"] = placeholderTextSizeAdjust }
        if let errorTextSizeAdjust { dict["errorTextSizeAdjust"] = errorTextSizeAdjust }
        if let errorMessageSpacing { dict["errorMessageSpacing"] = errorMessageSpacing }
        if let cardBrandIcon { dict["cardBrandIcon"] = cardBrandIcon.rawValue }
        return dict
    }

    var isEmpty: Bool { toDictionary().isEmpty }
}

extension UIColor {
    /// `#RRGGBB` or `#RRGGBBAA` (alpha included only when not fully opaque), matching the
    /// string color format the JS side's style resolution expects.
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int((r * 255).rounded()), gi = Int((g * 255).rounded()), bi = Int((b * 255).rounded())
        if a >= 0.999 {
            return String(format: "#%02X%02X%02X", ri, gi, bi)
        }
        let ai = Int((a * 255).rounded())
        return String(format: "#%02X%02X%02X%02X", ri, gi, bi, ai)
    }
}
