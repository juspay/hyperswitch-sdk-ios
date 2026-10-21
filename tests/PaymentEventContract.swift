import Foundation

@main
enum PaymentEventContract {
    static func main() {
        let fixtures: [(PaymentEventType, [String: Any])] = [
            (.cardDetailsChange, ["bin": NSNull(), "extendedBin": NSNull(), "last4": NSNull(), "brand": NSNull(), "expiryMonth": NSNull(), "expiryYear": NSNull(), "formattedExpiry": NSNull(), "isCardNumberComplete": false, "isCardNumberValid": false, "isExpiryComplete": false, "isExpiryValid": false, "isCvcComplete": false]),
            (.paymentMethodChange, ["paymentMethod": "card", "paymentMethodType": "credit", "isSavedPaymentMethod": true, "isOneClickWallet": false]),
            (.formStatusChange, ["status": "COMPLETE"]),
            (.billingDetailsChange, ["country": "US", "state": NSNull(), "postalCode": NSNull()]),
            (.cvcStatusChange, ["cvcStatus": ["isCvcEmpty": false, "isCvcComplete": true]]),
        ]
        let hub = PaymentEventHub()
        var changes: [PaymentEvent] = []
        var lifecycle: [String] = []
        hub.onChange = { changes.append($0) }
        hub.dispatch(type: "ready", payload: [:])
        hub.onReady = { lifecycle.append("ready") }
        hub.onFocus = { lifecycle.append("focus") }
        hub.onBlur = { lifecycle.append("blur") }
        hub.dispatch(type: "focus", payload: [:])
        hub.dispatch(type: "blur", payload: [:])
        precondition(lifecycle == ["ready", "focus", "blur"])
        precondition(changes.isEmpty)
        for (name, wirePayload) in fixtures {
            hub.dispatch(type: name.rawValue, payload: wirePayload)
            let event = changes.last!
            precondition(event.eventName == name)
            precondition(NSDictionary(dictionary: event.payload.toDictionary()).isEqual(to: wirePayload))
            switch event.payload {
            case .cardDetailsChange(let data): precondition(data.bin == nil)
            case .paymentMethodChange(let data): precondition(data.isSavedPaymentMethod && data.paymentMethod == "card")
            case .formStatusChange(let data): precondition(data.status == .complete)
            case .billingDetailsChange(let data): precondition(data.postalCode == nil)
            case .cvcStatusChange(let data): precondition(data.cvcStatus.isCvcComplete)
            }
            hub.dispatch(type: name.rawValue, payload: [:])
        }
        var invalidCard = fixtures[0].1
        invalidCard["bin"] = 424242
        hub.dispatch(type: "cardDetailsChange", payload: invalidCard)
        var invalidSaved = fixtures[1].1
        invalidSaved["isSavedPaymentMethod"] = "true"
        hub.dispatch(type: "paymentMethodChange", payload: invalidSaved)
        invalidSaved["isSavedPaymentMethod"] = NSNumber(value: 1)
        hub.dispatch(type: "paymentMethodChange", payload: invalidSaved)
        hub.dispatch(type: "formStatusChange", payload: ["status": "unknown"])
        hub.dispatch(type: "cvcStatusChange", payload: ["isCvcEmpty": true, "isCvcComplete": false])
        hub.dispatch(type: "PAYMENT_METHOD_STATUS", payload: fixtures[1].1)
        precondition(changes.count == fixtures.count)
        print("Swift merchant payload, serialization, validation and lifecycle checks passed")
    }
}
