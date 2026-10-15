//
//  CardFormAppearance.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 22/09/26.
//

import Foundation
import UIKit

/// How a card form looks: colours, shapes and type, for every field of the form. The same
/// members and the same names on Android, so one description of a design serves both, and
/// the names the payment sheet's appearance uses, so one SDK reads like the other.
///
/// A field you would rather draw yourself is better asked for with `CardFieldOptions.unstyled`,
/// which leaves you the text and nothing around it.
public struct CardFormAppearance {

    /// Anything a `UIColor` is: a colour, a pattern, or one that answers differently in
    /// light and dark. A colour that changes with the interface style is asked for both,
    /// so an app that has one set of dynamic colours needs nothing else here.
    public struct Colors {
        /// The cursor, and the border of the field being typed into.
        public var primary: UIColor?
        /// Behind the form, where a field does not cover it.
        public var background: UIColor?
        /// Behind each field.
        public var componentBackground: UIColor?
        /// The border of each field.
        public var componentBorder: UIColor?
        /// What the customer types.
        public var componentText: UIColor?
        /// The hint shown in an empty field.
        public var placeholderText: UIColor?
        /// Error text, and the border of a field that is not valid.
        public var error: UIColor?

        public init(
            primary: UIColor? = nil,
            background: UIColor? = nil,
            componentBackground: UIColor? = nil,
            componentBorder: UIColor? = nil,
            componentText: UIColor? = nil,
            placeholderText: UIColor? = nil,
            error: UIColor? = nil
        ) {
            self.primary = primary
            self.background = background
            self.componentBackground = componentBackground
            self.componentBorder = componentBorder
            self.componentText = componentText
            self.placeholderText = placeholderText
            self.error = error
        }
    }

    public struct Shapes {
        /// The corner radius of every field.
        public var borderRadius: CGFloat?
        public var borderWidth: CGFloat?
        /// How tall a field is. Its view is this tall plus room for a label and an error.
        public var inputHeight: CGFloat?
        /// Between a field and what the form draws under it.
        public var gap: CGFloat?

        public init(
            borderRadius: CGFloat? = nil,
            borderWidth: CGFloat? = nil,
            inputHeight: CGFloat? = nil,
            gap: CGFloat? = nil
        ) {
            self.borderRadius = borderRadius
            self.borderWidth = borderWidth
            self.inputHeight = inputHeight
            self.gap = gap
        }
    }

    public struct Font {
        /// A font already in your app; the form draws with the system font without one.
        public var family: String?
        /// Multiplies every text size the form draws.
        public var scale: CGFloat?
        /// Points added to the placeholder's size.
        public var placeholderTextSizeAdjust: CGFloat?
        /// Points added to the error message's size.
        public var errorTextSizeAdjust: CGFloat?

        public init(
            family: String? = nil,
            scale: CGFloat? = nil,
            placeholderTextSizeAdjust: CGFloat? = nil,
            errorTextSizeAdjust: CGFloat? = nil
        ) {
            self.family = family
            self.scale = scale
            self.placeholderTextSizeAdjust = placeholderTextSizeAdjust
            self.errorTextSizeAdjust = errorTextSizeAdjust
        }
    }

    public var colors: Colors?
    /// Only for a dark scheme that is not what `colors` answers in the dark. Dynamic
    /// `UIColor`s already carry both, so most apps leave this alone.
    public var darkColors: Colors?
    public var shapes: Shapes?
    public var font: Font?
    /// Where each field's label goes. A field's own `CardFieldOptions.labelBehavior` wins.
    public var labels: CardFieldOptions.LabelBehavior?

    public init(
        colors: Colors? = nil,
        darkColors: Colors? = nil,
        shapes: Shapes? = nil,
        font: Font? = nil,
        labels: CardFieldOptions.LabelBehavior? = nil
    ) {
        self.colors = colors
        self.darkColors = darkColors
        self.shapes = shapes
        self.font = font
        self.labels = labels
    }
}

/// One field drawn differently from the rest of the form. What is left out is the form's.
/// Colours are asked for as they are now, so a field styled this way does not follow a
/// change of interface style while it is open; `CardFormAppearance` does.
public struct CardFieldStyle {
    public var textColor: UIColor?
    public var fontSize: CGFloat?
    public var fontFamily: String?
    public var backgroundColor: UIColor?
    public var borderColor: UIColor?
    public var borderWidth: CGFloat?
    public var borderRadius: CGFloat?
    /// How tall the field is, without its label or its error message.
    public var height: CGFloat?

    public init(
        textColor: UIColor? = nil,
        fontSize: CGFloat? = nil,
        fontFamily: String? = nil,
        backgroundColor: UIColor? = nil,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat? = nil,
        borderRadius: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.textColor = textColor
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.borderRadius = borderRadius
        self.height = height
    }
}
