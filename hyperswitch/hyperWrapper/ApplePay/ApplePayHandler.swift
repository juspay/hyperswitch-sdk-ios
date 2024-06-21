//
//  ApplePayHandler.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 10/12/22.
//

import Foundation
import PassKit
import React

internal class ApplePayHandler: NSObject {
    
    var paymentController: PKPaymentAuthorizationController?
    var paymentStatus: PKPaymentAuthorizationStatus? = nil
    var callback: RCTDirectEventBlock?
    
    // Method to start an Apple Pay payment
    func startPayment(rnMessage: String, rnCallback: @escaping RCTDirectEventBlock) {
        
        callback = rnCallback
        var supportedNetworks: [PKPaymentNetwork]?
        var requiredBillingContactFields:Set<PKContactField> = [.emailAddress, .phoneNumber, .postalAddress, .name] //remove
        var requiredShippingContactFields:Set<PKContactField> = [.emailAddress, .phoneNumber, .postalAddress, .name] //remove
        
        
        guard let dict = rnMessage.toJSON() as? [String: AnyObject] else {
            rnCallback(["status": "Error"])
            return
        }
        
        guard let payment_request_data = dict["payment_request_data"] else {
            rnCallback(["status": "Error"])
            return
        }
        
        guard let countryCode = payment_request_data["country_code"] as? String else {
            rnCallback(["status": "Error"])
            return
        }
        
        guard let currencyCode = payment_request_data["currency_code"] as? String else {
            rnCallback(["status": "Error"])
            return
        }
        guard let total = payment_request_data["total"] as? [String: AnyObject] else {
            rnCallback(["status": "Error"])
            return
        }
        
        guard let amount = total["amount"] as? String,
              let label = total["label"] as? String,
              let type = total["type"] as? String else {
            rnCallback(["status": "Error"])
            return
        }
        
        guard let merchant_capabilities_array = payment_request_data["merchant_capabilities"] as? Array<String> else {
            rnCallback(["status": "Error"])
            return
        }
        
        if let supported_networks_array = payment_request_data["supported_networks"] as? Array<String> {
            supportedNetworks = supported_networks_array.compactMap { PKPaymentNetwork(rawValue: $0.capitalized) }
        }
        
        guard let merchantIdentifier = payment_request_data["merchant_identifier"] as? String else{
            rnCallback(["status": "Error"])
            return
        }
        
        if let required_billing_contact_fields = payment_request_data["required_billing_contact_fields"] as? Array<String> {
            requiredBillingContactFields = Set(required_billing_contact_fields.compactMap { PKContactField(rawValue: $0) })
        }
        
        if let required_shipping_contact_fields = payment_request_data["required_shipping_contact_fields"] as? Array<String> {
            requiredShippingContactFields = Set(required_shipping_contact_fields.compactMap { PKContactField(rawValue: $0) })
        }
             
        let paymentSummaryItems = PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(string: amount), type: (type == "final") ? .final : .pending)
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = [paymentSummaryItems]
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        paymentRequest.requiredShippingContactFields = requiredShippingContactFields
        paymentRequest.requiredBillingContactFields = requiredBillingContactFields
        paymentRequest.supportedNetworks = supportedNetworks ?? []
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
                rnCallback(["status": "Error"])
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
            
            self.callback?(
                [
                    "status": "Success",
                    "payment_data": dataString,
                    "payment_method": [
                        "type": paymentType,
                        "network": payment.token.paymentMethod.network ?? "",
                        "display_name": payment.token.paymentMethod.displayName ?? ""
                    ],
                    "transaction_identifier": payment.token.transactionIdentifier,
                    "billing_contact": convertPKContactToDictionary(payment.shippingContact)
                ]
            )
        }
        
        completion(paymentStatus ?? .failure)
    }
    /// Handle completion of the payment authorization flow
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            DispatchQueue.main.async {
                if self.paymentStatus == .failure {
                    self.callback?(["status": "Failed"])
                } else if self.paymentStatus == nil {
                    self.callback?(["status": "Cancelled"])
                }
            }
        }
    }
    func convertPKContactToDictionary(_ contact: PKContact?) -> [String: Any] {
        var contactDict = [String: Any]()
        
        if let name = contact?.name {
            var nameDict = [String: Any]()
            nameDict["givenName"] = name.givenName
            nameDict["familyName"] = name.familyName
            nameDict["namePrefix"] = name.namePrefix
            nameDict["nameSuffix"] = name.nameSuffix
            nameDict["nickname"] = name.nickname
            nameDict["middleName"] = name.middleName
            //nameDict["phoneticRepresentation"] = name.phoneticRepresentation
            contactDict["name"] = nameDict
        }
        
        if let postalAddress = contact?.postalAddress {
            var addressDict = [String: Any]()
            addressDict["street"] = postalAddress.street
            addressDict["city"] = postalAddress.city
            addressDict["state"] = postalAddress.state
            addressDict["postalCode"] = postalAddress.postalCode
            addressDict["country"] = postalAddress.country
            addressDict["subLocality"] = postalAddress.subLocality
            addressDict["subAdministrativeArea"] = postalAddress.subAdministrativeArea
            addressDict["isoCountryCode"] = postalAddress.isoCountryCode
            contactDict["postalAddress"] = addressDict
        }
        
        if let phoneNumber = contact?.phoneNumber {
            contactDict["phoneNumber"] = phoneNumber.stringValue
        }
        
        if let emailAddress = contact?.emailAddress {
            contactDict["emailAddress"] = emailAddress
        }
        
        return contactDict
    }
}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}
