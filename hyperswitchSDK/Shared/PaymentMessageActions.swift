import Foundation

/// Runs the merchant callback for a tapped message action. Client-core decides what is shown.
package enum PaymentMessageActions {
    package static let eventName = "customMessageElementClicked"

    /// Consumes internal events even after the owner releases its configuration.
    @discardableResult
    package static func dispatch(configuration: PaymentSheet.Configuration?, type: String, payload: [String: Any]) -> Bool {
        guard type == eventName else { return false }
        /* `index` counts actions across all messages in this order, the order they were encoded. */
        let elements = configuration?.paymentMethodsConfig?
            .flatMap { [$0.message] + ($0.paymentMethodTypes ?? []).map(\.message) }
            .flatMap { $0?.value?.elements ?? [] } ?? []
        if let index = payload["index"] as? Int, elements.indices.contains(index) {
            elements[index].onTap()
        }
        return true
    }
}
