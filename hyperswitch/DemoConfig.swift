//
//  DemoConfig.swift
//  Hyperswitch
//
//  Reference configuration that mirrors android/demo-app DemoConfig.kt.
//

import UIKit

// MARK: - Appearance

func buildAppearance() -> PaymentSheet.Appearance {
    var appearance = PaymentSheet.Appearance()

    // Light colors
    var colorsLight = PaymentSheet.Appearance.Colors()
    colorsLight.primary                  = UIColor(hex: "#006DF9")
    colorsLight.background               = UIColor(hex: "#FFFFFF")
    colorsLight.componentBackground      = UIColor(hex: "#F6F8F9")
    colorsLight.componentBorder          = UIColor(hex: "#E0E0E0")
    colorsLight.componentDivider         = UIColor(hex: "#E0E0E0")
    colorsLight.componentText            = UIColor(hex: "#000000")
    colorsLight.text                     = UIColor(hex: "#000000")
    colorsLight.textSecondary            = UIColor(hex: "#767676")
    colorsLight.componentPlaceholderText = UIColor(hex: "#9E9E9E")
    colorsLight.icon                     = UIColor(hex: "#000000")
    colorsLight.danger                   = UIColor(hex: "#FF0000")
    colorsLight.loaderBackground         = UIColor(hex: "#F6F8F9")
    colorsLight.loaderForeground         = UIColor(hex: "#006DF9")
    appearance.colorsLight = colorsLight

    // Dark colors
    var colorsDark = PaymentSheet.Appearance.Colors()
    colorsDark.primary                  = UIColor(hex: "#006DF9")
    colorsDark.background               = UIColor(hex: "#FFFFFF")
    colorsDark.componentBackground      = UIColor(hex: "#F6F8F9")
    colorsDark.componentBorder          = UIColor(hex: "#E0E0E0")
    colorsDark.componentDivider         = UIColor(hex: "#E0E0E0")
    colorsDark.componentText            = UIColor(hex: "#000000")
    colorsDark.text                     = UIColor(hex: "#000000")
    colorsDark.textSecondary            = UIColor(hex: "#767676")
    colorsDark.componentPlaceholderText = UIColor(hex: "#9E9E9E")
    colorsDark.icon                     = UIColor(hex: "#000000")
    colorsDark.danger                   = UIColor(hex: "#FF0000")
    colorsDark.loaderBackground         = UIColor(hex: "#F6F8F9")
    colorsDark.loaderForeground         = UIColor(hex: "#006DF9")
    appearance.colorsDark = colorsDark

    // Shapes
    appearance.cornerRadius = 8
    appearance.borderWidth  = 1
    var shadow = PaymentSheet.Appearance.Shadow()
    shadow.color     = UIColor(hex: "#000000")
    shadow.intensity = 4
    appearance.shadow = shadow

    // Typography
    appearance.font.sizeScaleFactor = 1.0
    appearance.font.family          = "Roboto"

    // Primary button
    var primaryButtonColorsLight = PaymentSheet.Appearance.PrimaryButtonColors()
    primaryButtonColorsLight.background = UIColor(hex: "#FFE500")
    primaryButtonColorsLight.text       = UIColor(hex: "#000000")
    primaryButtonColorsLight.border     = UIColor(hex: "#000000")
    appearance.primaryButton.colorsLight = primaryButtonColorsLight

    var primaryButtonColorsDark = PaymentSheet.Appearance.PrimaryButtonColors()
    primaryButtonColorsDark.background = UIColor(hex: "#FFE500")
    primaryButtonColorsDark.text       = UIColor(hex: "#000000")
    primaryButtonColorsDark.border     = UIColor(hex: "#000000")
    appearance.primaryButton.colorsDark = primaryButtonColorsDark

    appearance.primaryButton.cornerRadius  = 8
    appearance.primaryButton.borderWidth   = 2.5
    var primaryButtonShadow = PaymentSheet.Appearance.Shadow()
    primaryButtonShadow.color     = UIColor(hex: "#000000")
    primaryButtonShadow.intensity = 4
    appearance.primaryButton.shadow = primaryButtonShadow

    appearance.theme = .light

    return appearance
}

// MARK: - Wallet configuration

func buildWallets() -> PaymentSheet.WalletConfiguration {
    return PaymentSheet.WalletConfiguration(
        applePay: PaymentSheet.ApplePayWalletConfig(
            visibility:  .shown,
            buttonType:  .plain
        ),
        payPal: PaymentSheet.PayPalWalletConfig(
            visibility:  .shown,
            buttonType:  .paypal,
            buttonStyle: PaymentSheet.PayPalThemeStyle(light: .gold, dark: .blue)
        )
    )
}

// MARK: - Placeholder

func buildPlaceHolder() -> PaymentSheet.Configuration.PlaceHolder {
    var placeholder = PaymentSheet.Configuration.PlaceHolder()
    placeholder.cardNumber = "4242 4242 4242 4242"
    placeholder.expiryDate = "MM / YY"
    placeholder.cvv        = "CVC"
    return placeholder
}

// MARK: - Address

func buildAddress() -> PaymentSheet.Configuration.Address {
    var address = PaymentSheet.Configuration.Address()
    address.city       = "San Francisco"
    address.country    = "US"
    address.line1      = "123 Main St"
    address.line2      = "Apt 4B"
    address.postalCode = "94102"
    address.state      = "CA"
    return address
}

// MARK: - Billing & shipping

func buildBillingDetails() -> PaymentSheet.Configuration.AddressDetails {
    var billing = PaymentSheet.Configuration.AddressDetails()
    billing.address     = buildAddress()
    billing.email       = "john@example.com"
    billing.name        = "John Doe"
    billing.phoneCode   = "91"
    billing.phoneNumber = "9999999999"
    return billing
}

func buildShippingDetails() -> PaymentSheet.Configuration.AddressDetails {
    var shipping = PaymentSheet.Configuration.AddressDetails()
    shipping.address     = buildAddress()
    shipping.name        = "John Doe"
    shipping.phoneCode   = "91"
    shipping.phoneNumber = "9999999999"
    return shipping
}

// MARK: - Customer

func buildCustomer() -> PaymentSheet.Configuration.CustomerConfiguration {
    return PaymentSheet.Configuration.CustomerConfiguration(
        id:                 "cus_xxxxxxxxxxxx",
        ephemeralKeySecret: "ephem_xxxxxxxxxxxx"
    )
}

// MARK: - Payment method layout

func buildPaymentMethodLayout() -> PaymentSheet.PaymentMethodLayout {
    return PaymentSheet.PaymentMethodLayout(
        type:                .tabs,
        radios:              false,
        maxAccordionItems:   3,
        spacedAccordionItems: true,
        defaultCollapsed:    true,
        savedMethodCustomization: PaymentSheet.SavedMethodCustomization(
            defaultCollapsed: false,
            hideCardExpiry:   true,
            hideCVCError:     false,
            cvcIcon:          .shown,
            groupingBehavior: PaymentSheet.GroupingBehavior(
                displayInSeparateScreen: true,
                groupByPaymentMethods:   false
            )
        )
    )
}

// MARK: - Full configuration

/// Builds the demo configuration that mirrors the Android DemoConfig and web DemoAppIndex.js reference.
///
/// - Parameter netceteraApiKey: Optional Netcetera 3DS SDK key fetched from the backend.
func buildDemoConfiguration(netceteraApiKey: String? = nil) -> PaymentSheet.Configuration {
    var config = PaymentSheet.Configuration()

    config.appearance                                    = buildAppearance()
    config.walletButtonsConfiguration                    = buildWallets()
    config.placeholder                                   = buildPlaceHolder()
    config.defaultBillingDetails                         = buildBillingDetails()
    config.shippingDetails                               = buildShippingDetails()
    config.customer                                      = buildCustomer()
    config.merchantDisplayName                           = "Example, Inc."
    config.primaryButtonLabel                            = "Pay Now"
    config.paymentSheetHeaderLabel                       = "Select a payment method"
    config.savedPaymentSheetHeaderLabel                  = "Saved payment method"
    config.allowsDelayedPaymentMethods                   = false
    config.allowsPaymentMethodsRequiringShippingAddress  = false
    config.displaySavedPaymentMethodsCheckbox            = true
    config.displaySavedPaymentMethods                    = true
    config.displayDefaultSavedPaymentIcon                = true
    config.disableBranding                               = true
    config.stickyPayButton                               = true
    config.redirectionInfo                               = .hidden
    config.paymentMethodOrder                            = ["apple_pay", "google_pay", "paypal", "samsung_pay", "credit", "klarna"]
    config.paymentMethodsConfig                          = [
        PaymentSheet.Configuration.PaymentMethodConfig(paymentMethod: "card",   message: ""),
        PaymentSheet.Configuration.PaymentMethodConfig(paymentMethod: "wallet", message: ""),
    ]
    config.paymentMethodLayout                           = buildPaymentMethodLayout()
    config.netceteraSDKApiKey                            = netceteraApiKey

    return config
}

// MARK: - UIColor hex helper

private extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8)  / 255.0
        let b = CGFloat(rgb & 0x0000FF)          / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
