import Foundation
import UIKit

extension PaymentSheet.Configuration {
    /// Typed content retains callbacks locally; only text and styles are encoded.
    public struct PaymentMethodMessage: Encodable {
        public let value: MessageContent?
        /// Unset fields of a payment method type's message come from its payment method's message.
        public let displayMode: MessageDisplayMode?
        public let elementStyles: MessageElementStyles?

        public init(
            value: MessageContent? = nil,
            displayMode: MessageDisplayMode? = nil,
            elementStyles: MessageElementStyles? = nil
        ) {
            self.value = value
            self.displayMode = displayMode
            self.elementStyles = elementStyles
        }
    }
}
