import Foundation
import UIKit

/* Only these value models enter JSONEncoder. Native closures stay in the typed content
   retained by the sheet/widget that owns the corresponding React root. */
enum PaymentMessageWire {
    typealias Configuration = PaymentSheet.Configuration

    struct Style: Encodable {
        let color: String?
        let fontSize: Double?
        let fontWeight: Configuration.FontWeight?
        let fontStyle: Configuration.FontStyle?
        let textDecoration: Configuration.TextDecoration?

        init(_ style: Configuration.MessageElementStyle) {
            color = style.color?.hex()
            if let size = style.fontSize, !size.isFinite || size < 0 {
                NSLog("[Hyperswitch] Message fontSize must be finite and nonnegative; ignoring it.")
                fontSize = nil
            } else {
                fontSize = style.fontSize.map(Double.init)
            }
            fontWeight = style.fontWeight
            fontStyle = style.fontStyle
            textDecoration = style.textDecoration
        }
    }

    struct Styles: Encodable {
        let action: Style?
        init(_ styles: Configuration.MessageElementStyles) {
            action = styles.action.map(Style.init)
        }
    }

    struct Action: Encodable {
        let key: String
        let label: String
        let style: Style?
    }
    struct Elements: Encodable {
        let action: [Action]
    }

    struct Message: Encodable {
        let displayMode: Configuration.MessageDisplayMode
        let value: String?
        let elementStyles: Styles?
        let elements: Elements?

        init(_ message: Configuration.PaymentMethodMessage) {
            displayMode = message.displayMode
            elementStyles = message.elementStyles.map(Styles.init)
            var text = ""
            var actions: [Action] = []
            for part in message.value?.parts ?? [] {
                switch part {
                case .text(let literal): text += literal
                case .element(let element):
                    text += "{{\(element.key)}}"
                    guard !actions.contains(where: { $0.key == element.key }) else { continue }
                    actions.append(Action(
                        key: element.key, label: element.label, style: element.style.map(Style.init)
                    ))
                }
            }
            value = message.value == nil ? nil : text
            elements = actions.isEmpty ? nil : Elements(action: actions)
        }
    }

    struct MethodType: Encodable {
        let paymentMethodType: String
        let message: Message?
        init(_ config: Configuration.PaymentMethodTypeConfig) {
            paymentMethodType = config.paymentMethodType.rawValue
            message = config.message.map(Message.init)
        }
    }

    struct Method: Encodable {
        let paymentMethod: String
        let message: Message?
        let paymentMethodTypes: [MethodType]?
        init(_ config: Configuration.PaymentMethodConfig) {
            paymentMethod = config.paymentMethod.rawValue
            message = config.message.map(Message.init)
            paymentMethodTypes = config.paymentMethodTypes?.map(MethodType.init)
        }
    }
}
