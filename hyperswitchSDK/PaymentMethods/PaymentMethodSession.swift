//
//  PaymentMethodSession.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

import Foundation

public struct PaymentMethodSessionConfiguration {
    internal let sdkAuthorization: String

    /// [sdkAuthorization] comes from your server's payment method session.
    public init(sdkAuthorization: String) {
        self.sdkAuthorization = sdkAuthorization
    }
}

/// A payment method session: the place card forms come from.
public final class PaymentMethodSession {

    private let hyperswitchConfiguration: HyperswitchConfiguration
    private let configuration: PaymentMethodSessionConfiguration

    internal init(hyperswitchConfiguration: HyperswitchConfiguration, configuration: PaymentMethodSessionConfiguration) {
        self.hyperswitchConfiguration = hyperswitchConfiguration
        self.configuration = configuration
    }

    public func createCardForm(configuration: CardForm.Configuration = CardForm.Configuration()) -> CardForm {
        CardForm(
            hyperswitchConfiguration: hyperswitchConfiguration,
            sessionConfiguration: self.configuration,
            configuration: configuration
        )
    }
}

extension Hyperswitch {

    /// Starts the Payment Methods engine loading, so the first form does not wait for it.
    public func initPaymentMethodSession(configuration: PaymentMethodSessionConfiguration) -> PaymentMethodSession {
        PaymentMethodsHost.shared.warmUp()
        return PaymentMethodSession(hyperswitchConfiguration: hyperswitchConfiguration, configuration: configuration)
    }
}
