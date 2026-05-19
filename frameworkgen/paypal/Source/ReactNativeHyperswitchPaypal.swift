import PayPal

@objc(HyperswitchPaypal)
class ReactNativeHyperswitchPaypal: NSObject {

  private static let TAG = "HyperswitchPaypal"

  @objc
  static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc(launchPayPal:callback:)
  func launchPayPal(_ requestObj: String, callback: @escaping RCTResponseSenderBlock) {

    guard let data = requestObj.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      let error: [String: Any] = [
        "status": "failed",
        "error_message": "Failed to parse request JSON"
      ]
      callback([error])
      return
    }

    guard let clientId = json["clientId"] as? String else {
      let error: [String: Any] = [
        "status": "failed",
        "error_message": "Missing clientId"
      ]
      callback([error])
      return
    }

    guard let orderId = json["orderId"] as? String else {
      let error: [String: Any] = [
        "status": "failed",
        "error_message": "Missing orderId"
      ]
      callback([error])
      return
    }

    let environmentStr = json["environment"] as? String ?? "SANDBOX"
    let fundingSourceStr = json["fundingSource"] as? String ?? "PAYPAL"

    let environment: Environment = environmentStr == "PRODUCTION" ? .live : .sandbox

    let fundingSource: PayPalWebCheckoutFundingSource
    switch fundingSourceStr {
    case "PAY_LATER":
      fundingSource = .paylater
    case "PAYPAL_CREDIT":
      fundingSource = .paypalCredit
    default:
      fundingSource = .paypal
    }


    let config = CoreConfig(clientID: clientId, environment: environment)
    let payPalClient = PayPalWebCheckoutClient(config: config)
    let request = PayPalWebCheckoutRequest(orderID: orderId, fundingSource: fundingSource)

    DispatchQueue.main.async {
      payPalClient.start(request: request) { result in
        switch result {
        case .success(let paypalResult):
          let successMap: [String: Any] = [
            "status": "success",
            "orderId": paypalResult.orderID,
            "payerId": paypalResult.payerID
          ]
          callback([successMap])

        case .failure(let error):
          if PayPalError.isCheckoutCanceled(error) {
            let cancelMap: [String: Any] = [
              "status": "cancelled"
            ]
            callback([cancelMap])
          } else {
            let errorMap: [String: Any] = [
              "status": "failed",
              "error_message": error.localizedDescription
            ]
            callback([errorMap])
          }
        }
      }
    }
  }
}
