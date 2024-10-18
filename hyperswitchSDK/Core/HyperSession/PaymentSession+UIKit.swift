//
//  PaymentSession+UIKit.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation

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
    
//    public func presentPaymentManagementSheet(viewController: UIViewController, configuration: PMMConfiguration, completion: @escaping (PaymentMethodManagementSheetResult) -> ()) {
//        let pmManagement = PaymentMethodManagement(ephemeralKey: PaymentSession.ephemeralKey ?? "", configuration: configuration)
//        pmManagement.presentPaymentMethodManagementView(from: viewController, completion: completion)
//    }
    
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
        RNViewManager.sharedInstance2.reinvalidateBridge()
        let _ = RNViewManager.sharedInstance2.viewForModule("dummy", initialProperties: [:])
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
