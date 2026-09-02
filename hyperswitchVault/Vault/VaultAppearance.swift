import UIKit

/**
 * UI appearance of a vault field — the merchant-owned theme token bag that
 * travels inside `configuration.appearance` of the React Native surface's
 * initial props. Flat key set matching the React Native vault's `appearance`
 * prop contract exactly (no translation layer on the JS side).
 */
public struct VaultAppearance {

    public enum BrandIconMode: String {
        case auto = "auto"
        case `static` = "static"
        case hidden = "hidden"
    }

    public var primaryColor: UIColor?
    public var textColor: UIColor?
    public var errorColor: UIColor?
    public var placeholderColor: UIColor?
    public var backgroundColor: UIColor?
    public var borderColor: UIColor?
    public var borderRadius: CGFloat?
    public var borderWidth: CGFloat?
    public var fontFamily: String?
    public var inputHeight: CGFloat?
    public var fontScale: CGFloat?
    public var gap: CGFloat?
    public var placeholderTextSizeAdjust: CGFloat?
    public var errorTextSizeAdjust: CGFloat?
    public var errorMessageSpacing: CGFloat?
    public var brandIconMode: BrandIconMode?

    public init(
        primaryColor: UIColor? = nil,
        textColor: UIColor? = nil,
        errorColor: UIColor? = nil,
        placeholderColor: UIColor? = nil,
        backgroundColor: UIColor? = nil,
        borderColor: UIColor? = nil,
        borderRadius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        fontFamily: String? = nil,
        inputHeight: CGFloat? = nil,
        fontScale: CGFloat? = nil,
        gap: CGFloat? = nil,
        placeholderTextSizeAdjust: CGFloat? = nil,
        errorTextSizeAdjust: CGFloat? = nil,
        errorMessageSpacing: CGFloat? = nil,
        brandIconMode: BrandIconMode? = nil
    ) {
        self.primaryColor = primaryColor
        self.textColor = textColor
        self.errorColor = errorColor
        self.placeholderColor = placeholderColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderRadius = borderRadius
        self.borderWidth = borderWidth
        self.fontFamily = fontFamily
        self.inputHeight = inputHeight
        self.fontScale = fontScale
        self.gap = gap
        self.placeholderTextSizeAdjust = placeholderTextSizeAdjust
        self.errorTextSizeAdjust = errorTextSizeAdjust
        self.errorMessageSpacing = errorMessageSpacing
        self.brandIconMode = brandIconMode
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = primaryColor { out["primaryColor"] = v.hexString }
        if let v = textColor { out["textColor"] = v.hexString }
        if let v = errorColor { out["errorColor"] = v.hexString }
        if let v = placeholderColor { out["placeholderColor"] = v.hexString }
        if let v = backgroundColor { out["backgroundColor"] = v.hexString }
        if let v = borderColor { out["borderColor"] = v.hexString }
        if let v = borderRadius { out["borderRadius"] = v }
        if let v = borderWidth { out["borderWidth"] = v }
        if let v = fontFamily { out["fontFamily"] = v }
        if let v = inputHeight { out["inputHeight"] = v }
        if let v = fontScale { out["fontScale"] = v }
        if let v = gap { out["gap"] = v }
        if let v = placeholderTextSizeAdjust { out["placeholderTextSizeAdjust"] = v }
        if let v = errorTextSizeAdjust { out["errorTextSizeAdjust"] = v }
        if let v = errorMessageSpacing { out["errorMessageSpacing"] = v }
        if let v = brandIconMode { out["brandIconMode"] = v.rawValue }
        return out
    }

    /// Returns a copy with each unset member taken from `base`.
    public func merged(over base: VaultAppearance?) -> VaultAppearance {
        guard let base else { return self }
        var out = self
        if out.primaryColor == nil { out.primaryColor = base.primaryColor }
        if out.textColor == nil { out.textColor = base.textColor }
        if out.errorColor == nil { out.errorColor = base.errorColor }
        if out.placeholderColor == nil { out.placeholderColor = base.placeholderColor }
        if out.backgroundColor == nil { out.backgroundColor = base.backgroundColor }
        if out.borderColor == nil { out.borderColor = base.borderColor }
        if out.borderRadius == nil { out.borderRadius = base.borderRadius }
        if out.borderWidth == nil { out.borderWidth = base.borderWidth }
        if out.fontFamily == nil { out.fontFamily = base.fontFamily }
        if out.inputHeight == nil { out.inputHeight = base.inputHeight }
        if out.fontScale == nil { out.fontScale = base.fontScale }
        if out.gap == nil { out.gap = base.gap }
        if out.placeholderTextSizeAdjust == nil { out.placeholderTextSizeAdjust = base.placeholderTextSizeAdjust }
        if out.errorTextSizeAdjust == nil { out.errorTextSizeAdjust = base.errorTextSizeAdjust }
        if out.errorMessageSpacing == nil { out.errorMessageSpacing = base.errorMessageSpacing }
        if out.brandIconMode == nil { out.brandIconMode = base.brandIconMode }
        return out
    }
}

internal extension UIColor {
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "#%02X%02X%02X%02X",
            Int(round(alpha * 255)),
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}
