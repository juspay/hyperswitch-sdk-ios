//
//  PaymentSheetConfiguration.swift
//  Hyperswitch
//
//  Created by Balaganesh on 09/12/22.
//

import Foundation
import PassKit
import UIKit

// MARK: - Configuration
extension PaymentSheet {

    /// Configuration for PaymentSheet
    public struct Configuration: Codable {

        /// Initializes a Configuration with default values
        public init() {}

        /// If true, allows payment methods that do not move money at the end of the checkout. Defaults to false.
        /// - Description: Some payment methods can't guarantee you will receive funds from your customer at the end of the checkout because they take time to settle (eg. most bank debits, like SEPA or ACH) or require customer action to complete (e.g. OXXO, Konbini, Boleto). If this is set to true, make sure your integration listens to webhooks for notifications on whether a payment has succeeded or not.
        public var allowsDelayedPaymentMethods: Bool?

        /// If `true`, allows payment methods that require a shipping address, like Afterpay and Affirm. Defaults to `false`.
        /// Set this to `true` if you collect shipping addresses and set `Configuration.shippingDetails` or set `shipping` details directly on the PaymentIntent.
        /// - Note: PaymentSheet considers this property `true` and allows payment methods that require a shipping address if `shipping` details are present on the PaymentIntent when PaymentSheet loads.
        public var allowsPaymentMethodsRequiringShippingAddress: Bool?

        /// The label to use for the primary button.
        ///
        /// If not set, Payment Sheet will display suitable default labels
        /// for payment and setup intents.
        public var primaryButtonLabel: String?

        public var paymentSheetHeaderLabel: String?

        public var savedPaymentSheetHeaderLabel: String?

        /// Your customer-facing business name.
        /// The default value is the name of your app, using CFBundleDisplayName or CFBundleName
        public var merchantDisplayName: String?

        ///
        /// toggle to disable SaveCard CheckBox
        public var displaySavedPaymentMethodsCheckbox: Bool?

        ///
        /// toggle to disable SavedCard Screen
        public var displaySavedPaymentMethods: Bool?

        ///
        /// toggle to disable Branding
        public var disableBranding: Bool?

        ///
        /// add custom placeholder text
        public var placeholder: PlaceHolder = PlaceHolder()

        ///
        /// toggle to  disable Default Saved Payment Icon
        public var displayDefaultSavedPaymentIcon: Bool?

        /// A URL that redirects back to your app that PaymentSheet can use to auto-dismiss
        /// web views used for additional authentication, e.g. 3DS2
        public var returnURL: String?

        /// DefaultView = `true` launches PaymentSheet with cardForm, never shows the loading state.
        /// Default value is `false`
        public var defaultView: Bool?

        /// Describes the appearance of PaymentSheet
        public var appearance: PaymentSheet.Appearance = PaymentSheet.Appearance()

        /// PaymentSheet pre-populates fields with the values provided.
        /// be attached to the payment method even if they are not collected by the PaymentSheet UI.
        public var defaultBillingDetails: AddressDetails = AddressDetails()

        /// A closure that returns the customer's shipping details.
        /// This is used to display a "Billing address is same as shipping" checkbox if `defaultBillingDetails` is not provided
        public var shippingDetails: AddressDetails = AddressDetails()

        /// Optional configuration to display a custom message when a saved payment method is removed.
        public var removeSavedPaymentMethodMessage: String?

        /// By default, PaymentSheet will use a dynamic ordering that optimizes payment method display for the customer.
        /// You can override the default order in which payment methods are displayed in PaymentSheet with a list of payment method types.
        /// See https://docs.hyperswitch.io/api/payment_methods/object#payment_method_object-type for the list of valid types.  You may also pass external payment methods.
        /// - Example: ["card", "external_paypal", "klarna"]
        /// - Note: If you omit payment methods from this list, they’ll be automatically ordered by Hyperswitch after the ones you provide. Invalid payment methods are ignored.
        public var paymentMethodOrder: [String]?

        /// Api key used to invoke netcetera sdk for redirection-less 3DS authentication.
        public var netceteraSDKApiKey: String?

        /// hide confirm button for external confirm action
        public var hideConfirmButton: Bool?

        public struct PlaceHolder: Codable {

            public init() {}

            public var cardNumber: String?

            public var expiryDate: String?  //  MM/YY

            public var cvv: String?
        }

        /// Billing details of a customer
        public struct AddressDetails: Codable {

            /// Initializes billing details
            public init() {}

            /// The customer's billing address
            public var address: Address = Address()

            /// The customer's email
            /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
            public var email: String?

            /// The customer's full name
            /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
            public var name: String?

            /// The customer's phone number without formatting (e.g. 5551234567)
            public var phone: String?
        }

        /// An address.
        public struct Address: Codable {

            /// Initializes an Address
            public init() {}

            /// City, district, suburb, town, or village.
            /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
            public var city: String?

            /// Two-letter country code (ISO 3166-1 alpha-2).
            public var country: String?

            /// Address line 1 (e.g., street, PO Box, or company name).
            /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
            public var line1: String?

            /// Address line 2 (e.g., apartment, suite, unit, or building).
            /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
            public var line2: String?

            /// ZIP or postal code.
            /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
            public var postalCode: String?

            /// State, county, province, or region.
            /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
            public var state: String?
        }
    }
}
