import Foundation

package struct PaymentEventListener {
    let onPaymentEvent: (PaymentEvent) -> Void
}
