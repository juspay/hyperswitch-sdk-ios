import UIKit

// MARK: - CodableColor Wrapper
public struct CodableColor: Codable, Equatable {
    private let wrapped: UIColor   // internal storage

    public init(_ color: UIColor) {
        self.wrapped = color
    }

    // Accessor for UIKit API compatibility
    public var uiColor: UIColor { wrapped }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let hex = wrapped.hexString else {
            throw EncodingError.invalidValue(
                wrapped,
                EncodingError.Context(codingPath: container.codingPath,
                                      debugDescription: "Failed to encode UIColor to hex")
            )
        }
        try container.encode(hex)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        guard let decoded = UIColor(hexString: hex) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid hex string: \(hex)"
            )
        }
        self.wrapped = decoded
    }
}


// MARK: - UIColor Utilities
extension UIColor {
    /// Convert UIColor to hex string (#RRGGBB or #RRGGBBAA if alpha < 1)
    var hexString: String? {
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
              let cgColorInRGB = cgColor.converted(
                  to: sRGB,
                  intent: .defaultIntent,
                  options: nil
              ),
              let comps = cgColorInRGB.components else {
            return nil
        }

        let r = comps.count > 0 ? comps[0] : 0
        let g = comps.count > 1 ? comps[1] : 0
        let b = comps.count > 2 ? comps[2] : 0
        let a = cgColor.alpha

        var hex = String(format: "#%02lX%02lX%02lX",
                         lroundf(Float(r * 255)),
                         lroundf(Float(g * 255)),
                         lroundf(Float(b * 255)))
        if a < 1 {
            hex += String(format: "%02lX", lroundf(Float(a * 255)))
        }
        return hex
    }

    /// Initialize UIColor from hex string (#RRGGBB or #RRGGBBAA)
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }

        switch hex.count {
        case 6:
            self.init(red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
                      green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
                      blue: CGFloat(rgb & 0x0000FF) / 255,
                      alpha: 1.0)
        case 8:
            self.init(red: CGFloat((rgb & 0xFF000000) >> 24) / 255,
                      green: CGFloat((rgb & 0x00FF0000) >> 16) / 255,
                      blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255,
                      alpha: CGFloat(rgb & 0x000000FF) / 255)
        default:
            return nil
        }
    }
}


// MARK: - CodableFont Wrapper
public struct CodableFont: Codable, Equatable {
    private let wrapped: UIFont   // internal storage

    public init(_ font: UIFont) {
        self.wrapped = font
    }

    // Accessor for UIKit API compatibility
    public var uiFont: UIFont { wrapped }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrapped.fontName)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        guard let decodedFont = UIFont(name: name, size: .zero) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid font name: \(name)"
            )
        }
        self.wrapped = decodedFont
    }
}
