import Foundation
import UIKit

extension PaymentSheet.Configuration {
    /// Typed interpolation retains action objects without generating or parsing wire placeholders.
    public struct MessageContent: ExpressibleByStringInterpolation, Encodable {
        /// Text and actions in display order; text segments have no `onTap`.
        package let segments: [MessageElement]

        public init(_ text: String) { segments = text.isEmpty ? [] : [MessageElement(label: text)] }
        public init(stringLiteral value: String) { self.init(value) }
        public init(stringInterpolation: StringInterpolation) {
            segments = stringInterpolation.segments
        }

        public func encode(to encoder: Encoder) throws {
            try segments.encode(to: encoder)
        }

        /// Runs the action at `index`, the segment's position as encoded, if it shows `text`.
        package func tap(at index: Int, text: String) {
            guard segments.indices.contains(index), segments[index].label == text else { return }
            segments[index].onTap?()
        }

        public struct StringInterpolation: StringInterpolationProtocol {
            fileprivate var segments: [MessageElement] = []

            public init(literalCapacity: Int, interpolationCount: Int) {}

            public mutating func appendLiteral(_ literal: String) { appendText(literal) }
            public mutating func appendInterpolation(_ element: MessageElement) { segments.append(element) }
            public mutating func appendInterpolation(_ text: String) { appendText(text) }
            /// Numbers and other plain values are interpolated as text.
            public mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T) {
                appendText(value.description)
            }

            private mutating func appendText(_ text: String) {
                if !text.isEmpty { segments.append(MessageElement(label: text)) }
            }
        }
    }
}
