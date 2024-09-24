//
//  PaymentSession.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation

@frozen public enum PaymentResult {
    case completed(data: String)
    case canceled(data: String)
    case failed(error: Error)
}

public class PaymentSession {
    
    internal static var isPresented: Bool = false
    internal static var paymentIntentClientSecret: String?
    internal static var ephemeralKey: String?
    
    public init(publishableKey: String, customBackendUrl: String? = nil, customParams: [String : Any]? = nil, customLogUrl: String? = nil){
        APIClient.shared.publishableKey = publishableKey
        APIClient.shared.customBackendUrl = customBackendUrl
        APIClient.shared.customLogUrl = customLogUrl
        APIClient.shared.customParams = customParams
    }
    
    public func initPaymentSession(paymentIntentClientSecret: String){
        PaymentSession.paymentIntentClientSecret = paymentIntentClientSecret
    }
    
    public func initPaymentManagementSession(ephemeralKey: String){
        PaymentSession.ephemeralKey = ephemeralKey
    }
}
