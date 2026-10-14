//
//  ApplePayHandler.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 10/12/22.
//

import Foundation
import HyperswitchShared
import PassKit
internal import React

internal class ApplePayHandler: NSObject {

    var paymentStatus: PKPaymentAuthorizationStatus? = .failure
    var callback: RCTResponseSenderBlock?

    private var retainedSelf: ApplePayHandler?

    internal func startPayment(rnMessage: String, rnCallback: @escaping RCTResponseSenderBlock, presentCallback: RCTResponseSenderBlock?) {

        callback = rnCallback
        var requiredBillingContactFields: Set<PKContactField>?
        var requiredShippingContactFields: Set<PKContactField>?

        guard let dict = rnMessage.toJSON() as? [String: AnyObject] else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing field payment_request_data"])
            return
        }

        guard let payment_request_data = dict["payment_request_data"] else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing field payment_request_data"])
            return
        }

        guard let countryCode = payment_request_data["country_code"] as? String else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing field country_code"])
            return
        }

        guard let currencyCode = payment_request_data["currency_code"] as? String else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing field currency_code"])
            return
        }
        guard let total = payment_request_data["total"] as? [String: AnyObject] else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing field total"])
            return
        }

        guard let amount = total["amount"] as? String,
            let label = total["label"] as? String,
            let type = total["type"] as? String
        else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing fields amount, label, type"])
            return
        }

        guard let merchant_capabilities_array = payment_request_data["merchant_capabilities"] as? [String] else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing field merchant_capabilities"])
            return
        }

        guard let merchantIdentifier = payment_request_data["merchant_identifier"] as? String else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing field merchant_identifier"])
            return
        }

        guard let supported_networks_array = payment_request_data["supported_networks"] as? [String] else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: missing field supported_networks"])
            return
        }

        let supportedNetworks = supported_networks_array.compactMap { (string) -> PKPaymentNetwork? in
            switch string.lowercased() {
            case "amex": return .amex
            case "bancomat":
                if #available(iOS 16.0, *) { return .bancomat }
                return nil
            case "bancontact":
                if #available(iOS 16.0, *) { return .bancontact }
                return nil
            case "cartesbancaires": return .cartesBancaires
            case "chinaunionpay": return .chinaUnionPay
            case "dankort": return .dankort
            case "discover": return .discover
            case "eftpos": return .eftpos
            case "electron": return .electron
            case "elo": return .elo
            case "girocard": return .girocard
            case "interac": return .interac
            case "jcb": return .JCB
            case "mada": return .mada
            case "maestro": return .maestro
            case "mastercard": return .masterCard
            case "mir": return .mir
            case "privatelabel": return .privateLabel
            case "quicpay": return .quicPay
            case "visa": return .visa
            case "vpay": return .vPay
            default: return nil
            }
        }

        if let required_billing_contact_fields = payment_request_data["required_billing_contact_fields"] as? [String] {
            requiredBillingContactFields = Set(required_billing_contact_fields.compactMap(mapToPKContactField))
        }

        if let required_shipping_contact_fields = payment_request_data["required_shipping_contact_fields"] as? [String] {
            requiredShippingContactFields = Set(required_shipping_contact_fields.compactMap(mapToPKContactField))
        }

        let paymentSummaryItems = PKPaymentSummaryItem(
            label: label,
            amount: NSDecimalNumber(string: amount),
            type: (type == "final") ? .final : .pending
        )
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = [paymentSummaryItems]
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        paymentRequest.requiredShippingContactFields = requiredShippingContactFields ?? []
        paymentRequest.requiredBillingContactFields = requiredBillingContactFields ?? []
        paymentRequest.supportedNetworks = supportedNetworks
        paymentRequest.merchantCapabilities = []
        for val in merchant_capabilities_array {
            switch val {
            case "supports3DS": paymentRequest.merchantCapabilities.insert(.threeDSecure)
            case "supportsCredit": paymentRequest.merchantCapabilities.insert(.credit)
            case "supportsDebit": paymentRequest.merchantCapabilities.insert(.debit)
            case "supportsEMV": paymentRequest.merchantCapabilities.insert(.emv)
            default: break
            }
        }

        /// Create and present the PKPaymentAuthorizationController
        guard
            PKPaymentAuthorizationController.canMakePayments(),
            !paymentRequest.merchantIdentifier.isEmpty,
            PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) != nil
        else {
            presentCallback?([])
            complete(["status": "Failed", "message": "ApplePay: cannot make payments"])
            return
        }
        let paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController.delegate = self
        retainedSelf = self
        paymentController.present(completion: { presented in
            presentCallback?([])
            if presented {
                self.paymentStatus = nil
            } else {
                self.complete(["status": "Failed", "message": "ApplePay: unable to present"])
                self.retainedSelf = nil
            }
        })
    }

    private func complete(_ result: [String: Any]) {
        guard let callback else { return }
        self.callback = nil
        callback([result])
    }
}

/// Extension to conform to PKPaymentAuthorizationControllerDelegate
extension ApplePayHandler: PKPaymentAuthorizationControllerDelegate {

    /// Handle successful payment authorization
    internal func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {

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

        complete(
            [
                "status": "Success",
                "payment_data": dataString,
                "payment_method": [
                    "type": paymentType,
                    "network": payment.token.paymentMethod.network ?? "",
                    "display_name": payment.token.paymentMethod.displayName ?? "",
                ],
                "transaction_identifier": payment.token.transactionIdentifier,
                "billing_contact": convertPKContactToDictionary(payment.billingContact),
                "shipping_contact": convertPKContactToDictionary(payment.shippingContact),
            ]
        )
        completion(PKPaymentAuthorizationResult(status: paymentStatus ?? .failure, errors: errors))
    }
    /// Handle completion of the payment authorization flow
    // NOTE: PassKit can call this twice for one presentation (Home pressed as the sheet appears).
    // Clearing the delegate drops the second call; complete() guards the callback.
    internal func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.delegate = nil
        controller.dismiss {
            DispatchQueue.main.async {
                if self.paymentStatus == .failure {
                    self.complete(["status": "Failed", "message": "ApplePay: payment failed"])
                } else if self.paymentStatus == nil {
                    self.complete(["status": "Cancelled"])
                }
                self.retainedSelf = nil
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
