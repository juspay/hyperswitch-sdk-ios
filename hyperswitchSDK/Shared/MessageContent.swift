import Foundation
import UIKit

extension PaymentSheet.Configuration {
    /// Typed interpolation retains action objects without generating or parsing wire placeholders.
    public struct MessageContent: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
        package enum Part {
            case text(String)
            case element(MessageElement)
        }

        package let parts: [Part]

        package var elements: [MessageElement] {
            parts.compactMap { part in
                if case .element(let element) = part { return element }
                return nil
            }
        }

        public init(_ text: String) { parts = [.text(text)] }
        public init(stringLiteral value: String) { self.init(value) }
        public init(stringInterpolation: StringInterpolation) {
            parts = stringInterpolation.parts
        }

        public struct StringInterpolation: StringInterpolationProtocol {
            fileprivate var parts: [Part] = []

            public init(literalCapacity: Int, interpolationCount: Int) {
                parts.reserveCapacity(interpolationCount * 2 + 1)
            }

            public mutating func appendLiteral(_ literal: String) { appendText(literal) }
            public mutating func appendInterpolation(_ element: MessageElement) { parts.append(.element(element)) }
            public mutating func appendInterpolation(_ text: String) { appendText(text) }
            /// Numbers and other plain values are interpolated as text.
            public mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T) {
                appendText(value.description)
            }

            private mutating func appendText(_ text: String) {
                if !text.isEmpty { parts.append(.text(text)) }
            }
        }
    }
}
