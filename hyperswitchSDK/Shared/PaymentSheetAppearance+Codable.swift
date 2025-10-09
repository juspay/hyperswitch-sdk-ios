//
//  PaymentSheetAppearance+Codable.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 09/10/25.
//

// MARK: - Codable Conformance
import UIKit

extension PaymentSheet.Appearance.Colors: Codable {
    enum CodingKeys: String, CodingKey {
        case primary, background, componentBackground, componentBorder
        case componentDivider, text, textSecondary, componentText
        case componentPlaceholderText, icon, danger
        case loaderBackground, loaderForeground
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(primary.map { CodableColor($0) }, forKey: .primary)
        try c.encodeIfPresent(background.map { CodableColor($0) }, forKey: .background)
        try c.encodeIfPresent(componentBackground.map { CodableColor($0) }, forKey: .componentBackground)
        try c.encodeIfPresent(componentBorder.map { CodableColor($0) }, forKey: .componentBorder)
        try c.encodeIfPresent(componentDivider.map { CodableColor($0) }, forKey: .componentDivider)
        try c.encodeIfPresent(text.map { CodableColor($0) }, forKey: .text)
        try c.encodeIfPresent(textSecondary.map { CodableColor($0) }, forKey: .textSecondary)
        try c.encodeIfPresent(componentText.map { CodableColor($0) }, forKey: .componentText)
        try c.encodeIfPresent(componentPlaceholderText.map { CodableColor($0) }, forKey: .componentPlaceholderText)
        try c.encodeIfPresent(icon.map { CodableColor($0) }, forKey: .icon)
        try c.encodeIfPresent(danger.map { CodableColor($0) }, forKey: .danger)
        try c.encodeIfPresent(loaderBackground.map { CodableColor($0) }, forKey: .loaderBackground)
        try c.encodeIfPresent(loaderForeground.map { CodableColor($0) }, forKey: .loaderForeground)
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        primary = try c.decodeIfPresent(CodableColor.self, forKey: .primary)?.uiColor
        background = try c.decodeIfPresent(CodableColor.self, forKey: .background)?.uiColor
        componentBackground = try c.decodeIfPresent(CodableColor.self, forKey: .componentBackground)?.uiColor
        componentBorder = try c.decodeIfPresent(CodableColor.self, forKey: .componentBorder)?.uiColor
        componentDivider = try c.decodeIfPresent(CodableColor.self, forKey: .componentDivider)?.uiColor
        text = try c.decodeIfPresent(CodableColor.self, forKey: .text)?.uiColor
        textSecondary = try c.decodeIfPresent(CodableColor.self, forKey: .textSecondary)?.uiColor
        componentText = try c.decodeIfPresent(CodableColor.self, forKey: .componentText)?.uiColor
        componentPlaceholderText = try c.decodeIfPresent(CodableColor.self, forKey: .componentPlaceholderText)?.uiColor
        icon = try c.decodeIfPresent(CodableColor.self, forKey: .icon)?.uiColor
        danger = try c.decodeIfPresent(CodableColor.self, forKey: .danger)?.uiColor
        loaderBackground = try c.decodeIfPresent(CodableColor.self, forKey: .loaderBackground)?.uiColor
        loaderForeground = try c.decodeIfPresent(CodableColor.self, forKey: .loaderForeground)?.uiColor
    }
}



extension PaymentSheet.Appearance.Font: Codable {
    enum CodingKeys: String, CodingKey {
        case sizeScaleFactor, base, headingTextSizeAdjust, subHeadingTextSizeAdjust
        case placeholderTextSizeAdjust, buttonTextSizeAdjust, errorTextSizeAdjust
        case linkTextSizeAdjust, modalTextSizeAdjust, cardTextSizeAdjust, family
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(sizeScaleFactor, forKey: .sizeScaleFactor)
        try c.encodeIfPresent(base.map { CodableFont($0) }, forKey: .base)
        try c.encodeIfPresent(headingTextSizeAdjust, forKey: .headingTextSizeAdjust)
        try c.encodeIfPresent(subHeadingTextSizeAdjust, forKey: .subHeadingTextSizeAdjust)
        try c.encodeIfPresent(placeholderTextSizeAdjust, forKey: .placeholderTextSizeAdjust)
        try c.encodeIfPresent(buttonTextSizeAdjust, forKey: .buttonTextSizeAdjust)
        try c.encodeIfPresent(errorTextSizeAdjust, forKey: .errorTextSizeAdjust)
        try c.encodeIfPresent(linkTextSizeAdjust, forKey: .linkTextSizeAdjust)
        try c.encodeIfPresent(modalTextSizeAdjust, forKey: .modalTextSizeAdjust)
        try c.encodeIfPresent(cardTextSizeAdjust, forKey: .cardTextSizeAdjust)
        try c.encodeIfPresent(family, forKey: .family)
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sizeScaleFactor = try c.decodeIfPresent(CGFloat.self, forKey: .sizeScaleFactor)
        base = try c.decodeIfPresent(CodableFont.self, forKey: .base)?.uiFont
        headingTextSizeAdjust = try c.decodeIfPresent(CGFloat.self, forKey: .headingTextSizeAdjust)
        subHeadingTextSizeAdjust = try c.decodeIfPresent(CGFloat.self, forKey: .subHeadingTextSizeAdjust)
        placeholderTextSizeAdjust = try c.decodeIfPresent(CGFloat.self, forKey: .placeholderTextSizeAdjust)
        buttonTextSizeAdjust = try c.decodeIfPresent(CGFloat.self, forKey: .buttonTextSizeAdjust)
        errorTextSizeAdjust = try c.decodeIfPresent(CGFloat.self, forKey: .errorTextSizeAdjust)
        linkTextSizeAdjust = try c.decodeIfPresent(CGFloat.self, forKey: .linkTextSizeAdjust)
        modalTextSizeAdjust = try c.decodeIfPresent(CGFloat.self, forKey: .modalTextSizeAdjust)
        cardTextSizeAdjust = try c.decodeIfPresent(CGFloat.self, forKey: .cardTextSizeAdjust)
        family = try c.decodeIfPresent(String.self, forKey: .family)
    }
}



extension PaymentSheet.Appearance.PrimaryButton: Codable {
    enum CodingKeys: String, CodingKey {
        case backgroundColor, textColor, successBackgroundColor, successTextColor
        case cornerRadius, borderColor, borderWidth, font, shadow
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(backgroundColor.map { CodableColor($0) }, forKey: .backgroundColor)
        try c.encodeIfPresent(textColor.map { CodableColor($0) }, forKey: .textColor)
        try c.encodeIfPresent(successBackgroundColor.map { CodableColor($0) }, forKey: .successBackgroundColor)
        try c.encodeIfPresent(successTextColor.map { CodableColor($0) }, forKey: .successTextColor)
        try c.encodeIfPresent(cornerRadius, forKey: .cornerRadius)
        try c.encodeIfPresent(borderColor.map { CodableColor($0) }, forKey: .borderColor)
        try c.encodeIfPresent(borderWidth, forKey: .borderWidth)
        try c.encodeIfPresent(font.map { CodableFont($0) }, forKey: .font)
        try c.encodeIfPresent(shadow, forKey: .shadow)
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        backgroundColor = try c.decodeIfPresent(CodableColor.self, forKey: .backgroundColor)?.uiColor
        textColor = try c.decodeIfPresent(CodableColor.self, forKey: .textColor)?.uiColor
        successBackgroundColor = try c.decodeIfPresent(CodableColor.self, forKey: .successBackgroundColor)?.uiColor
        successTextColor = try c.decodeIfPresent(CodableColor.self, forKey: .successTextColor)?.uiColor
        cornerRadius = try c.decodeIfPresent(CGFloat.self, forKey: .cornerRadius)
        borderColor = try c.decodeIfPresent(CodableColor.self, forKey: .borderColor)?.uiColor
        borderWidth = try c.decodeIfPresent(CGFloat.self, forKey: .borderWidth)
        font = try c.decodeIfPresent(CodableFont.self, forKey: .font)?.uiFont
        shadow = try c.decodeIfPresent(PaymentSheet.Appearance.Shadow.self, forKey: .shadow)
    }
}



extension PaymentSheet.Appearance.Shadow: Codable {
    enum CodingKeys: String, CodingKey {
        case color, opacity, offset, radius, intensity
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(color.map { CodableColor($0) }, forKey: .color)
        try c.encodeIfPresent(opacity, forKey: .opacity)
        try c.encodeIfPresent(offset, forKey: .offset)
        try c.encodeIfPresent(radius, forKey: .radius)
        try c.encodeIfPresent(intensity, forKey: .intensity)
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        color = try c.decodeIfPresent(CodableColor.self, forKey: .color)?.uiColor
        opacity = try c.decodeIfPresent(CGFloat.self, forKey: .opacity)
        offset = try c.decodeIfPresent(CGSize.self, forKey: .offset)
        radius = try c.decodeIfPresent(CGFloat.self, forKey: .radius)
        intensity = try c.decodeIfPresent(CGFloat.self, forKey: .intensity)
    }
}



extension PaymentSheet.Appearance: Codable {
    enum CodingKeys: String, CodingKey {
        case font, colors, primaryButton, cornerRadius, borderWidth, shadow, theme
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(font, forKey: .font)
        try c.encodeIfPresent(colors, forKey: .colors)
        try c.encodeIfPresent(primaryButton, forKey: .primaryButton)
        try c.encodeIfPresent(cornerRadius, forKey: .cornerRadius)
        try c.encodeIfPresent(borderWidth, forKey: .borderWidth)
        try c.encodeIfPresent(shadow, forKey: .shadow)
        try c.encodeIfPresent(theme, forKey: .theme)
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        font = try c.decodeIfPresent(PaymentSheet.Appearance.Font.self, forKey: .font) ?? Font()
        colors = try c.decodeIfPresent(PaymentSheet.Appearance.Colors.self, forKey: .colors) ?? Colors()
        primaryButton = try c.decodeIfPresent(PaymentSheet.Appearance.PrimaryButton.self, forKey: .primaryButton) ?? PrimaryButton()
        cornerRadius = try c.decodeIfPresent(CGFloat.self, forKey: .cornerRadius)
        borderWidth = try c.decodeIfPresent(CGFloat.self, forKey: .borderWidth)
        shadow = try c.decodeIfPresent(PaymentSheet.Appearance.Shadow.self, forKey: .shadow)
        theme = try c.decodeIfPresent(PaymentSheet.Appearance.Theme.self, forKey: .theme)
    }
}
