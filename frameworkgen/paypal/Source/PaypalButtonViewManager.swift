import PayPal

@objc(PaypalButton)
class PaypalButtonViewManager: RCTViewManager {

    override func view() -> PaypalButtonView {
        return PaypalButtonView()
    }

    @objc override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
