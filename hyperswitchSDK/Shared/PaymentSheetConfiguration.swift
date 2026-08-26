//
//  PaymentSheetConfiguration.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 17/06/26.
//

import Foundation
import UIKit

// MARK: - Configuration
extension PaymentSheet {

    /// Configuration for PaymentSheet
    public struct Configuration: Encodable {

        /// Initializes a Configuration with default values
        public init() {}

        /// Describes the appearance of PaymentSheet
        public var appearance: PaymentSheet.Appearance = PaymentSheet.Appearance()

        /// Your customer-facing business name.
        public var merchantDisplayName: String?

        /// If true, allows payment methods that do not move money at the end of the checkout. Defaults to false.
        public var allowsDelayedPaymentMethods: Bool?

        /// If `true`, allows payment methods that require a shipping address, like Afterpay and Affirm. Defaults to `false`.
        public var allowsPaymentMethodsRequiringShippingAddress: Bool?

        /// Toggle to show/hide the "save card" checkbox. Defaults to true.
        public var displaySavedPaymentMethodsCheckbox: Bool?

        /// Toggle to show/hide the saved-card screen. Defaults to true.
        public var displaySavedPaymentMethods: Bool?

        /// Toggle to show/hide the default saved-payment icon. Defaults to true.
        public var displayDefaultSavedPaymentIcon: Bool?

        /// Toggle to show/hide the pay button. Defaults to true for the full PaymentSheet.
        public var displayPayButton: Bool?

        /// Keep the pay button pinned to the bottom of the sheet. Defaults to false.
        public var stickyPayButton: Bool?

        /// Toggle to disable Hyperswitch branding.
        public var disableBranding: Bool?

        /// Pre-load the card element for faster first render. Defaults to false.
        public var preloadCardElement: Bool?

        /// The label to use for the primary button.
        public var primaryButtonLabel: String?

        /// Custom header label for the payment sheet.
        public var paymentSheetHeaderLabel: String?

        /// Custom header label for the saved-payment sheet.
        public var savedPaymentSheetHeaderLabel: String?

        /// API key used to invoke the Netcetera SDK for redirection-less 3DS authentication.
        public var netceteraSDKApiKey: String?

        /// Locale override (e.g. "en", "fr").
        public var locale: String?

        /// Customer the PaymentSheet operates on.
        public var customer: Customer?

        /// Custom placeholder text for card fields.
        public var placeholder: PlaceHolder = PlaceHolder()

        /// Billing details to pre-populate fields with.
        public var billingDetails: AddressDetails = AddressDetails()

        /// Shipping details.
        public var shippingDetails: AddressDetails = AddressDetails()

        /// Per-wallet button styling for the express/wallet buttons.
        public var walletButtonsConfiguration: WalletButtonsConfiguration?

        /// Whether redirection messaging is shown. Defaults to `.shown`.
        public var redirectionInfo: RedirectionVisibility?

        /// Always send a customer-acceptance object on confirm. Defaults to false.
        public var alwaysSendCustomerAcceptance: Bool?

        /// Per-payment-method custom messaging.
        public var paymentMethodsConfig: [PaymentMethodConfig]?

        /// Open the card scanner automatically when the card form appears. Defaults to false.
        public var opensCardScannerAutomatically: Bool?

        /// Override the order in which payment methods are displayed.
        public var paymentMethodOrder: [String]?

        /// Layout customization for the payment-method list.
        public var paymentMethodLayout: PaymentMethodLayout?

        /// Render card fields (number / expiry / cvc) as separate inputs. Defaults to false.
        public var splitCardFields: Bool?

        // MARK: - Placeholder

        public struct PlaceHolder: Encodable {
            public init() {}
            public var cardNumber: String?
            public var expiryDate: String?  // MM/YY
            public var cvv: String?
        }

        // MARK: - Customer

        public struct Customer: Encodable {
            public init() {}
            public init(id: String?, ephemeralKeySecret: String?) {
                self.id = id
                self.ephemeralKeySecret = ephemeralKeySecret
            }
            public var id: String?
            public var ephemeralKeySecret: String?
        }

        // MARK: - Address details

        /// Billing/shipping details for a customer.
        public struct AddressDetails: Encodable {
            public init() {}

            /// The customer's address.
            public var address: Address = Address()

            /// The customer's email.
            public var email: String?

            /// The customer's phone.
            public var phone: Phone = Phone()
        }

        /// An address.
        public struct Address: Encodable {
            public init() {}

            public var firstName: String?
            public var lastName: String?
            public var city: String?
            /// Two-letter country code (ISO 3166-1 alpha-2).
            public var country: String?
            public var line1: String?
            public var line2: String?
            /// ZIP or postal code.
            public var postalCode: String?
            public var state: String?

            // FIXME: `first_name`/`last_name` to camelCase in RN.
            enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case lastName = "last_name"
                case city, country, line1, line2, postalCode, state
            }
        }

        /// A phone number split into a national number and a dialing code.
        public struct Phone: Encodable {
            public init() {}
            public var number: String?
            public var code: String?
        }

        // MARK: - Payment method messaging

        public struct PaymentMethodConfig: Encodable {
            public init(paymentMethod: String, message: String? = nil) {
                self.paymentMethod = paymentMethod
                self.message = message
            }
            public var paymentMethod: String
            public var message: String?
        }

        /// Visibility for redirection messaging.
        public enum RedirectionVisibility: String, Encodable {
            case shown, hidden
        }

        // MARK: - Wallet buttons

        /// Per-wallet button styling for the express/wallet buttons.
        public struct WalletButtonsConfiguration: Encodable {
            public init() {}
            public var applePay: ApplePay?
            public var payPal: PayPal?

            /// Visibility shared by all wallet buttons.
            public enum Visibility: String, Encodable {
                case shown, hidden
            }

            public struct ApplePay: Encodable {
                public init() {}
                public var visibility: Visibility?
                public var buttonType: ButtonType?
                public var buttonStyle: Style?

                public enum ButtonType: String, Encodable {
                    case buy, setUp, inStore, donate, checkout, book, subscribe, plain
                }
                public enum Theme: String, Encodable {
                    case white, whiteOutline, black
                }
                public struct Style: Encodable {
                    public init() {}
                    public init(light: Theme?, dark: Theme?) {
                        self.light = light
                        self.dark = dark
                    }
                    public var light: Theme?
                    public var dark: Theme?
                }
            }

            public struct PayPal: Encodable {
                public init() {}
                public var visibility: Visibility?
                public var buttonType: ButtonType?
                public var buttonSize: ButtonSize?
                public var buttonStyle: Style?

                public enum ButtonType: String, Encodable {
                    case paypal, checkout, buynow, pay
                }
                public enum ButtonSize: String, Encodable {
                    case small, medium, large
                }
                public enum Theme: String, Encodable {
                    case gold, blue, white, black, silver
                }
                public struct Style: Encodable {
                    public init() {}
                    public init(light: Theme?, dark: Theme?) {
                        self.light = light
                        self.dark = dark
                    }
                    public var light: Theme?
                    public var dark: Theme?
                }
            }
        }

        // MARK: - Payment method layout

        /// Layout customization for the payment-method list.
        public struct PaymentMethodLayout: Encodable {
            public init() {}

            public var type: LayoutType?
            public var showOneClickWalletsOnTop: Bool?
            public var paymentMethodsArrangementForTabs: Arrangement?
            public var defaultCollapsed: Bool?
            public var radios: Bool?
            public var spacedAccordionItems: Bool?
            public var maxAccordionItems: Int?
            public var cvcIcon: IconVisibility?
            public var cardBrandIcon: CardBrandIcon?
            public var showCheckedIconForSelection: Bool?
            /// Text shown on the separator between the wallet buttons and the
            /// remaining payment methods. Defaults to the localised "Or pay using".
            public var separatorText: String?
            public var savedMethodCustomization: SavedMethodCustomization?

            public enum LayoutType: String, Encodable {
                case tabs, accordion, spacedAccordion
            }
            public enum Arrangement: String, Encodable {
                case `default`, grid
            }
            public enum IconVisibility: String, Encodable {
                case shown, hidden
            }
            public enum CardBrandIcon: String, Encodable {
                case animated, hidden, standard, hideGeneric
            }

            public struct SavedMethodCustomization: Encodable {
                public init() {}
                public var hideCardExpiry: Bool?
                public var hideCVCError: Bool?
                public var cvcIcon: IconVisibility?
                public var groupingBehavior: GroupingBehavior?
                public var defaultCollapsed: Bool?
                public var hiddenPaymentMethods: [String]?
            }

            public struct GroupingBehavior: Encodable {
                public init() {}
                public var displayInSeparateScreen: Bool?
                public var displayInSeparateSection: Bool?
                public var groupByPaymentMethods: Bool?
            }
        }
    }
}
