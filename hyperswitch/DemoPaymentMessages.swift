import Hyperswitch
import UIKit

enum DemoPaymentMessages {
    static func make() -> [PaymentSheet.Configuration.PaymentMethodConfig] {
        typealias Configuration = PaymentSheet.Configuration
        let terms = Configuration.MessageElement.action(
            label: "Terms & Conditions",
            style: Configuration.MessageElementStyle(textDecoration: .underline),
            onClick: { print("[HyperswitchDemo] Terms & Conditions tapped") }
        )
        let privacy = Configuration.MessageElement.action(
            label: "Privacy Policy",
            style: Configuration.MessageElementStyle(
                color: UIColor(red: 5.0 / 255.0, green: 112.0 / 255.0, blue: 222.0 / 255.0, alpha: 1),
                textDecoration: .underline
            ),
            onClick: { print("[HyperswitchDemo] Privacy Policy tapped") }
        )
        let message = Configuration.PaymentMethodMessage(
            value: "Please review the \(terms) and \(privacy).\nPlease review before paying."
        )
        return [
            Configuration.PaymentMethodConfig(paymentMethod: .card, message: message),
            Configuration.PaymentMethodConfig(paymentMethod: .wallet, message: message),
            Configuration.PaymentMethodConfig(paymentMethod: .bankDebit, message: message),
        ]
    }
}
