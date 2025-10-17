//
//  PaymentSession+UIKit.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation
import React

extension PaymentSession {
    
    private static var hasResponded: Bool = false
    internal static var headlessCompletion: ((PaymentSessionHandler) -> Void)?
    private static var completion: ((PaymentResult) -> Void)?
    
    private static func safeResolve(_ callback: @escaping RCTResponseSenderBlock,_ result: [Any],_ resultHandler: @escaping (PaymentResult) -> Void){
        guard !PaymentSession.hasResponded else {
            print("Warning: Attempt to resolve callback more than once")
            resultHandler(.failed(error: NSError(domain: "Not Initialised", code: 0, userInfo: ["message" : "An error has occurred."])))
            return
        }
        PaymentSession.hasResponded = true
        callback(result)
    }
    
    public func presentPaymentSheet(viewController: UIViewController, completion: @escaping (PaymentSheetResult) -> ()){
        presentPaymentSheet(viewController: viewController, configuration: PaymentSheet.Configuration(), completion: completion)
    }
    
    public func presentPaymentSheet(viewController: UIViewController, configuration: PaymentSheet.Configuration, completion: @escaping (PaymentSheetResult) -> ()){
        PaymentSession.isPresented = true
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: PaymentSession.paymentIntentClientSecret ?? "", configuration: configuration)
        paymentSheet.present(from: viewController, completion: completion)
    }
    
    // for external frameworks
    public func presentPaymentSheetWithParams(viewController: UIViewController, params: [String: Any], completion: @escaping (PaymentSheetResult) -> ()){
        PaymentSession.isPresented = true
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: PaymentSession.paymentIntentClientSecret ?? "", configuration: PaymentSheet.Configuration())
        paymentSheet.presentWithParams(from: viewController, props: params, completion: completion)
    }
    
    public func getCustomerSavedPaymentMethods(_ func_: @escaping (PaymentSessionHandler) -> Void) {
        PaymentSession.hasResponded = false
        PaymentSession.isPresented = false
        PaymentSession.headlessCompletion = func_
        RNHeadlessManager.sharedInstance.reinvalidateBridge()
        let hyperParams = HyperParams.getHyperParams()   
        let props: [String: Any] = [
            "clientSecret": PaymentSession.paymentIntentClientSecret as Any,
            "publishableKey": APIClient.shared.publishableKey as Any,
            "hyperParams": hyperParams,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customLogUrl": APIClient.shared.customLogUrl as Any,
            "customParams": APIClient.shared.customParams as Any
        ]
        let _ = RNHeadlessManager.sharedInstance.viewForModule("HyperHeadless", initialProperties: ["props": props])
    }
    
    internal static func getPaymentSession(getPaymentMethodData: NSDictionary, getPaymentMethodData2: NSDictionary, getPaymentMethodDataArray: NSArray, callback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            PaymentSession.hasResponded = false
            let handler = PaymentSessionHandler(
                getCustomerDefaultSavedPaymentMethodData: {
                    return parseGetPaymentMethodData(getPaymentMethodData)
                },
                getCustomerLastUsedPaymentMethodData: {
                    return parseGetPaymentMethodData(getPaymentMethodData2)
                },
                getCustomerSavedPaymentMethodData: {
                    var array = [PaymentMethod]()
                    for i in 0..<getPaymentMethodDataArray.count {
                        if let map = getPaymentMethodDataArray[i] as? NSDictionary {
                            array.append(parseGetPaymentMethodData(map))
                        }
                    }
                    return array
                },
                confirmWithCustomerDefaultPaymentMethod: { cvc, resultHandler in
                    if let paymentToken = getPaymentMethodData["payment_token"] as? String {
                        self.completion = resultHandler
                        var map = [String: Any]()
                        map["paymentToken"] = paymentToken
                        map["cvc"] = cvc
                        self.safeResolve(callback, [map], resultHandler)
                    }
                },
                confirmWithCustomerLastUsedPaymentMethod: { cvc, resultHandler in
                    if let paymentToken = getPaymentMethodData2["payment_token"] as? String {
                        self.completion = resultHandler
                        var map = [String: Any]()
                        map["paymentToken"] = paymentToken
                        map["cvc"] = cvc
                        self.safeResolve(callback, [map], resultHandler)
                    }
                },
                confirmWithCustomerPaymentToken: { paymentToken, cvc, resultHandler in
                    self.completion = resultHandler
                    var map = [String: Any]()
                    map["paymentToken"] = paymentToken
                    map["cvc"] = cvc
                    self.safeResolve(callback, [map], resultHandler)
                }
            )
            self.headlessCompletion?(handler)
        }
    }
    
    
    internal static func exitHeadless(rnMessage: String) {
        DispatchQueue.main.async {
            if let data = rnMessage.data(using: .utf8) {
                do {
                    if let message = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                        guard let status = message["status"] else {
                            completion?(.failed(error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."])))
                            return
                        }
                        switch status {
                        case "cancelled":
                            completion?(.canceled(data: status))
                        case "failed", "requires_payment_method":
                            let domain = (message["code"]) != "" ? message["code"] : "UNKNOWN_ERROR"
                            let errorMessage = message["message"] ?? "An error has occurred."
                            let userInfo = ["message": errorMessage]
                            completion?(.failed(error: NSError(domain: domain ?? "UNKNOWN_ERROR", code: 0, userInfo: userInfo)))
                        default:
                            completion?(.completed(data: status))
                        }
                    } else {
                        let domain = "UNKNOWN_ERROR"
                        let errorMessage = "An error has occurred."
                        let userInfo = ["message": errorMessage]
                        self.completion?(.failed(error: NSError(domain: domain , code: 0, userInfo: userInfo)))
                    }
                } catch {
                    let domain = "UNKNOWN_ERROR"
                    let errorMessage = "An error has occurred."
                    let userInfo = ["message": errorMessage]
                    self.completion?(.failed(error: NSError(domain: domain , code: 0, userInfo: userInfo)))
                }
            }
        }
    }
    
    private static func parseGetPaymentMethodData(_ readableMap: NSDictionary) -> PaymentMethod {
        let paymentMethodStr = readableMap["payment_method_str"] as? String
        
        if paymentMethodStr != nil {
            let cardMap = readableMap["card"] as? [String: Any]
            
            var card: Card? = nil
            if let cardData = cardMap {
                card = Card(
                    scheme: cardData["scheme"] as? String ?? "",
                    issuerCountry: cardData["issuer_country"] as? String ?? "",
                    last4Digits: cardData["last4_digits"] as? String ?? "",
                    expiryMonth: cardData["expiry_month"] as? String ?? "",
                    expiryYear: cardData["expiry_year"] as? String ?? "",
                    cardToken: cardData["card_token"] as? String,
                    cardHolderName: cardData["card_holder_name"] as? String ?? "",
                    cardFingerprint: cardData["card_fingerprint"] as? String,
                    nickName: cardData["nick_name"] as? String ?? "",
                    cardNetwork: cardData["card_network"] as? String ?? "",
                    cardIsin: cardData["card_isin"] as? String ?? "",
                    cardIssuer: cardData["card_issuer"] as? String ?? "",
                    cardType: cardData["card_type"] as? String ?? "",
                    savedToLocker: cardData["saved_to_locker"] as? Bool ?? false
                )
            }
            
            let paymentExperienceArray = readableMap["payment_experience"] as? NSArray
            var paymentExperienceList: [String] = []
            if let array = paymentExperienceArray {
                for i in 0..<array.count {
                    if let item = array[i] as? String {
                        paymentExperienceList.append(item)
                    }
                }
            }
            
            return PaymentMethodType(
                paymentToken: readableMap["payment_token"] as? String ?? "",
                paymentMethodId: readableMap["payment_method_id"] as? String ?? "",
                customerId: readableMap["customer_id"] as? String ?? "",
                paymentMethod: readableMap["payment_method_str"] as? String ?? "",
                paymentMethodType: readableMap["payment_method_type"] as? String ?? "",
                paymentMethodIssuer: readableMap["payment_method_issuer"] as? String ?? "",
                paymentMethodIssuerCode: readableMap["payment_method_issuer_code"] as? String,
                recurringEnabled: readableMap["recurring_enabled"] as? Bool ?? false,
                installmentPaymentEnabled: readableMap["installment_payment_enabled"] as? Bool ?? false,
                paymentExperience: paymentExperienceList,
                card: card,
                metadata: readableMap["metadata"] as? String,
                created: readableMap["created"] as? String ?? "",
                bank: readableMap["bank"] as? String,
                surchargeDetails: readableMap["surcharge_details"] as? String,
                requiresCvv: readableMap["requires_cvv"] as? Bool ?? false,
                lastUsedAt: readableMap["last_used_at"] as? String ?? "",
                defaultPaymentMethodSet: readableMap["default_payment_method_set"] as? Bool ?? false
            )
        } else {
            return PMError(
                code: readableMap["code"] as? String ?? "",
                message: readableMap["message"] as? String ?? ""
            )
        }
    }
}
