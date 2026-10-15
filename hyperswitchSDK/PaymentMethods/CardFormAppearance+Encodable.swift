//
//  CardFormAppearance+Encodable.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 22/09/26.
//

import UIKit

/// As the bundle reads an appearance, which is as the payment sheet's is written: colours
/// under `light` and `dark`, everything else plainly. `PaymentSheetAppearance+Encodable`
/// does the same for the payment sheet; the two are apart so that neither SDK's look
/// depends on the other's.

/// Light/dark scheme keys for the `{ light, dark }` color schema.
private enum SchemeKey: String, CodingKey {
    case light, dark
}

// MARK: - Appearance -> { colors: {light, dark}, shapes, font, labels }

extension CardFormAppearance: Encodable {
    private enum Keys: String, CodingKey {
        case colors, shapes, font, labels
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)

        if colors != nil || darkColors != nil {
            var schemes = c.nestedContainer(keyedBy: SchemeKey.self, forKey: .colors)
            if let colors = colors {
                try schemes.encode(Themed(colors, .light), forKey: .light)
            }
            /// A `UIColor` that changes with the interface style answers the dark one itself,
            /// so `colors` stands in for `darkColors` until an app says otherwise.
            if let dark = darkColors ?? colors {
                try schemes.encode(Themed(dark, .dark), forKey: .dark)
            }
        }

        try c.encodeIfPresent(shapes, forKey: .shapes)
        try c.encodeIfPresent(font, forKey: .font)
        try c.encodeIfPresent(labels?.rawValue, forKey: .labels)
    }

    /// One set of colours as one interface style sees them.
    private struct Themed: Encodable {
        private enum Keys: String, CodingKey {
            case primary, background, componentBackground, componentBorder
            case componentText, placeholderText, error
        }

        let colors: Colors
        let style: UIUserInterfaceStyle

        init(_ colors: Colors, _ style: UIUserInterfaceStyle) {
            self.colors = colors
            self.style = style
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: Keys.self)
            try c.encodeIfPresent(colors.primary?.hex(for: style), forKey: .primary)
            try c.encodeIfPresent(colors.background?.hex(for: style), forKey: .background)
            try c.encodeIfPresent(colors.componentBackground?.hex(for: style), forKey: .componentBackground)
            try c.encodeIfPresent(colors.componentBorder?.hex(for: style), forKey: .componentBorder)
            try c.encodeIfPresent(colors.componentText?.hex(for: style), forKey: .componentText)
            try c.encodeIfPresent(colors.placeholderText?.hex(for: style), forKey: .placeholderText)
            try c.encodeIfPresent(colors.error?.hex(for: style), forKey: .error)
        }
    }
}

// MARK: - Shapes -> { borderRadius, borderWidth, inputHeight, gap }

extension CardFormAppearance.Shapes: Encodable {
    private enum Keys: String, CodingKey {
        case borderRadius, borderWidth, inputHeight, gap
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encodeIfPresent(borderRadius, forKey: .borderRadius)
        try c.encodeIfPresent(borderWidth, forKey: .borderWidth)
        try c.encodeIfPresent(inputHeight, forKey: .inputHeight)
        try c.encodeIfPresent(gap, forKey: .gap)
    }
}

// MARK: - Font -> { family, scale, *TextSizeAdjust }

extension CardFormAppearance.Font: Encodable {
    private enum Keys: String, CodingKey {
        case family, scale, placeholderTextSizeAdjust, errorTextSizeAdjust
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encodeIfPresent(family, forKey: .family)
        try c.encodeIfPresent(scale, forKey: .scale)
        try c.encodeIfPresent(placeholderTextSizeAdjust, forKey: .placeholderTextSizeAdjust)
        try c.encodeIfPresent(errorTextSizeAdjust, forKey: .errorTextSizeAdjust)
    }
}

// MARK: - Field style -> { container, input }, as React Native spells a style

extension CardFieldStyle: Encodable {
    private enum Keys: String, CodingKey {
        case container, input
    }
    private enum ContainerKeys: String, CodingKey {
        case backgroundColor, borderColor, borderWidth, borderRadius, height
    }
    private enum InputKeys: String, CodingKey {
        case color, fontSize, fontFamily
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)

        /// A style holds one value per key, so a colour is asked for as it is now rather
        /// than for both schemes.
        var container = c.nestedContainer(keyedBy: ContainerKeys.self, forKey: .container)
        try container.encodeIfPresent(backgroundColor?.hex(), forKey: .backgroundColor)
        try container.encodeIfPresent(borderColor?.hex(), forKey: .borderColor)
        try container.encodeIfPresent(borderWidth, forKey: .borderWidth)
        try container.encodeIfPresent(borderRadius, forKey: .borderRadius)
        try container.encodeIfPresent(height, forKey: .height)

        var input = c.nestedContainer(keyedBy: InputKeys.self, forKey: .input)
        try input.encodeIfPresent(textColor?.hex(), forKey: .color)
        try input.encodeIfPresent(fontSize, forKey: .fontSize)
        try input.encodeIfPresent(fontFamily, forKey: .fontFamily)
    }
}
