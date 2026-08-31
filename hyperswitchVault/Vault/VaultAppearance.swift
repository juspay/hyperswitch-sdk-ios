import UIKit

/// Per-scheme color overrides (light/dark), mirrors the JS `appearance` config.
public struct VaultColors {
    public var background: UIColor?
    public var border: UIColor?
    public var borderFocused: UIColor?
    public var text: UIColor?
    public var hint: UIColor?
    public var error: UIColor?

    public init(
        background: UIColor? = nil,
        border: UIColor? = nil,
        borderFocused: UIColor? = nil,
        text: UIColor? = nil,
        hint: UIColor? = nil,
        error: UIColor? = nil
    ) {
        self.background = background
        self.border = border
        self.borderFocused = borderFocused
        self.text = text
        self.hint = hint
        self.error = error
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = background { out["background"] = v.hexString }
        if let v = border { out["border"] = v.hexString }
        if let v = borderFocused { out["borderFocused"] = v.hexString }
        if let v = text { out["text"] = v.hexString }
        if let v = hint { out["hint"] = v.hexString }
        if let v = error { out["error"] = v.hexString }
        return out
    }
}

public struct VaultAppearanceColors {
    public var light: VaultColors?
    public var dark: VaultColors?

    public init(light: VaultColors? = nil, dark: VaultColors? = nil) {
        self.light = light
        self.dark = dark
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = light { out["light"] = v.dict }
        if let v = dark { out["dark"] = v.dict }
        return out
    }
}

public struct VaultShadow {
    public var color: UIColor?
    public var opacity: CGFloat?
    public var radius: CGFloat?
    public var offset: CGSize?
    public var elevation: CGFloat?

    public init(
        color: UIColor? = nil,
        opacity: CGFloat? = nil,
        radius: CGFloat? = nil,
        offset: CGSize? = nil,
        elevation: CGFloat? = nil
    ) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.offset = offset
        self.elevation = elevation
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = color { out["color"] = v.hexString }
        if let v = opacity { out["opacity"] = v }
        if let v = radius { out["radius"] = v }
        if let v = offset { out["offset"] = ["x": v.width, "y": v.height] }
        if let v = elevation { out["elevation"] = v }
        return out
    }
}

/// Mirrors the hyperswitch appearance config passed to the `hs-vault` RN app.
public struct VaultAppearance {
    public var colors: VaultAppearanceColors?
    public var radius: CGFloat?
    public var borderWidth: CGFloat?
    public var padding: CGFloat?
    public var fontSize: CGFloat?
    public var shadow: VaultShadow?

    public init(
        colors: VaultAppearanceColors? = nil,
        radius: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        padding: CGFloat? = nil,
        fontSize: CGFloat? = nil,
        shadow: VaultShadow? = nil
    ) {
        self.colors = colors
        self.radius = radius
        self.borderWidth = borderWidth
        self.padding = padding
        self.fontSize = fontSize
        self.shadow = shadow
    }

    internal var dict: [String: Any] {
        var out = [String: Any]()
        if let v = colors { out["colors"] = v.dict }
        if let v = radius { out["radius"] = v }
        if let v = borderWidth { out["borderWidth"] = v }
        if let v = padding { out["padding"] = v }
        if let v = fontSize { out["fontSize"] = v }
        if let v = shadow { out["shadow"] = v.dict }
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
