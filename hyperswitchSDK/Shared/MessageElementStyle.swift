import Foundation
import UIKit

extension PaymentSheet.Configuration {
    public struct MessageElementStyle {
        public var color: UIColor?
        /// Size in points, before the SDK typography scale is applied.
        public var fontSize: CGFloat?
        public var fontWeight: FontWeight?
        public var fontStyle: FontStyle?
        public var textDecoration: TextDecoration?

        public init(
            color: UIColor? = nil,
            fontSize: CGFloat? = nil,
            fontWeight: FontWeight? = nil,
            fontStyle: FontStyle? = nil,
            textDecoration: TextDecoration? = nil
        ) {
            self.color = color
            self.fontSize = fontSize
            self.fontWeight = fontWeight
            self.fontStyle = fontStyle
            self.textDecoration = textDecoration
        }
    }

    public struct MessageElementStyles {
        public let action: MessageElementStyle?
        public init(action: MessageElementStyle? = nil) {
            self.action = action
        }
    }
}
