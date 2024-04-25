//
//  ApplePayHandler.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 10/12/22.
//

import Foundation
import PassKit
import React

class ApplePayHandler: NSObject {
    
    var paymentController: PKPaymentAuthorizationController?
    var paymentStatus: PKPaymentAuthorizationStatus? = nil
    var callback: RCTResponseSenderBlock?
    
    // Method to start an Apple Pay payment
    func startPayment(rnMessage: String, rnCallback: @escaping RCTResponseSenderBlock) {
        
        callback = rnCallback
        
        guard let dict = rnMessage.toJSON() as? [String: AnyObject] else {
            rnCallback([["status": "Error"]])
            return
        }
        
        guard let session_token_data = dict["session_token_data"],
              let payment_request_data = dict["payment_request_data"] else {
            rnCallback([["status": "Error"]])
            return
        }
        
        guard let total1 = payment_request_data["total"] as? [String: AnyObject] else {
            rnCallback([["status": "Error"]])
            return
        }
        
        guard let amount = total1["amount"] as? String,
              let label = total1["label"] as? String,
              let type = total1["type"] as? String else {
            rnCallback([["status": "Error"]])
            return
        }
        
        guard let merchant_capabilities_array = payment_request_data["merchant_capabilities"] as? Array<String>,
              let supported_networks_array = payment_request_data["supported_networks"] as? Array<String> else {
            rnCallback([["status": "Error"]])
            return
        }
        
        guard let merchantIdentifier = payment_request_data["merchant_identifier"] as? String,
              let countryCode = payment_request_data["country_code"] as? String,
              let currencyCode = payment_request_data["currency_code"] as? String else {
            rnCallback([["status": "Error"]])
            return
        }
        
        let total = PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(string: amount), type: (type == "final") ? .final : .pending)
        
        let supportedNetworks = supported_networks_array.map { (string) -> PKPaymentNetwork in
            if string == "visa" {
                return .visa
            } else if string == "masterCard" {
                return .masterCard
            } else if string == "amex" {
                return .amex
            } else if string == "discover" {
                return .discover
            }
            return .quicPay
        }
        
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = [total]
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        paymentRequest.requiredShippingContactFields = [.phoneNumber, .emailAddress]
        paymentRequest.supportedNetworks = supportedNetworks
        
        for val in merchant_capabilities_array {
            paymentRequest.merchantCapabilities = (val == "supports3DS") ? .capability3DS : .capabilityDebit
        }
        
        /// Create and present the PKPaymentAuthorizationController
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present(completion: { presented in
            if presented {
                self.paymentStatus = nil
            } else {
                rnCallback([["status": "Error"]])
            }
        })
    }
}

/// Extension to conform to PKPaymentAuthorizationControllerDelegate
extension ApplePayHandler: PKPaymentAuthorizationControllerDelegate {
    
    /// Handle successful payment authorization
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        
        if payment.shippingContact?.emailAddress == nil || payment.shippingContact?.phoneNumber == nil {
            paymentStatus = .failure
        } else {
            paymentStatus = .success
            
            let dataString = payment.token.paymentData.base64EncodedString()
            
            var paymentType = "debit"
            switch payment.token.paymentMethod.type {
            case .debit: paymentType = "debit"
            case .credit: paymentType = "credit"
            case .store: paymentType = "store"
            case .prepaid: paymentType = "prepaid"
            case .eMoney: paymentType = "eMoney"
            default: paymentType = "unknown"
            }
            
            self.callback?([
                [
                    "status": "Success",
                    "payment_data": dataString,
                    "payment_method": [
                        "type": paymentType,
                        "network": payment.token.paymentMethod.network ?? "",
                        "display_name": payment.token.paymentMethod.displayName ?? ""
                    ],
                    "transaction_identifier": payment.token.transactionIdentifier
                ]
            ])
        }
        
        completion(paymentStatus ?? .failure)
    }
    /// Handle completion of the payment authorization flow
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            DispatchQueue.main.async {
                if self.paymentStatus == .failure {
                    self.callback?([["status": "Failed"]])
                } else if self.paymentStatus == nil {
                    self.callback?([["status": "Cancelled"]])
                }
            }
        }
    }
    
}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}
