//
//  PaymentManagementConfiguration.swift
//  hyperswitch
//
//  Created by Shivam Nan on 30/09/24.
//

import Foundation
import UIKit

// MARK: - Payment Methods Management Configuration

/// Configuration for Payment Method Management Sheet
public struct PMMConfiguration: DictionaryConverter {
    /// Describes the appearance of PaymentSheet
    public var appearance = PMMAppearance.default
}

/// Describes the appearance of Payment Method Management Sheet
public struct PMMAppearance: Equatable, DictionaryConverter {
    /// The default appearance for PaymentSheet
    public static let `default` = PMMAppearance()
    
    /// Creates a `PaymentSheet.Appearance` with default values
    public init() {}
    
    /// Describes the appearance of fonts in PaymentSheet
    public var font: Font = Font()
    
    /// Describes the colors in PaymentSheet
    public var colors: Colors = Colors()
    
    /// The corner radius used for buttons, inputs, tabs in PaymentSheet
    /// - Note: The behavior of this property is consistent with the behavior of corner radius on `CALayer`
    public var cornerRadius: CGFloat?
    
    /// The border used for inputs and tabs in PaymentSheet
    /// - Note: The behavior of this property is consistent with the behavior of border width on `CALayer`
    public var borderWidth: CGFloat?
    
    /// The shadow used for inputs and tabs in PaymentSheet
    /// - Note: Set this to `.disabled` to disable shadows
    public var shadow: Shadow?
    
    public var theme: Theme?
    
    public enum Theme {
        case `default`
        case light
        case dark
        case minimal
        case flatMinimal
        
        var themeLabel: String {
            switch self {
            case .`default`:
                return "Default"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            case .minimal:
                return "Minimal"
            case .flatMinimal:
                return "FlatMinimal"
            }
        }
    }
    
    // MARK: Fonts
    /// Describes the appearance of fonts in PaymentSheet
    public struct Font: Equatable, DictionaryConverter {
        
        /// Creates a `PaymentSheet.Appearance.Font` with default values
        public init() {}
        
        /// The scale factor for all font sizes in PaymentSheet.
        /// Font sizes are multiplied by this value before being displayed. For example, setting this to 1.2 increases the size of all text by 20%.
        /// - Note: This value must be greater than 0. The default value is 1.0.
        /// - Note: This is used in conjunction with the Dynamic Type accessibility text size.
        public var sizeScaleFactor: CGFloat?
        
        /// The font family of this font is used throughout PaymentSheet. PaymentSheet uses this font at multiple weights (e.g., regular, medium, semibold) if they exist.
        /// - Note: The size and weight of the font is ignored. To adjust font sizes, see `sizeScaleFactor`.
        public var base: UIFont?
        
        /// The size adjustment for all heading texts in PaymentSheet
        /// Font sizes of all headings will be increased by this value from their respective default size
        public var headingTextSizeAdjust: CGFloat?
        
        /// The size for all sub heading texts in PaymentSheet
        /// Font sizes of all sub headings will be increased by this value from their respective default size
        public var subHeadingTextSizeAdjust: CGFloat?
        
        /// The size for all placeholder texts in PaymentSheet
        /// Font sizes of all placeholder texts will be increased by this value from their respective default size
        public var placeholderTextSizeAdjust: CGFloat?
        
        /// The size for all button texts in PaymentSheet
        /// Font sizes of all button texts will be increased by this value from their respective default size
        public var buttonTextSizeAdjust: CGFloat?
        
        /// The size for all error texts in PaymentSheet
        /// Font sizes of all error texts will be increased by this value from their respective default size
        public var errorTextSizeAdjust: CGFloat?
        
        /// The size for all link texts in PaymentSheet
        /// Font sizes of all link texts will be increased by this value from their respective default size
        public var linkTextSizeAdjust: CGFloat?
        
        /// The size for all modal texts in PaymentSheet
        /// Font sizes of all modal texts will be increased by this value from their respective default size
        public var modalTextSizeAdjust: CGFloat?
        
        /// The size for all card texts in PaymentSheet
        /// Font sizes of all card texts will be increased by this value from their respective default size
        public var cardTextSizeAdjust: CGFloat?
    }
    
    // MARK: Colors
    /// Describes the colors in PaymentSheet
    public struct Colors: Equatable, DictionaryConverter {
        
        /// Creates a `PaymentSheet.Appearance.Colors` with default values
        public init() {}
        
        /// The primary color used throughout PaymentSheet
        public var primary: UIColor?
        
        /// The color used for the background of PaymentSheet
        public var background: UIColor?
        
        /// The color used for the background of inputs, tabs, and other components
        public var componentBackground: UIColor?
        
        /// The border color used for inputs, tabs, and other components
        public var componentBorder: UIColor?
        
        /// The color of the divider lines used inside inputs, tabs, and other components
        public var componentDivider: UIColor?
        
        /// The default text color used in PaymentSheet, appearing over the background color
        public var text: UIColor?
        
        /// The color used for text of secondary importance. For example, this color is used for the label above input fields
        public var textSecondary: UIColor?
        
        /// The color of text appearing over `componentBackground`
        public var componentText: UIColor?
        
        /// The color used for input placeholder text
        public var componentPlaceholderText: UIColor?
        
        /// The color used for icons in PaymentSheet, such as the close or back icons
        public var icon: UIColor?
        
        /// The color used to indicate errors or destructive actions in PaymentSheet
        public var danger: UIColor?
        
        /// The color used to indicate Loader Background Color
        public var loaderBackground: UIColor?
        
        /// The color used to indicate Loader Foreground Color
        public var loaderForeground: UIColor?
    }
    
    // MARK: Shadow
    /// Represents a shadow in PaymentSheet
    public struct Shadow: Equatable, DictionaryConverter {
        
        /// A pre-configured `Shadow` in the disabled or off state
        public static var disabled: Shadow?
        
        /// Color of the shadow
        /// - Note: The behavior of this property is consistent with `CALayer.shadowColor`
        public var color: UIColor?
        
        /// Opacity or alpha of the shadow
        /// - Note: The behavior of this property is consistent with `CALayer.shadowOpacity`
        public var opacity: CGFloat?
        
        /// Offset of the shadow
        /// - Note: The behavior of this property is consistent with `CALayer.shadowOffset`
        public var offset: CGSize?
        
        /// Radius of the shadow
        /// - Note: The behavior of this property is consistent with `CALayer.shadowRadius`
        public var radius: CGFloat?
        
        /// intensity of the shadow
        /// - Note: The behavior of this property is consistent with `CALayer.shadowIntensity`
        public var intensity: CGFloat?
        
        /// Creates a `PaymentSheet.Appearance.Shadow` with default values
        public init() {}
        
        /// Creates a `Shadow` with the specified parameters
        /// - Parameters:
        ///   - color: Color of the shadow
        ///   - opacity: Opacity or opacity of the shadow
        ///   - offset: Offset of the shadow
        ///   - radius: Radius of the shadow
        ///   - intensity: Intensity of the shadow
        public init(color: UIColor?, opacity: CGFloat?, offset: CGSize?, radius: CGFloat?, intensity: CGFloat?) {
            self.color = color
            self.opacity = opacity
            self.offset = offset
            self.radius = radius
            self.intensity = intensity
        }
    }
    
}
