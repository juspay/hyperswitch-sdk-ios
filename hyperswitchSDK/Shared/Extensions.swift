//
//  Extensions.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 05/09/24.
//

import Foundation
import UIKit

internal extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor(dynamicProvider: { (traitCollection) in
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return light
            case .dark:
                return dark
            @unknown default:
                return light
            }
        })
    }
}

internal extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}

internal extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Encoding", code: 0)
        }
        return dict
    }
}

internal extension UIColor {
    /// Convert UIColor to hex string (#RRGGBB or #RRGGBBAA if alpha < 1)
    var hexString: String? {
        guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
            let cgColorInRGB = cgColor.converted(
                to: sRGB,
                intent: .defaultIntent,
                options: nil
            ),
            let comps = cgColorInRGB.components
        else {
            return nil
        }

        let r = comps.count > 0 ? comps[0] : 0
        let g = comps.count > 1 ? comps[1] : 0
        let b = comps.count > 2 ? comps[2] : 0
        let a = cgColor.alpha

        var hex = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
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
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
                blue: CGFloat(rgb & 0x0000FF) / 255,
                alpha: 1.0
            )
        case 8:
            self.init(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255,
                alpha: CGFloat(rgb & 0x000000FF) / 255
            )
        default:
            return nil
        }
    }
}
