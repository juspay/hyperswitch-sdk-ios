//
//  PaymentSheetApperance.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 09/11/23.
//

import UIKit

public extension PaymentSheet {

    /// Describes the appearance of PaymentSheet.
    struct Appearance: Encodable {

        /// Creates a `PaymentSheet.Appearance` with default values
        public init() {}

        /// The visual theme. Note: only `.default` auto-switches with the system
        /// light/dark setting; a named theme pins the scheme.
        public var theme: Theme?

        /// Describes the colors in PaymentSheet (resolved per light/dark scheme)
        public var colors: Colors = Colors()

        /// The corner radius / border / shadow / spacing used across PaymentSheet
        public var shapes: Shapes = Shapes() // FIXME: to be removed.

        /// Describes the appearance of fonts in PaymentSheet
        public var font: Font = Font()

        /// Describes the appearance of the primary button (e.g., the "Pay" button)
        public var primaryButton: PrimaryButton = PrimaryButton()

        /// Describes the appearance of payment-method logos / selection icons
        public var logo: Logo?

        public enum Theme: String, Encodable {
            case `default` = "Default"
            case light = "Light"
            case dark = "Dark"
            case minimal = "Minimal"
            case flatMinimal = "FlatMinimal"
            case brutal = "Brutal"
            case glass = "Glass"
            case skeu = "Skeu"
            case clay = "Clay"
            case charcoal = "Charcoal"
            case soft = "Soft"
        }

        // MARK: Colors

        /// Describes the colors in PaymentSheet.
        /// Each color may be a plain `UIColor` (applied to both schemes) or a dynamic
        /// `UIColor` (resolved differently for light and dark).
        public struct Colors {

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

            /// The color of text appearing over `componentBackground`
            public var componentText: UIColor?

            /// The primary/default text color used in PaymentSheet
            public var primaryText: UIColor?

            /// The color used for text of secondary importance (e.g. labels above inputs)
            public var secondaryText: UIColor?

            /// The color used for input placeholder text
            public var placeholderText: UIColor?

            /// The color used for icons in PaymentSheet, such as the close or back icons
            public var icon: UIColor?

            /// The color used to indicate errors or destructive actions in PaymentSheet
            public var error: UIColor?

            /// The color used for the loader background
            public var loaderBackground: UIColor?

            /// The color used for the loader foreground
            public var loaderForeground: UIColor?

            /// The color used for the modal/scrim overlay
            public var overlay: UIColor?

            /// The background color of a selected component
            public var selectedComponentBackground: UIColor?

            /// The border color of a selected component
            public var selectedComponentBorder: UIColor?

            /// The border width of a selected component
            public var selectedComponentBorderWidth: CGFloat?

            /// The divider color of a selected component
            public var selectedComponentDivider: UIColor?

            /// The text color of a selected component
            public var selectedComponentText: UIColor?
        }

        // MARK: Shapes

        /// Corner radius, border, shadow and spacing for inputs/tabs/components.
        public struct Shapes: Encodable {  // FIXME: remove this struct.

            /// Creates a `PaymentSheet.Appearance.Shapes` with default values
            public init() {}

            /// The corner radius used for buttons, inputs, tabs in PaymentSheet
            public var borderRadius: CGFloat?

            /// The border width used for inputs and tabs in PaymentSheet
            public var borderWidth: CGFloat?

            /// The shadow used for inputs and tabs in PaymentSheet
            public var shadow: Shadow?

            /// The height of inputs in points
            public var inputHeight: CGFloat?

            /// The spacing between components in points
            public var gap: CGFloat?
        }

        // MARK: Shadow

        /// Represents a shadow in PaymentSheet
        public struct Shadow {

            /// Creates a `PaymentSheet.Appearance.Shadow` with default values
            public init() {}

            /// A pre-configured `Shadow` in the disabled or off state
            public static var disabled: Shadow?

            /// Color of the shadow
            public var color: UIColor?

            /// Opacity or alpha of the shadow
            public var opacity: CGFloat?

            /// Offset of the shadow
            public var offset: Offset?

            /// Blur radius of the shadow
            public var blurRadius: CGFloat?

            /// Intensity of the shadow
            public var intensity: CGFloat?
        }

        /// A 2D offset (used by `Shadow.offset`)
        public struct Offset: Encodable {

            /// Creates an `Offset` with default values
            public init() {}

            public init(x: CGFloat, y: CGFloat) {
                self.x = x
                self.y = y
            }

            public var x: CGFloat?
            public var y: CGFloat?
        }

        // MARK: Fonts

        /// Describes the appearance of fonts in PaymentSheet
        public struct Font {

            /// Creates a `PaymentSheet.Appearance.Font` with default values
            public init() {}

            /// The font used throughout PaymentSheet.
            public var base: UIFont?

            /// Explicit font-family override. Takes precedence over `base`
            public var family: String?

            /// The scale factor for all font sizes in PaymentSheet.
            /// - Note: The default value is 1.0.
            public var scale: CGFloat?

            /// Size adjustment for all heading texts
            public var headingTextSizeAdjust: CGFloat?

            /// Size adjustment for all sub-heading texts
            public var subHeadingTextSizeAdjust: CGFloat?

            /// Size adjustment for all placeholder texts
            public var placeholderTextSizeAdjust: CGFloat?

            /// Size adjustment for all button texts
            public var buttonTextSizeAdjust: CGFloat?

            /// Size adjustment for all error texts
            public var errorTextSizeAdjust: CGFloat?

            /// Size adjustment for all link texts
            public var linkTextSizeAdjust: CGFloat?

            /// Size adjustment for all modal texts
            public var modalTextSizeAdjust: CGFloat?

            /// Size adjustment for all card texts
            public var cardTextSizeAdjust: CGFloat?
        }

        // MARK: Primary Button

        /// Describes the appearance of the primary button (e.g., the "Pay" button).
        public struct PrimaryButton {

            /// Creates a `PaymentSheet.Appearance.PrimaryButton` with default values
            public init() {}

            /// The background color of the primary button
            public var background: UIColor?

            /// The text color of the primary button
            public var text: UIColor?

            /// The border color of the primary button
            public var border: UIColor?

            /// The corner radius / border width / shadow of the primary button
            public var shapes: Shapes = Shapes()

            /// The height of the primary button in points
            public var height: CGFloat?
        }

        // MARK: Logo

        /// Describes the appearance of payment-method logos and the selection check icon.
        public struct Logo {

            /// Creates a `PaymentSheet.Appearance.Logo` with default values
            public init() {}

            /// The corner radius of the logo container
            public var borderRadius: CGFloat?

            /// The background color behind the logo (defaults to transparent on the RN side)
            public var backgroundColor: UIColor?

            /// The tint used when the payment method is selected
            public var selected: UIColor?

            /// The tint used when the payment method is not selected
            public var unselected: UIColor?

            /// The check icon shown for the selected payment method
            public var checkedIconForSelection: CheckedIcon?
        }

        /// The check icon shown for a selected payment method.
        public struct CheckedIcon {

            /// Creates a `PaymentSheet.Appearance.CheckedIcon` with default values
            public init() {}

            /// The fill color of the check icon
            public var color: UIColor?

            /// The stroke color of the check icon
            public var stroke: UIColor?

            /// The size of the check icon in points
            public var size: CGFloat?

            /// The bottom offset of the check icon in points
            public var bottom: CGFloat?

            /// The right offset of the check icon in points
            public var right: CGFloat?
        }
    }
}
