import Foundation

/// Runs the merchant callback for a tapped message action. Client-core decides what is shown.
package enum PaymentMessageActions {
    package static let eventName = "customMessageElementClicked"

    /// Consumes internal events even after the owner releases its configuration.
    @discardableResult
    package static func dispatch(configuration: PaymentSheet.Configuration?, type: String, payload: [String: Any]) -> Bool {
        guard type == eventName else { return false }
        /* The key is `id_index`: the message's random id, then the action's index in it. */
        guard payload["type"] as? String == "action",
            let parts = (payload["key"] as? String)?.split(separator: "_"),
            parts.count == 2, let index = Int(parts[1])
        else { return true }
        let message = configuration?.paymentMethodsConfig?
            .flatMap { [$0.message] + ($0.paymentMethodTypes ?? []).map(\.message) }
            .first { $0?.id == String(parts[0]) }
        if let elements = message??.value?.elements, elements.indices.contains(index) {
            elements[index].onTap()
        }
        return true
    }
}
