import Foundation

/// Runs the merchant callback for a tapped message action. Client-core decides what is shown.
package enum PaymentMessageActions {
    package static let eventName = "customMessageElementClicked"

    /// Consumes internal events even after the owner releases its configuration.
    @discardableResult
    package static func dispatch(configuration: PaymentSheet.Configuration?, type: String, payload: [String: Any]) -> Bool {
        guard type == eventName else { return false }
        guard let key = payload["key"] as? String else { return true }
        let element = configuration?.paymentMethodsConfig?.flatMap(\.elements).first { $0.key == key }
        if payload["type"] as? String == "action" { element?.onClick() }
        return true
    }
}
