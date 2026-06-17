//
//  Extensions.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 05/09/24.
//

import Foundation
import UIKit

internal extension UIColor {
    /// Returns the hex string (#RRGGBB or #RRGGBBAA if alpha < 1) for the color,
    /// optionally resolved for a specific interface style.
    func hex(for style: UIUserInterfaceStyle? = nil) -> String? {
        let color = style.map { resolvedColor(with: UITraitCollection(userInterfaceStyle: $0)) } ?? self

        guard
            let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
            let cgColorInRGB = color.cgColor.converted(to: sRGB, intent: .defaultIntent, options: nil),
            let comps = cgColorInRGB.components
        else { return nil }

        let r = comps.count > 0 ? comps[0] : 0
        let g = comps.count > 1 ? comps[1] : 0
        let b = comps.count > 2 ? comps[2] : 0
        let a = color.cgColor.alpha

        var hex = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255))
        )
        if a < 1 { hex += String(format: "%02lX", lroundf(Float(a * 255))) }
        return hex
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
