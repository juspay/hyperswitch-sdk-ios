//
//  PaymentSheetConfiguration.swift
//  Hyperswitch
//
//  Created by Balaganesh on 09/12/22.
//

import Foundation
import PassKit
import UIKit

// MARK: - Wallet Configuration
extension PaymentSheet {

    /// Visibility of a wallet button
    public enum WalletShowType: String, Codable {
        case shown = "shown"
        case hidden = "hidden"
    }

    /// Layout type for the payment method list.
    public enum LayoutType: String, Codable {
        /// Accordion (expandable list) layout.
        case accordion = "accordion"
        /// Tabs layout.
        case tabs = "tabs"
    }

    /// Arrangement of payment methods in the tabs layout.
    public enum PaymentMethodsArrangement: String, Codable {
        /// Default (list) arrangement.
        case `default` = "default"
        /// Grid arrangement.
        case grid = "grid"
    }

    // MARK: - Payment Method Layout

    /// Grouping behaviour for saved payment methods in the accordion layout.
    public struct GroupingBehavior: Codable {
        public init(
            displayInSeparateScreen: Bool? = nil,
            groupByPaymentMethods: Bool? = nil
        ) {
            self.displayInSeparateScreen = displayInSeparateScreen
            self.groupByPaymentMethods = groupByPaymentMethods
        }
        public var displayInSeparateScreen: Bool?
        public var groupByPaymentMethods: Bool?
    }

    /// Customisation options for the saved payment methods section.
    public struct SavedMethodCustomization: Codable {
        public init(
            defaultCollapsed: Bool? = nil,
            hideCardExpiry: Bool? = nil,
            hideCVCError: Bool? = nil,
            cvcIcon: WalletShowType? = nil,
            groupingBehavior: GroupingBehavior? = nil
        ) {
            self.defaultCollapsed = defaultCollapsed
            self.hideCardExpiry = hideCardExpiry
            self.hideCVCError = hideCVCError
            self.cvcIcon = cvcIcon
            self.groupingBehavior = groupingBehavior
        }
        public var defaultCollapsed: Bool?
        public var hideCardExpiry: Bool?
        public var hideCVCError: Bool?
        public var cvcIcon: WalletShowType?
        public var groupingBehavior: GroupingBehavior?
    }

    /// Layout configuration for the payment method list.
    public struct PaymentMethodLayout: Codable {
        public init(
            type: LayoutType? = nil,
            radios: Bool? = nil,
            maxAccordionItems: Int? = nil,
            spacedAccordionItems: Bool? = nil,
            defaultCollapsed: Bool? = nil,
            showOneClickWalletsOnTop: Bool? = nil,
            paymentMethodsArrangementForTabs: PaymentMethodsArrangement? = nil,
            savedMethodCustomization: SavedMethodCustomization? = nil
        ) {
            self.type = type
            self.radios = radios
            self.maxAccordionItems = maxAccordionItems
            self.spacedAccordionItems = spacedAccordionItems
            self.defaultCollapsed = defaultCollapsed
            self.showOneClickWalletsOnTop = showOneClickWalletsOnTop
            self.paymentMethodsArrangementForTabs = paymentMethodsArrangementForTabs
            self.savedMethodCustomization = savedMethodCustomization
        }
        public var type: LayoutType?
        public var radios: Bool?
        public var maxAccordionItems: Int?
        public var spacedAccordionItems: Bool?
        public var defaultCollapsed: Bool?
        /// Whether to show one-click wallets at the top of the list (default: true).
        public var showOneClickWalletsOnTop: Bool?
        /// Arrangement of payment methods in the tabs layout.
        public var paymentMethodsArrangementForTabs: PaymentMethodsArrangement?
        public var savedMethodCustomization: SavedMethodCustomization?
    }

    // MARK: Apple Pay wallet config

    public enum ApplePayButtonType: String, Codable {
        case buy = "buy"
        case setUp = "setUp"
        case inStore = "inStore"
        case donate = "donate"
        case checkout = "checkout"
        case book = "book"
        case subscribe = "subscribe"
        case plain = "plain"
    }

    public enum ApplePayButtonStyle: String, Codable {
        case white = "white"
        case whiteOutline = "whiteOutline"
        case black = "black"
    }

    public struct ApplePayThemeStyle: Codable {
        public init(light: ApplePayButtonStyle = .black, dark: ApplePayButtonStyle = .white) {
            self.light = light
            self.dark = dark
        }
        public var light: ApplePayButtonStyle
        public var dark: ApplePayButtonStyle
    }

    public struct ApplePayWalletConfig: Codable {
        public init(
            visibility: WalletShowType = .shown,
            buttonType: ApplePayButtonType = .plain,
            buttonStyle: ApplePayThemeStyle? = nil
        ) {
            self.visibility = visibility
            self.buttonType = buttonType
            self.buttonStyle = buttonStyle
        }
        public var visibility: WalletShowType
        public var buttonType: ApplePayButtonType
        public var buttonStyle: ApplePayThemeStyle?
    }

    // MARK: PayPal wallet config

    public enum PayPalButtonType: String, Codable {
        case paypal = "PAYPAL"
        case checkout = "CHECKOUT"
        case buyNow = "BUY_NOW"
        case pay = "PAY"
    }

    public enum PayPalButtonStyle: String, Codable {
        case gold = "GOLD"
        case blue = "BLUE"
        case white = "WHITE"
        case black = "BLACK"
        case silver = "SILVER"
    }

    public struct PayPalThemeStyle: Codable {
        public init(light: PayPalButtonStyle = .gold, dark: PayPalButtonStyle = .blue) {
            self.light = light
            self.dark = dark
        }
        public var light: PayPalButtonStyle
        public var dark: PayPalButtonStyle
    }

    public struct PayPalWalletConfig: Codable {
        public init(
            visibility: WalletShowType = .shown,
            buttonType: PayPalButtonType = .paypal,
            buttonStyle: PayPalThemeStyle? = nil
        ) {
            self.visibility = visibility
            self.buttonType = buttonType
            self.buttonStyle = buttonStyle
        }
        public var visibility: WalletShowType
        public var buttonType: PayPalButtonType
        public var buttonStyle: PayPalThemeStyle?
    }

    // MARK: Google Pay wallet config (stub — not supported on iOS)

    @available(*, deprecated, message: "Google Pay is not supported on iOS. This type exists only for cross-platform API compatibility.")
    public struct GooglePayWalletConfig: Codable {
        public init() {}
    }

    // MARK: WalletConfiguration

    /// Per-wallet button configuration passed to the payment sheet.
    /// Google Pay is not supported on iOS and is always hidden.
    public struct WalletConfiguration: Codable {

        public init(
            applePay: ApplePayWalletConfig = ApplePayWalletConfig(),
            payPal: PayPalWalletConfig = PayPalWalletConfig()
        ) {
            self.applePay = applePay
            self.payPal = payPal
        }

        public var applePay: ApplePayWalletConfig
        public var payPal: PayPalWalletConfig

        // Wire keys — matches SdkTypes.res: walletButtonsConfiguration { googlePay, applePay, payPal }
        enum CodingKeys: String, CodingKey {
            case googlePay, applePay, payPal
        }

        public func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            // Google Pay is not supported on iOS — always encode as hidden
            try c.encode(["visibility": WalletShowType.hidden.rawValue], forKey: .googlePay)
            try c.encode(applePay, forKey: .applePay)
            try c.encode(payPal, forKey: .payPal)
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            applePay = try c.decodeIfPresent(ApplePayWalletConfig.self, forKey: .applePay) ?? ApplePayWalletConfig()
            payPal = try c.decodeIfPresent(PayPalWalletConfig.self, forKey: .payPal) ?? PayPalWalletConfig()
        }
    }
}

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
        /// - Note: If you omit payment methods from this list, they'll be automatically ordered by Hyperswitch after the ones you provide. Invalid payment methods are ignored.
        public var paymentMethodOrder: [String]?

        /// Api key used to invoke netcetera sdk for redirection-less 3DS authentication.
        public var netceteraSDKApiKey: String?

        /// hide confirm button for external confirm action
        public var hideConfirmButton: Bool?

        /// Per-wallet button configuration for the payment sheet
        public var walletButtonsConfiguration: WalletConfiguration = WalletConfiguration()

        /// Controls visibility of redirection info.
        public var redirectionInfo: WalletShowType?

        /// Layout configuration for the payment method list.
        public var paymentMethodLayout: PaymentMethodLayout?

        /// The customer configuration (id + ephemeral key).
        public var customer: CustomerConfiguration?

        /// Whether to display the confirm/pay button.
        public var displayPayButton: Bool?

        /// Whether to keep the pay button always visible (sticky).
        public var stickyPayButton: Bool?

        /// Whether to preload the card element before the sheet is opened.
        public var preloadCardElement: Bool?

        /// Always send customer acceptance data when confirming.
        public var alwaysSendCustomerAcceptance: Bool?

        /// Automatically open the card scanner when the card form is shown.
        public var opensCardScannerAutomatically: Bool?

        /// Per-payment-method message overrides.
        public var paymentMethodsConfig: [PaymentMethodConfig]?

        // MARK: CodingKeys — maps defaultBillingDetails → "billingDetails" on the wire
        enum CodingKeys: String, CodingKey {
            case allowsDelayedPaymentMethods
            case allowsPaymentMethodsRequiringShippingAddress
            case primaryButtonLabel
            case paymentSheetHeaderLabel
            case savedPaymentSheetHeaderLabel
            case merchantDisplayName
            case displaySavedPaymentMethodsCheckbox
            case displaySavedPaymentMethods
            case disableBranding
            case placeholder
            case displayDefaultSavedPaymentIcon
            case returnURL
            case defaultView
            case appearance
            case billingDetails           // wire key for defaultBillingDetails
            case shippingDetails
            case removeSavedPaymentMethodMessage
            case paymentMethodOrder
            case netceteraSDKApiKey
            case hideConfirmButton
            case walletButtonsConfiguration
            case redirectionInfo
            case paymentMethodLayout
            case customer
            case displayPayButton
            case stickyPayButton
            case preloadCardElement
            case alwaysSendCustomerAcceptance
            case opensCardScannerAutomatically
            case paymentMethodsConfig
        }

        public func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encodeIfPresent(allowsDelayedPaymentMethods, forKey: .allowsDelayedPaymentMethods)
            try c.encodeIfPresent(allowsPaymentMethodsRequiringShippingAddress, forKey: .allowsPaymentMethodsRequiringShippingAddress)
            try c.encodeIfPresent(primaryButtonLabel, forKey: .primaryButtonLabel)
            try c.encodeIfPresent(paymentSheetHeaderLabel, forKey: .paymentSheetHeaderLabel)
            try c.encodeIfPresent(savedPaymentSheetHeaderLabel, forKey: .savedPaymentSheetHeaderLabel)
            try c.encodeIfPresent(merchantDisplayName, forKey: .merchantDisplayName)
            try c.encodeIfPresent(displaySavedPaymentMethodsCheckbox, forKey: .displaySavedPaymentMethodsCheckbox)
            try c.encodeIfPresent(displaySavedPaymentMethods, forKey: .displaySavedPaymentMethods)
            try c.encodeIfPresent(disableBranding, forKey: .disableBranding)
            try c.encode(placeholder, forKey: .placeholder)
            try c.encodeIfPresent(displayDefaultSavedPaymentIcon, forKey: .displayDefaultSavedPaymentIcon)
            try c.encodeIfPresent(returnURL, forKey: .returnURL)
            try c.encodeIfPresent(defaultView, forKey: .defaultView)
            try c.encode(appearance, forKey: .appearance)
            try c.encode(defaultBillingDetails, forKey: .billingDetails)
            try c.encode(shippingDetails, forKey: .shippingDetails)
            try c.encodeIfPresent(removeSavedPaymentMethodMessage, forKey: .removeSavedPaymentMethodMessage)
            try c.encodeIfPresent(paymentMethodOrder, forKey: .paymentMethodOrder)
            try c.encodeIfPresent(netceteraSDKApiKey, forKey: .netceteraSDKApiKey)
            try c.encodeIfPresent(hideConfirmButton, forKey: .hideConfirmButton)
            try c.encode(walletButtonsConfiguration, forKey: .walletButtonsConfiguration)
            try c.encodeIfPresent(redirectionInfo, forKey: .redirectionInfo)
            try c.encodeIfPresent(paymentMethodLayout, forKey: .paymentMethodLayout)
            try c.encodeIfPresent(customer, forKey: .customer)
            try c.encodeIfPresent(displayPayButton, forKey: .displayPayButton)
            try c.encodeIfPresent(stickyPayButton, forKey: .stickyPayButton)
            try c.encodeIfPresent(preloadCardElement, forKey: .preloadCardElement)
            try c.encodeIfPresent(alwaysSendCustomerAcceptance, forKey: .alwaysSendCustomerAcceptance)
            try c.encodeIfPresent(opensCardScannerAutomatically, forKey: .opensCardScannerAutomatically)
            try c.encodeIfPresent(paymentMethodsConfig, forKey: .paymentMethodsConfig)
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            allowsDelayedPaymentMethods = try c.decodeIfPresent(Bool.self, forKey: .allowsDelayedPaymentMethods)
            allowsPaymentMethodsRequiringShippingAddress = try c.decodeIfPresent(Bool.self, forKey: .allowsPaymentMethodsRequiringShippingAddress)
            primaryButtonLabel = try c.decodeIfPresent(String.self, forKey: .primaryButtonLabel)
            paymentSheetHeaderLabel = try c.decodeIfPresent(String.self, forKey: .paymentSheetHeaderLabel)
            savedPaymentSheetHeaderLabel = try c.decodeIfPresent(String.self, forKey: .savedPaymentSheetHeaderLabel)
            merchantDisplayName = try c.decodeIfPresent(String.self, forKey: .merchantDisplayName)
            displaySavedPaymentMethodsCheckbox = try c.decodeIfPresent(Bool.self, forKey: .displaySavedPaymentMethodsCheckbox)
            displaySavedPaymentMethods = try c.decodeIfPresent(Bool.self, forKey: .displaySavedPaymentMethods)
            disableBranding = try c.decodeIfPresent(Bool.self, forKey: .disableBranding)
            placeholder = try c.decodeIfPresent(PlaceHolder.self, forKey: .placeholder) ?? PlaceHolder()
            displayDefaultSavedPaymentIcon = try c.decodeIfPresent(Bool.self, forKey: .displayDefaultSavedPaymentIcon)
            returnURL = try c.decodeIfPresent(String.self, forKey: .returnURL)
            defaultView = try c.decodeIfPresent(Bool.self, forKey: .defaultView)
            appearance = try c.decodeIfPresent(PaymentSheet.Appearance.self, forKey: .appearance) ?? Appearance()
            defaultBillingDetails = try c.decodeIfPresent(AddressDetails.self, forKey: .billingDetails) ?? AddressDetails()
            shippingDetails = try c.decodeIfPresent(AddressDetails.self, forKey: .shippingDetails) ?? AddressDetails()
            removeSavedPaymentMethodMessage = try c.decodeIfPresent(String.self, forKey: .removeSavedPaymentMethodMessage)
            paymentMethodOrder = try c.decodeIfPresent([String].self, forKey: .paymentMethodOrder)
            netceteraSDKApiKey = try c.decodeIfPresent(String.self, forKey: .netceteraSDKApiKey)
            hideConfirmButton = try c.decodeIfPresent(Bool.self, forKey: .hideConfirmButton)
            walletButtonsConfiguration = try c.decodeIfPresent(WalletConfiguration.self, forKey: .walletButtonsConfiguration) ?? WalletConfiguration()
            redirectionInfo = try c.decodeIfPresent(WalletShowType.self, forKey: .redirectionInfo)
            paymentMethodLayout = try c.decodeIfPresent(PaymentMethodLayout.self, forKey: .paymentMethodLayout)
            customer = try c.decodeIfPresent(CustomerConfiguration.self, forKey: .customer)
            displayPayButton = try c.decodeIfPresent(Bool.self, forKey: .displayPayButton)
            stickyPayButton = try c.decodeIfPresent(Bool.self, forKey: .stickyPayButton)
            preloadCardElement = try c.decodeIfPresent(Bool.self, forKey: .preloadCardElement)
            alwaysSendCustomerAcceptance = try c.decodeIfPresent(Bool.self, forKey: .alwaysSendCustomerAcceptance)
            opensCardScannerAutomatically = try c.decodeIfPresent(Bool.self, forKey: .opensCardScannerAutomatically)
            paymentMethodsConfig = try c.decodeIfPresent([PaymentMethodConfig].self, forKey: .paymentMethodsConfig)
        }

        public struct PlaceHolder: Codable {

            public init() {}

            public var cardNumber: String?

            public var expiryDate: String?  //  MM/YY

            public var cvv: String?
        }

        /// Customer identifier + ephemeral key for saved payment methods.
        public struct CustomerConfiguration: Codable {
            public init(id: String? = nil, ephemeralKeySecret: String? = nil) {
                self.id = id
                self.ephemeralKeySecret = ephemeralKeySecret
            }
            public var id: String?
            public var ephemeralKeySecret: String?
        }

        /// Per-payment-method message override.
        public struct PaymentMethodConfig: Codable {
            public init(paymentMethod: String, message: String? = nil) {
                self.paymentMethod = paymentMethod
                self.message = message
            }
            /// The payment method identifier, e.g. "card", "wallet".
            public var paymentMethod: String
            /// Optional custom message to display for this payment method.
            public var message: String?
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

            /// The customer's phone number (digits only, without country code)
            public var phoneNumber: String?

            /// The customer's phone country code (e.g. "1" for US, "44" for UK)
            public var phoneCode: String?

            // MARK: Codable — phone is serialized as { number, code } sub-object

            enum CodingKeys: String, CodingKey {
                case address, email, name, phone
            }
            private enum PhoneKeys: String, CodingKey {
                case number, code
            }

            public func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(address, forKey: .address)
                try c.encodeIfPresent(email, forKey: .email)
                try c.encodeIfPresent(name, forKey: .name)
                if phoneNumber != nil || phoneCode != nil {
                    var phoneContainer = c.nestedContainer(keyedBy: PhoneKeys.self, forKey: .phone)
                    try phoneContainer.encodeIfPresent(phoneNumber, forKey: .number)
                    try phoneContainer.encodeIfPresent(phoneCode, forKey: .code)
                }
            }

            public init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                address = try c.decodeIfPresent(Address.self, forKey: .address) ?? Address()
                email = try c.decodeIfPresent(String.self, forKey: .email)
                name = try c.decodeIfPresent(String.self, forKey: .name)
                if let phoneContainer = try? c.nestedContainer(keyedBy: PhoneKeys.self, forKey: .phone) {
                    phoneNumber = try phoneContainer.decodeIfPresent(String.self, forKey: .number)
                    phoneCode = try phoneContainer.decodeIfPresent(String.self, forKey: .code)
                }
            }
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
