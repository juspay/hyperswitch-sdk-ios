//
//  VerifyApp.swift
//  Hyperswitch
//
//

import SwiftUI
import UIKit

#if VERIFY_PAYMENTS
import Hyperswitch
#endif
#if VERIFY_PAYMENT_METHODS
import HyperswitchPaymentMethods
#endif
#if VERIFY_PAYMENT_METHOD_MANAGEMENT
import HyperswitchPaymentMethodManagement
#endif
#if VERIFY_LITE
import HyperswitchLite
#endif
#if VERIFY_AUTHENTICATION
import HyperswitchAuthentication
#endif

@main
struct VerifyApp: App {
    var body: some Scene {
        WindowGroup { Text("Hyperswitch \(SDKVersion.current)") }
    }
}

func useLinkedSDKs(presenter: UIViewController) async {
    let hyperswitch = Hyperswitch(configuration: HyperswitchConfiguration(publishableKey: "pk_snd_verify"))
    let session = await hyperswitch.initPaymentSession(configuration: PaymentSessionConfiguration(sdkAuthorization: ""))
    session.updateIntent(authorizationProvider: { $0("") }, completion: { _ in })

    #if VERIFY_PAYMENTS
    session.presentPaymentSheet(viewController: presenter) { _ in }
    #endif
    #if VERIFY_LITE
    session.presentPaymentSheetLite(viewController: presenter, configuration: PaymentSheet.Configuration()) { _ in }
    #endif
    #if VERIFY_PAYMENT_METHODS
    let form = hyperswitch.initPaymentMethodSession(configuration: PaymentMethodSessionConfiguration(sdkAuthorization: "")).createCardForm()
    _ = form.cardNumberField()
    #endif
    #if VERIFY_PAYMENT_METHOD_MANAGEMENT
    hyperswitch.initPaymentMethodManagement(configuration: PaymentMethodManagementConfiguration(sdkAuthorization: ""))
        .present(from: presenter) { _ in }
    #endif
    #if VERIFY_AUTHENTICATION
    _ = hyperswitch.initAuthenticationSession(clientSecret: "", authenticationId: "", merchantId: "")
    _ = AuthenticationSession(publishableKey: "pk_snd_verify")
    _ = ThreeDSProviderFactory.getAvailableProviders()
    #endif
}
