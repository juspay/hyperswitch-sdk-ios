//
//  PaymentRequestData.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 18/05/26.
//

public struct PaymentRequestData: Codable {
    var paymentMethodType: PaymentMethodType
}

public enum PaymentMethodType: String, Codable {
    case applePay = "apple_pay"
    case payPal = "paypal"
}
