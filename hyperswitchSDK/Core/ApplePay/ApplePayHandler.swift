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
    
    var paymentStatus: PKPaymentAuthorizationStatus? = .failure
    var callback: RCTResponseSenderBlock?
    
    internal func startPayment(rnMessage: String, rnCallback: @escaping RCTResponseSenderBlock, presentCallback: RCTResponseSenderBlock?) {
        
        callback = rnCallback
        var requiredBillingContactFields:Set<PKContactField>?
        var requiredShippingContactFields:Set<PKContactField>?
        
        guard let dict = rnMessage.toJSON() as? [String: AnyObject] else {
            presentCallback?([])
            rnCallback([["status": "Error", "message": "01"]])
            return
        }
        
        guard let payment_request_data = dict["payment_request_data"] else {
            presentCallback?([])
            callback?([["status": "Error", "message": "02"]])
            callback = nil
            return
        }
        
        guard let countryCode = payment_request_data["country_code"] as? String else {
            presentCallback?([])
            callback?([["status": "Error", "message": "03"]])
            callback = nil
            return
        }
        
        guard let currencyCode = payment_request_data["currency_code"] as? String else {
            presentCallback?([])
            callback?([["status": "Error", "message": "04"]])
            callback = nil
            return
        }
        guard let total = payment_request_data["total"] as? [String: AnyObject] else {
            presentCallback?([])
            callback?([["status": "Error", "message": "05"]])
            callback = nil
            return
        }
        
        guard let amount = total["amount"] as? String,
              let label = total["label"] as? String,
              let type = total["type"] as? String else {
            presentCallback?([])
            callback?([["status": "Error", "message": "06"]])
            callback = nil
            return
        }
        
        guard let merchant_capabilities_array = payment_request_data["merchant_capabilities"] as? Array<String> else {
            presentCallback?([])
            callback?([["status": "Error", "message": "07"]])
            callback = nil
            return
        }
        
        guard let merchantIdentifier = payment_request_data["merchant_identifier"] as? String else{
            presentCallback?([])
            callback?([["status": "Error", "message": "08"]])
            callback = nil
            return
        }
        
        guard let supported_networks_array = payment_request_data["supported_networks"] as? Array<String> else{
            presentCallback?([])
            callback?([["status": "Error", "message": "09"]])
            callback = nil
            return
        }
        
        let supportedNetworks = supported_networks_array.compactMap { (string) -> PKPaymentNetwork? in
            switch string {
            case "visa":
                return .visa
            case "masterCard":
                return .masterCard
            case "amex":
                return .amex
            case "discover":
                return .discover
            case "quicPay":
                return .quicPay
            default:
                return nil
            }
        }
        
        if let required_billing_contact_fields = payment_request_data["required_billing_contact_fields"] as? Array<String> {
            requiredBillingContactFields = Set(required_billing_contact_fields.compactMap(mapToPKContactField))
        }
        
        if let required_shipping_contact_fields = payment_request_data["required_shipping_contact_fields"] as? Array<String> {
            requiredShippingContactFields = Set(required_shipping_contact_fields.compactMap(mapToPKContactField))
        }
        
        let paymentSummaryItems = PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(string: amount), type: (type == "final") ? .final : .pending)
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = [paymentSummaryItems]
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        paymentRequest.requiredShippingContactFields = requiredShippingContactFields ?? []
        paymentRequest.requiredBillingContactFields = requiredBillingContactFields ?? []
        paymentRequest.supportedNetworks = supportedNetworks
        for val in merchant_capabilities_array {
            paymentRequest.merchantCapabilities = (val == "supports3DS") ? .threeDSecure : .debit
        }
        
        /// Create and present the PKPaymentAuthorizationController
        guard
            PKPaymentAuthorizationController.canMakePayments(),
            !paymentRequest.merchantIdentifier.isEmpty,
            PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) != nil
        else {
            presentCallback?([])
            callback?([["status": "Error", "message": "10"]])
            callback = nil
            return
        }
        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        paymentController.present(completion: { presented in
            presentCallback?([])
            if presented {
                self.paymentStatus = nil
            } else {
                self.callback?([["status": "Error", "message": "11"]])
                self.callback = nil
            }
        })
    }
}

/// Extension to conform to PKPaymentAuthorizationControllerDelegate
extension ApplePayHandler: PKPaymentAuthorizationControllerDelegate {
    
    /// Handle successful payment authorization
    internal func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        
        let errors = [Error]()
        let status = PKPaymentAuthorizationStatus.success
        self.paymentStatus = status
        
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
            [[
                "status": "Success",
                "payment_data": dataString,
                "payment_method": [
                    "type": paymentType,
                    "network": payment.token.paymentMethod.network ?? "",
                    "display_name": payment.token.paymentMethod.displayName ?? ""
                ],
                "transaction_identifier": payment.token.transactionIdentifier,
                "billing_contact": convertPKContactToDictionary(payment.billingContact),
                "shipping_contact": convertPKContactToDictionary(payment.shippingContact)
            ]]
        )
        completion(PKPaymentAuthorizationResult(status: paymentStatus ?? .failure, errors: errors))
    }
    /// Handle completion of the payment authorization flow
    internal func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
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
    
    private func mapToPKContactField(_ string: String) -> PKContactField? {
        switch string {
        case "postalAddress": return .postalAddress
        case "email": return .emailAddress
        case "phone": return .phoneNumber
        case "name": return .name
        case "phoneticName": return .phoneticName
        default: return nil
        }
    }
    
    private func convertPKContactToDictionary(_ contact: PKContact?) -> [String: Any] {
        var contactDict = [String: Any]()
        
        if let name = contact?.name {
            var nameDict = [String: Any]()
            nameDict["givenName"] = name.givenName
            nameDict["familyName"] = name.familyName
            nameDict["namePrefix"] = name.namePrefix
            nameDict["nameSuffix"] = name.nameSuffix
            nameDict["nickname"] = name.nickname
            nameDict["middleName"] = name.middleName
            //            nameDict["phoneticRepresentation"] = name.phoneticRepresentation
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
