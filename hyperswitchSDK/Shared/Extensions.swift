//
//  Extensions.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 05/09/24.
//

import Foundation

public extension UIColor {
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
