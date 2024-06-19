//
//  PaymentSession.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import UIKit

@frozen public enum PaymentResult {
    case completed(data: String)
    case canceled(data: String)
    case failed(error: Error)
}

public class PaymentSession {
    
    static var viewController: UIViewController?
    static var clientSecret: String?
    public var completion: ((PaymentSessionHandler) -> Void)?
    var completion2: ((PaymentResult) -> Void)?
    static var shared: PaymentSession?
    
    public init() {}
    
    public convenience init(viewController: UIViewController?=nil, clientSecret: String) {
        self.init()
        
        PaymentSession.viewController = viewController
        PaymentSession.clientSecret = clientSecret
        PaymentSession.shared = self
        
    }
    
    public func getCustomerSavedPaymentMethods(_ func1: @escaping (PaymentSessionHandler) -> Void) {
        completion = func1
        RNViewManager.sharedInstance2.reinvalidateBridge()
        let _ = RNViewManager.sharedInstance2.viewForModule("dummy", initialProperties: [:])
    }
    
    public func getPaymentSession(getPaymentMethodData: NSDictionary, getPaymentMethodData2: NSDictionary, getPaymentMethodDataArray: NSArray, callback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            let handler = PaymentSessionHandler(
                getCustomerDefaultSavedPaymentMethodData: {
                    return self.parseGetPaymentMethodData(getPaymentMethodData)
                },
                getCustomerLastUsedPaymentMethodData: {
                    return self.parseGetPaymentMethodData(getPaymentMethodData2)
                },
                getCustomerSavedPaymentMethodData: {
                    var array = [PaymentMethod]()
                    for i in 0..<getPaymentMethodDataArray.count {
                        if let map = getPaymentMethodDataArray[i] as? NSDictionary {
                            array.append(self.parseGetPaymentMethodData(map))
                        }
                    }
                    return array
                },
                confirmWithCustomerDefaultPaymentMethod: { cvc, resultHandler in
                    if let map = getPaymentMethodData["_0"] as? NSDictionary,
                       let paymentToken = map["payment_token"] as? String {
                            self.completion2 = resultHandler
                            var map = [String: Any]()
                            map["paymentToken"] = paymentToken
                            map["cvc"] = cvc
                            callback([map])
                    }
                },
                confirmWithCustomerLastUsedPaymentMethod: { cvc, resultHandler in
                    if let map = getPaymentMethodData2["_0"] as? NSDictionary,
                       let paymentToken = map["payment_token"] as? String {
                            self.completion2 = resultHandler
                            var map = [String: Any]()
                            map["paymentToken"] = paymentToken
                            map["cvc"] = cvc
                            callback([map])
                    }
                },
                confirmWithCustomerPaymentToken: { paymentToken, cvc, resultHandler in
                        self.completion2 = resultHandler
                        var map = [String: Any]()
                        map["paymentToken"] = paymentToken
                        map["cvc"] = cvc
                        callback([map])
                }
            )
            self.completion?(handler)
        }
    }
    
    
    func exitHeadless(rnMessage: String) {
        DispatchQueue.main.async {
            if let data = rnMessage.data(using: .utf8) {
                do {
                    if let message = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                        guard let status = message["status"] else {
                            self.completion2?(.failed(error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."])))
                            return
                        }
                        switch status {
                        case "cancelled":
                            self.completion2?(.canceled(data: status))
                        case "failed", "requires_payment_method":
                            let domain = (message["code"]) != "" ? message["code"] : "UNKNOWN_ERROR"
                            let errorMessage = message["message"] ?? "An error has occurred."
                            let userInfo = ["message": errorMessage]
                            self.completion2?(.failed(error: NSError(domain: domain ?? "UNKNOWN_ERROR", code: 0, userInfo: userInfo)))
                        default:
                            self.completion2?(.completed(data: status))
                        }
                    } else {
                        let domain = "UNKNOWN_ERROR"
                        let errorMessage = "An error has occurred."
                        let userInfo = ["message": errorMessage]
                        self.completion2?(.failed(error: NSError(domain: domain , code: 0, userInfo: userInfo)))
                    }
                } catch {
                    let domain = "UNKNOWN_ERROR"
                    let errorMessage = "An error has occurred."
                    let userInfo = ["message": errorMessage]
                    self.completion2?(.failed(error: NSError(domain: domain , code: 0, userInfo: userInfo)))
                }
            }
        }
    }
    
    private func parseGetPaymentMethodData(_ readableMap: NSDictionary) -> PaymentMethod {
        let tag = readableMap["TAG"] as? String ?? ""
        let dataObject = readableMap["_0"] as? [String: Any]
        
        switch tag {
        case "SAVEDLISTCARD":
            if let it = dataObject {
                return Card(
                    isDefaultPaymentMethod: it["isDefaultPaymentMethod"] as? Bool ?? false,
                    paymentToken: it["payment_token"] as? String ?? "",
                    cardScheme: it["cardScheme"] as? String ?? "",
                    name: it["name"] as? String ?? "",
                    expiryDate: it["expiry_date"] as? String ?? "",
                    cardNumber: it["cardNumber"] as? String ?? "",
                    nickName: it["nick_name"] as? String ?? "",
                    cardHolderName: it["cardHolderName"] as? String ?? "",
                    requiresCVV: it["requiresCVV"] as? Bool ?? false,
                    created: it["created"] as? String ?? "",
                    lastUsedAt: it["lastUsedAt"] as? String ?? ""
                )
            }
        case "SAVEDLISTWALLET":
            if let it = dataObject {
                return Wallet(
                    isDefaultPaymentMethod: it["isDefaultPaymentMethod"] as? Bool ?? false,
                    paymentToken: it["payment_token"] as? String ?? "",
                    walletType: it["walletType"] as? String ?? "",
                    created: it["created"] as? String ?? "",
                    lastUsedAt: it["lastUsedAt"] as? String ?? ""
                )
            }
        default:
            return PMError(code: readableMap["code"] as? String ?? "",message: readableMap["message"] as? String ?? "No default type found")
        }
        return PMError(code: "01", message: "No default type found")
    }
}

public struct Card: PaymentMethod{
    public let isDefaultPaymentMethod: Bool
    public let paymentToken: String
    public let cardScheme: String
    public let name: String
    public let expiryDate: String
    public let cardNumber: String
    public let nickName: String
    public let cardHolderName: String
    public let requiresCVV: Bool
    public let created: String
    public let lastUsedAt: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "isDefaultPaymentMethod": isDefaultPaymentMethod,
            "paymentToken": paymentToken,
            "cardScheme": cardScheme,
            "name": name,
            "expiryDate": expiryDate,
            "cardNumber": cardNumber,
            "nickName": nickName,
            "cardHolderName": cardHolderName,
            "requiresCVV": requiresCVV,
            "created": created,
            "lastUsedAt": lastUsedAt
        ]
    }
}

public struct Wallet: PaymentMethod {
    public let isDefaultPaymentMethod: Bool
    public let paymentToken: String
    public let walletType: String
    public let created: String
    public let lastUsedAt: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "isDefaultPaymentMethod": isDefaultPaymentMethod,
            "paymentToken": paymentToken,
            "walletType": walletType,
            "created": created,
            "lastUsedAt": lastUsedAt
        ]
    }
}

public struct PMError: PaymentMethod {
    
    public let isDefaultPaymentMethod: Bool = false
    public let paymentToken: String = ""
    public let created: String = ""
    public let lastUsedAt: String = ""
    public let code: String
    public let message: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "code": code,
            "message": message,
            "isDefaultPaymentMethod": isDefaultPaymentMethod,
            "paymentToken": paymentToken,
            "created": created,
            "lastUsedAt": lastUsedAt
        ]
    }
}

public struct PaymentSessionHandler {
    public let getCustomerDefaultSavedPaymentMethodData: () -> PaymentMethod
    public let getCustomerLastUsedPaymentMethodData: () -> PaymentMethod
    public let getCustomerSavedPaymentMethodData: () -> [PaymentMethod]
    public let confirmWithCustomerDefaultPaymentMethod: (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    public let confirmWithCustomerLastUsedPaymentMethod: (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    public let confirmWithCustomerPaymentToken: (_ paymentToken: String, _ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    
    init(
        getCustomerDefaultSavedPaymentMethodData: @escaping () -> PaymentMethod,
        getCustomerLastUsedPaymentMethodData: @escaping () -> PaymentMethod,
        getCustomerSavedPaymentMethodData: @escaping () -> [PaymentMethod],
        confirmWithCustomerDefaultPaymentMethod: @escaping (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void,
        confirmWithCustomerLastUsedPaymentMethod: @escaping (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void,
        confirmWithCustomerPaymentToken: @escaping (_ paymentToken: String, _ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    ) {
        self.getCustomerDefaultSavedPaymentMethodData = getCustomerDefaultSavedPaymentMethodData
        self.getCustomerLastUsedPaymentMethodData = getCustomerLastUsedPaymentMethodData
        self.getCustomerSavedPaymentMethodData = getCustomerSavedPaymentMethodData
        self.confirmWithCustomerDefaultPaymentMethod = confirmWithCustomerDefaultPaymentMethod
        self.confirmWithCustomerLastUsedPaymentMethod = confirmWithCustomerLastUsedPaymentMethod
        self.confirmWithCustomerPaymentToken = confirmWithCustomerPaymentToken
    }
}

public protocol PaymentMethod {
    var isDefaultPaymentMethod: Bool { get }
    var paymentToken: String { get }
    var created: String { get }
    var lastUsedAt: String { get }
    func toHashMap() -> [String: Any]
}

