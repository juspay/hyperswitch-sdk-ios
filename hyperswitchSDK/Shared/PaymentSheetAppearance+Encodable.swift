//
//  PaymentSheetAppearance+Encodable.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 09/10/25.
//
//

import UIKit

/// Light/dark scheme keys for the `{ light, dark }` color schema.
private enum SchemeKey: String, CodingKey {
    case light, dark
}

private extension KeyedEncodingContainer where Key == SchemeKey {
    mutating func encodeThemed<NestedKey: CodingKey>(
        keyedBy: NestedKey.Type,
        _ body: (_ container: inout KeyedEncodingContainer<NestedKey>, _ style: UIUserInterfaceStyle) throws -> Void
    ) throws {
        var light = nestedContainer(keyedBy: NestedKey.self, forKey: .light)
        try body(&light, .light)
        var dark = nestedContainer(keyedBy: NestedKey.self, forKey: .dark)
        try body(&dark, .dark)
    }
}

// MARK: - Colors -> { light: {...}, dark: {...} }

extension PaymentSheet.Appearance.Colors: Encodable {
    private enum ColorKeys: String, CodingKey {
        case primary, background, componentBackground, componentBorder, componentDivider
        case componentText, primaryText, secondaryText, placeholderText, icon, error
        case loaderBackground, loaderForeground, overlay
        case selectedComponentBackground, selectedComponentBorder, selectedComponentDivider
        case selectedComponentText, selectedComponentBorderWidth
    }

    public func encode(to encoder: Encoder) throws {
        var root = encoder.container(keyedBy: SchemeKey.self)
        try root.encodeThemed(keyedBy: ColorKeys.self) { c, style in
            try c.encodeIfPresent(primary?.hex(for: style), forKey: .primary)
            try c.encodeIfPresent(background?.hex(for: style), forKey: .background)
            try c.encodeIfPresent(componentBackground?.hex(for: style), forKey: .componentBackground)
            try c.encodeIfPresent(componentBorder?.hex(for: style), forKey: .componentBorder)
            try c.encodeIfPresent(componentDivider?.hex(for: style), forKey: .componentDivider)
            try c.encodeIfPresent(componentText?.hex(for: style), forKey: .componentText)
            try c.encodeIfPresent(primaryText?.hex(for: style), forKey: .primaryText)
            try c.encodeIfPresent(secondaryText?.hex(for: style), forKey: .secondaryText)
            try c.encodeIfPresent(placeholderText?.hex(for: style), forKey: .placeholderText)
            try c.encodeIfPresent(icon?.hex(for: style), forKey: .icon)
            try c.encodeIfPresent(error?.hex(for: style), forKey: .error)
            try c.encodeIfPresent(loaderBackground?.hex(for: style), forKey: .loaderBackground)
            try c.encodeIfPresent(loaderForeground?.hex(for: style), forKey: .loaderForeground)
            try c.encodeIfPresent(overlay?.hex(for: style), forKey: .overlay)
            try c.encodeIfPresent(selectedComponentBackground?.hex(for: style), forKey: .selectedComponentBackground)
            try c.encodeIfPresent(selectedComponentBorder?.hex(for: style), forKey: .selectedComponentBorder)
            try c.encodeIfPresent(selectedComponentDivider?.hex(for: style), forKey: .selectedComponentDivider)
            try c.encodeIfPresent(selectedComponentText?.hex(for: style), forKey: .selectedComponentText)
            try c.encodeIfPresent(selectedComponentBorderWidth, forKey: .selectedComponentBorderWidth)
        }
    }
}

// MARK: - Font -> { family, scale, *TextSizeAdjust }

extension PaymentSheet.Appearance.Font: Encodable {
    private enum Keys: String, CodingKey {
        case family, scale
        case headingTextSizeAdjust, subHeadingTextSizeAdjust, placeholderTextSizeAdjust
        case buttonTextSizeAdjust, errorTextSizeAdjust, linkTextSizeAdjust
        case modalTextSizeAdjust, cardTextSizeAdjust
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encodeIfPresent(family ?? base?.familyName, forKey: .family)
        try c.encodeIfPresent(scale, forKey: .scale)
        try c.encodeIfPresent(headingTextSizeAdjust, forKey: .headingTextSizeAdjust)
        try c.encodeIfPresent(subHeadingTextSizeAdjust, forKey: .subHeadingTextSizeAdjust)
        try c.encodeIfPresent(placeholderTextSizeAdjust, forKey: .placeholderTextSizeAdjust)
        try c.encodeIfPresent(buttonTextSizeAdjust, forKey: .buttonTextSizeAdjust)
        try c.encodeIfPresent(errorTextSizeAdjust, forKey: .errorTextSizeAdjust)
        try c.encodeIfPresent(linkTextSizeAdjust, forKey: .linkTextSizeAdjust)
        try c.encodeIfPresent(modalTextSizeAdjust, forKey: .modalTextSizeAdjust)
        try c.encodeIfPresent(cardTextSizeAdjust, forKey: .cardTextSizeAdjust)
    }
}

// MARK: - Shadow -> { color, opacity, blurRadius, offset: {x, y}, intensity }

extension PaymentSheet.Appearance.Shadow: Encodable {
    private enum Keys: String, CodingKey {
        case color, opacity, blurRadius, offset, intensity
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        // FIXME: Shadow color is not theme-split in the RN.
        try c.encodeIfPresent(color?.hex(for: .light), forKey: .color)
        try c.encodeIfPresent(opacity, forKey: .opacity)
        try c.encodeIfPresent(blurRadius, forKey: .blurRadius)
        try c.encodeIfPresent(offset, forKey: .offset)
        try c.encodeIfPresent(intensity, forKey: .intensity)
    }
}

// MARK: - PrimaryButton -> { colors: {light, dark}, shapes, height }

extension PaymentSheet.Appearance.PrimaryButton: Encodable {
    private enum Keys: String, CodingKey {
        case colors, shapes, height
    }
    private enum ColorKeys: String, CodingKey {
        case background, text, border
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        var colorsRoot = c.nestedContainer(keyedBy: SchemeKey.self, forKey: .colors)
        try colorsRoot.encodeThemed(keyedBy: ColorKeys.self) { cc, style in
            try cc.encodeIfPresent(background?.hex(for: style), forKey: .background)
            try cc.encodeIfPresent(text?.hex(for: style), forKey: .text)
            try cc.encodeIfPresent(border?.hex(for: style), forKey: .border)
        }
        try c.encode(shapes, forKey: .shapes)
        try c.encodeIfPresent(height, forKey: .height)
    }
}

// MARK: - Logo -> { borderRadius, colors: {light, dark}, checkedIconForSelection }

extension PaymentSheet.Appearance.Logo: Encodable {
    private enum Keys: String, CodingKey {
        case borderRadius, colors, checkedIconForSelection
    }
    private enum ColorKeys: String, CodingKey {
        case backgroundColor, selected, unselected
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encodeIfPresent(borderRadius, forKey: .borderRadius)
        var colorsRoot = c.nestedContainer(keyedBy: SchemeKey.self, forKey: .colors)
        try colorsRoot.encodeThemed(keyedBy: ColorKeys.self) { cc, style in
            try cc.encodeIfPresent(backgroundColor?.hex(for: style), forKey: .backgroundColor)
            try cc.encodeIfPresent(selected?.hex(for: style), forKey: .selected)
            try cc.encodeIfPresent(unselected?.hex(for: style), forKey: .unselected)
        }
        try c.encodeIfPresent(checkedIconForSelection, forKey: .checkedIconForSelection)
    }
}

// MARK: - CheckedIcon -> { colors: {light, dark}, size, bottom, right }

extension PaymentSheet.Appearance.CheckedIcon: Encodable {
    private enum Keys: String, CodingKey {
        case colors, size, bottom, right
    }
    private enum ColorKeys: String, CodingKey {
        case color, stroke
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        var colorsRoot = c.nestedContainer(keyedBy: SchemeKey.self, forKey: .colors)
        try colorsRoot.encodeThemed(keyedBy: ColorKeys.self) { cc, style in
            try cc.encodeIfPresent(color?.hex(for: style), forKey: .color)
            try cc.encodeIfPresent(stroke?.hex(for: style), forKey: .stroke)
        }
        try c.encodeIfPresent(size, forKey: .size)
        try c.encodeIfPresent(bottom, forKey: .bottom)
        try c.encodeIfPresent(right, forKey: .right)
    }
}
