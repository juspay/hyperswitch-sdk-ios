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

        /// Hide the card nickname input field regardless of the mandate / save-card state. Defaults to false.
        public var hideCardNicknameField: Bool?

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

        /// Hyperswitch `payment_method` values.
        public enum PaymentMethod: String, Encodable {
            case card
            case cardRedirect = "card_redirect"
            case payLater = "pay_later"
            case wallet
            case bankRedirect = "bank_redirect"
            case bankTransfer = "bank_transfer"
            case crypto
            case bankDebit = "bank_debit"
            case reward
            case realTimePayment = "real_time_payment"
            case upi
            case voucher
            case giftCard = "gift_card"
            case openBanking = "open_banking"
            case mobilePayment = "mobile_payment"
            case networkToken = "network_token"
        }

        /// Hyperswitch `payment_method_type` values.
        public enum PaymentMethodType: String, Encodable {
            case ach
            case affirm
            case afterpayClearpay = "afterpay_clearpay"
            case alfamart
            case aliPay = "ali_pay"
            case aliPayHk = "ali_pay_hk"
            case alma
            case amazonPay = "amazon_pay"
            case paysera
            case applePay = "apple_pay"
            case atome
            case bacs
            case bancontactCard = "bancontact_card"
            case becs
            case benefit
            case bizum
            case blik
            case bluecode
            case boleto
            case bcaBankTransfer = "bca_bank_transfer"
            case bniVa = "bni_va"
            case breadpay
            case briVa = "bri_va"
            case bhnCardNetwork = "bhn_card_network"
            case cardRedirect = "card_redirect"
            case cimbVa = "cimb_va"
            case classic
            case credit
            case cryptoCurrency = "crypto_currency"
            case cashapp
            case dana
            case danamonVa = "danamon_va"
            case debit
            case duitNow = "duit_now"
            case efecty
            case eft
            case eftDebitOrder = "eft_debit_order"
            case eps
            case flexiti
            case fps
            case evoucher
            case giropay
            case givex
            case googlePay = "google_pay"
            case goPay = "go_pay"
            case gcash
            case ideal
            case interac
            case indomaret
            case klarna
            case kakaoPay = "kakao_pay"
            case localBankRedirect = "local_bank_redirect"
            case mandiriVa = "mandiri_va"
            case knet
            case mbWay = "mb_way"
            case mobilePay = "mobile_pay"
            case momo
            case momoAtm = "momo_atm"
            case multibanco
            case neteller
            case onlineBankingThailand = "online_banking_thailand"
            case onlineBankingCzechRepublic = "online_banking_czech_republic"
            case onlineBankingFinland = "online_banking_finland"
            case onlineBankingFpx = "online_banking_fpx"
            case onlineBankingPoland = "online_banking_poland"
            case onlineBankingSlovakia = "online_banking_slovakia"
            case oxxo
            case pagoEfectivo = "pago_efectivo"
            case permataBankTransfer = "permata_bank_transfer"
            case openBankingUk = "open_banking_uk"
            case payBright = "pay_bright"
            case payjustnow
            case paypal
            case paze
            case pix
            case pixKey = "pix_key"
            case pixEmv = "pix_emv"
            case pixQr = "pix_qr"
            case pixAutomaticoQr = "pix_automatico_qr"
            case pixAutomaticoPush = "pix_automatico_push"
            case paySafeCard = "pay_safe_card"
            case przelewy24
            case promptPay = "prompt_pay"
            case pse
            case qris
            case redCompra = "red_compra"
            case redPagos = "red_pagos"
            case samsungPay = "samsung_pay"
            case sepa
            case sepaBankTransfer = "sepa_bank_transfer"
            case sepaGuarenteedDebit = "sepa_guarenteed_debit"
            case skrill
            case sofort
            case swish
            case touchNGo = "touch_n_go"
            case trustly
            case twint
            case upiCollect = "upi_collect"
            case upiIntent = "upi_intent"
            case upiQr = "upi_qr"
            case vipps
            case vietQr = "viet_qr"
            case venmo
            case walley
            case wero
            case weChatPay = "we_chat_pay"
            case sevenEleven = "seven_eleven"
            case lawson
            case miniStop = "mini_stop"
            case familyMart = "family_mart"
            case seicomart
            case payEasy = "pay_easy"
            case localBankTransfer = "local_bank_transfer"
            case mifinity
            case openBankingPis = "open_banking_pis"
            case directCarrierBilling = "direct_carrier_billing"
            case instantBankTransfer = "instant_bank_transfer"
            case instantBankTransferFinland = "instant_bank_transfer_finland"
            case instantBankTransferPoland = "instant_bank_transfer_poland"
            case revolutPay = "revolut_pay"
            case indonesianBankTransfer = "indonesian_bank_transfer"
            case openBanking = "open_banking"
            case networkToken = "network_token"
            case payshap
            case payshapProxy = "payshap_proxy"
            case ted
        }

        public enum MessageDisplayMode: String, Encodable {
            case customMessage = "custom_message"
            case defaultSdkMessage = "default_sdk_message"
            case hidden
        }
        public enum TextDecoration: String, Encodable { case none, underline }

        public struct MessageElementStyle {
            public var color: UIColor?
            /// Size, weight and italic are used; the SDK typography supplies the family and scale.
            public var font: UIFont?
            public var textDecoration: TextDecoration?

            public init(color: UIColor? = nil, font: UIFont? = nil, textDecoration: TextDecoration? = nil) {
                self.color = color
                self.font = font
                self.textDecoration = textDecoration
            }
        }

        public struct MessageElementStyles: Encodable {
            public let action: MessageElementStyle?
            public init(action: MessageElementStyle? = nil) {
                self.action = action
            }
        }

        /// One piece of a message: plain text, or an action when it has `onTap`.
        /// The callback never enters the encoded configuration.
        public struct MessageElement: Encodable {
            package let label: String
            package let style: MessageElementStyle?
            package let onTap: (() -> Void)?

            package init(label: String, style: MessageElementStyle? = nil, onTap: (() -> Void)? = nil) {
                self.label = label
                self.style = style
                self.onTap = onTap
            }

            public static func action(
                label: String,
                style: MessageElementStyle? = nil,
                onTap: @escaping () -> Void
            ) -> MessageElement {
                MessageElement(label: label, style: style, onTap: onTap)
            }

            private enum CodingKeys: String, CodingKey {
                case text, tappable, style
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(label, forKey: .text)
                if onTap != nil {
                    try container.encode(true, forKey: .tappable)
                }
                try container.encodeIfPresent(style, forKey: .style)
            }
        }

        /// Typed content retains callbacks locally; only text and styles are encoded.
        public struct PaymentMethodMessage: Encodable {
            public let value: MessageContent?
            /// Unset fields of a payment method type's message come from its payment method's message.
            public let displayMode: MessageDisplayMode?
            public let elementStyles: MessageElementStyles?

            public init(
                value: MessageContent? = nil,
                displayMode: MessageDisplayMode? = nil,
                elementStyles: MessageElementStyles? = nil
            ) {
                self.value = value
                self.displayMode = displayMode
                self.elementStyles = elementStyles
            }

            package func tap(at index: Int, text: String) {
                value?.tap(at: index, text: text)
            }
        }

        /// Message for one payment method type; it wins over its payment method's message.
        public struct PaymentMethodTypeConfig: Encodable {
            public init(paymentMethodType: PaymentMethodType, message: PaymentMethodMessage? = nil) {
                self.paymentMethodType = paymentMethodType
                self.message = message
            }

            public var paymentMethodType: PaymentMethodType
            public var message: PaymentMethodMessage?
        }

        public struct PaymentMethodConfig: Encodable {
            public init(
                paymentMethod: PaymentMethod,
                message: PaymentMethodMessage? = nil,
                paymentMethodTypes: [PaymentMethodTypeConfig]? = nil
            ) {
                self.paymentMethod = paymentMethod
                self.message = message
                self.paymentMethodTypes = paymentMethodTypes
            }

            public var paymentMethod: PaymentMethod
            public var message: PaymentMethodMessage?
            /// Not supported for `.card`.
            public var paymentMethodTypes: [PaymentMethodTypeConfig]?
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

extension PaymentSheet.Configuration {
    /// Runs a tapped message action. `paymentMethodType` is empty when the shown text is the
    /// payment method's own message; `index` is the segment's position in that message and
    /// `text` what it showed, so a segment with other text is not run.
    package func messageTapped(paymentMethod: String, paymentMethodType: String, index: Int, text: String) {
        guard let config = paymentMethodsConfig?.first(where: { $0.paymentMethod.rawValue == paymentMethod }) else {
            return
        }
        let message =
            paymentMethodType.isEmpty
            ? config.message
            : config.paymentMethodTypes?.first { $0.paymentMethodType.rawValue == paymentMethodType }?.message
        message?.tap(at: index, text: text)
    }
}
