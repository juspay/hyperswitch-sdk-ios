import Foundation
import UIKit

extension PaymentSheet.Configuration {
    /// Immutable action definition; the callback never enters the encoded configuration.
    public struct MessageElement {
        package let key: String
        package let label: String
        package let style: MessageElementStyle?
        package let onClick: () -> Void

        private init(label: String, style: MessageElementStyle?, onClick: @escaping () -> Void) {
            key = "element_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
            self.label = label
            self.style = style
            self.onClick = onClick
        }

        public static func action(
            label: String,
            style: MessageElementStyle? = nil,
            onClick: @escaping () -> Void
        ) -> MessageElement {
            MessageElement(label: label, style: style, onClick: onClick)
        }
    }
}
