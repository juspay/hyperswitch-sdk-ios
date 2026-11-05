import Foundation

/// Runs the merchant callback for a tapped message action. Client-core decides what is shown.
package enum PaymentMessageActions {
    /* `index` counts actions across all messages in this order, the order they were encoded. */
    package static func run(configuration: PaymentSheet.Configuration?, index: Int) {
        let elements = configuration?.paymentMethodsConfig?
            .flatMap { [$0.message] + ($0.paymentMethodTypes ?? []).map(\.message) }
            .flatMap { $0?.value?.elements ?? [] } ?? []
        if elements.indices.contains(index) {
            elements[index].onTap()
        }
    }
}
