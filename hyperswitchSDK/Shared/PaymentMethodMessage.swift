import Foundation
import UIKit

extension PaymentSheet.Configuration {
    /// Typed content retains callbacks locally; only labels and styles are encoded.
    public struct PaymentMethodMessage: Encodable {
        /// Random, so interpolated text cannot guess an action key (`{{id_index}}`).
        package let id = String((0..<8).map { _ in "abcdefghijklmnopqrstuvwxyz0123456789".randomElement()! })
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
