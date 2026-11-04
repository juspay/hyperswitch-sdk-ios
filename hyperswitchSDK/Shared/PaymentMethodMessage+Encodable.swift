import UIKit

/* Callbacks stay in the typed content retained by the owning sheet/widget; only text,
   labels and styles are encoded. */

// MARK: - PaymentMethodMessage -> { displayMode, elementStyles, value: [segment] }

extension PaymentSheet.Configuration.PaymentMethodMessage {
    private enum Keys: String, CodingKey {
        case displayMode, value, elementStyles
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encodeIfPresent(displayMode, forKey: .displayMode)
        try c.encodeIfPresent(elementStyles, forKey: .elementStyles)
        try c.encodeIfPresent(value?.parts, forKey: .value)
    }
}

// MARK: - MessageContent.Part -> { text } or { text, tappable, style }

extension PaymentSheet.Configuration.MessageContent.Part: Encodable {
    private enum Keys: String, CodingKey {
        case text, tappable, style
    }

    package func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case .text(let text):
            try c.encode(text, forKey: .text)
        case .element(let element):
            try c.encode(element.label, forKey: .text)
            try c.encode(true, forKey: .tappable)
            try c.encodeIfPresent(element.style, forKey: .style)
        }
    }
}

// MARK: - MessageElementStyle -> { color, fontSize, fontWeight, fontStyle, textDecoration }

extension PaymentSheet.Configuration.MessageElementStyle: Encodable {
    private enum Keys: String, CodingKey {
        case color, fontSize, fontWeight, fontStyle, textDecoration
    }

    /// A font's weight maps to the nearest CSS-style weight.
    private static let weights: [(UIFont.Weight, String)] = [
        (.ultraLight, "100"), (.thin, "200"), (.light, "300"), (.regular, "400"), (.medium, "500"),
        (.semibold, "600"), (.bold, "700"), (.heavy, "800"), (.black, "900"),
    ]

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encodeIfPresent(color?.hex(), forKey: .color)
        if let font {
            let descriptor = font.fontDescriptor
            let traits = descriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
            let isBold = descriptor.symbolicTraits.contains(.traitBold)
            let weight = traits?[.weight] as? CGFloat ?? (isBold ? UIFont.Weight.bold : .regular).rawValue
            let nearest = Self.weights.min { abs($0.0.rawValue - weight) < abs($1.0.rawValue - weight) }
            try c.encode(Double(font.pointSize), forKey: .fontSize)
            try c.encodeIfPresent(nearest?.1, forKey: .fontWeight)
            try c.encode(descriptor.symbolicTraits.contains(.traitItalic) ? "italic" : "normal", forKey: .fontStyle)
        }
        try c.encodeIfPresent(textDecoration, forKey: .textDecoration)
    }
}
