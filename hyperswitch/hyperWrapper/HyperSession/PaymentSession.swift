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
    
    private static var completion: ((PaymentResult) -> Void)?
    private static var hasResponded = false
    internal static var headlessCompletion: ((PaymentSessionHandler) -> Void)?
    internal static var paymentIntentClientSecret: String?
    
    private static func safeResolve(_ callback: @escaping RCTResponseSenderBlock,_ result: [Any],_ resultHandler: @escaping (PaymentResult) -> Void){
        guard !PaymentSession.hasResponded else {
            print("Warning: Attempt to resolve callback more than once")
            resultHandler(.failed(error: NSError(domain: "Not Initialised", code: 0, userInfo: ["message" : "An error has occurred."])))
            return
        }
        PaymentSession.hasResponded = true
        callback(result)
    }
    
    public init(publishableKey: String, customBackendUrl: String? = nil, customParams: [String : Any]? = nil, customLogUrl: String? = nil){
        APIClient.shared.publishableKey = publishableKey
        APIClient.shared.customBackendUrl = customBackendUrl
        APIClient.shared.customLogUrl = customLogUrl
        APIClient.shared.customParams = customParams
    }
    
    public func initPaymentSession(paymentIntentClientSecret: String){
        PaymentSession.paymentIntentClientSecret = paymentIntentClientSecret
    }
    
    public func presentPaymentSheet(viewController: UIViewController, configuration: PaymentSheet.Configuration, completion: @escaping (PaymentSheetResult) -> ()){
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: PaymentSession.paymentIntentClientSecret ?? "", configuration: configuration)
        paymentSheet.present(from: viewController, completion: completion)
    }
    public func getCustomerSavedPaymentMethods(_ func_: @escaping (PaymentSessionHandler) -> Void) {
        PaymentSession.hasResponded = false
        PaymentSession.headlessCompletion = func_
        RNViewManager.sharedInstance2.reinvalidateBridge()
        let _ = RNViewManager.sharedInstance2.viewForModule("dummy", initialProperties: [:])
    }
    
    internal static func getPaymentSession(getPaymentMethodData: NSDictionary, getPaymentMethodData2: NSDictionary, getPaymentMethodDataArray: NSArray, callback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
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
                    if let map = getPaymentMethodData["_0"] as? NSDictionary,
                       let paymentToken = map["payment_token"] as? String {
                        self.completion = resultHandler
                        var map = [String: Any]()
                        map["paymentToken"] = paymentToken
                        map["cvc"] = cvc
                        self.safeResolve(callback, [map], resultHandler)
                    }
                },
                confirmWithCustomerLastUsedPaymentMethod: { cvc, resultHandler in
                    if let map = getPaymentMethodData2["_0"] as? NSDictionary,
                       let paymentToken = map["payment_token"] as? String {
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

