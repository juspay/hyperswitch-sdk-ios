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
    public var completion: ((@escaping () -> Any?, @escaping(@escaping (PaymentResult) -> Void) -> Void) -> Void)?
    var completion2: ((PaymentResult) -> Void)?
    static var shared: PaymentSession?
    
    init() {}
    
    public convenience init(viewController: UIViewController?=nil, clientSecret: String) {
        self.init()
        
        PaymentSession.viewController = viewController
        PaymentSession.clientSecret = clientSecret
        PaymentSession.shared = self
        
    }
    
    public func initSavedPaymentMethodSession(_ function1: ((@escaping () -> Any?, @escaping (@escaping (PaymentResult) -> Void) -> Void) -> Void)?) {
        completion = function1
        RNViewManager.sharedInstance2.reinvalidateBridge()
        let _ = RNViewManager.sharedInstance2.viewForModule("dummy", initialProperties: [:])
    }
    
    func getPaymentSession(getPaymentMethodData: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            func getCustomerDefaultSavedPaymentMethodData() -> Any? {
                return self.parseGetPaymentMethodData(getPaymentMethodData)
            }
            
            func confirmWithCustomerDefaultPaymentMethod(resultHandler: @escaping (PaymentResult) -> Void) {
                self.completion2 = resultHandler
                callback([])
            }
            
            self.completion?(getCustomerDefaultSavedPaymentMethodData, confirmWithCustomerDefaultPaymentMethod)
        }
    }
    
    
    func exitHeadless(message: NSDictionary) {
        DispatchQueue.main.async {
            guard let status = message["status"] as? String else {
                self.completion2?(.failed(error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."])))
                return
            }
            switch status {
            case "cancelled":
                self.completion2?(.canceled(data: status))
            case "failed", "requires_payment_method":
                let domain = (message["code"] as? String) != "" ? message["code"] as? String : "UNKNOWN_ERROR"
                let errorMessage = message["message"] as? String ?? "An error has occurred."
                let userInfo = ["message": errorMessage]
                self.completion2?(.failed(error: NSError(domain: domain ?? "UNKNOWN_ERROR", code: 0, userInfo: userInfo)))
            default:
                self.completion2?(.completed(data: status))
            }
            
        }
    }
    
    private func parseGetPaymentMethodData(_ readableMap: NSDictionary) -> Any? {
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
                    cardHolderName: it["cardHolderName"] as? String ?? ""
                )
            }
        case "SAVEDLISTWALLET":
            if let it = dataObject {
                return Wallet(
                    isDefaultPaymentMethod: it["isDefaultPaymentMethod"] as? Bool ?? false,
                    paymentToken: it["payment_token"] as? String ?? "",
                    walletType: it["walletType"] as? String ?? ""
                )
            }
        default:
            return PMError(code: readableMap["code"] as? String ?? "",message: readableMap["message"] as? String ?? "No default type found")
        }
        
        return nil
    }
}

public struct Card {
    public let isDefaultPaymentMethod: Bool
    public let paymentToken: String
    public let cardScheme: String
    public let name: String
    public let expiryDate: String
    public let cardNumber: String
    public let nickName: String
    public let cardHolderName: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "isDefaultPaymentMethod": isDefaultPaymentMethod,
            "paymentToken": paymentToken,
            "cardScheme": cardScheme,
            "name": name,
            "expiryDate": expiryDate,
            "cardNumber": cardNumber,
            "nickName": nickName,
            "cardHolderName": cardHolderName
        ]
    }
}

public struct Wallet {
    public let isDefaultPaymentMethod: Bool
    public let paymentToken: String
    public let walletType: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "isDefaultPaymentMethod": isDefaultPaymentMethod,
            "paymentToken": paymentToken,
            "walletType": walletType
        ]
    }
}

public struct PMError {
    public let code: String
    public let message: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "code": code,
            "message": message
        ]
    }
}
