import Foundation
import UIKit

extension PaymentSheet.Configuration {
    /// Typed content retains callbacks locally; serialization uses callback-free wire models.
    public struct PaymentMethodMessage {
        public let value: MessageContent?
        public let displayMode: MessageDisplayMode
        public let elementStyles: MessageElementStyles?

        public init(
            value: MessageContent? = nil,
            displayMode: MessageDisplayMode? = nil,
            elementStyles: MessageElementStyles? = nil
        ) {
            self.value = value
            self.displayMode = displayMode ?? (value == nil ? .defaultSdkMessage : .customMessage)
            self.elementStyles = elementStyles
        }
    }
}
