//
//  PaymentIntentParams.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 10/05/23.
//

import Foundation
import UIKit

public class PaymentIntentParams: NSObject {

    public init(sdkAuthorization: String) {
        self.sdkAuthorization = sdkAuthorization
        super.init()
    }

    public var sdkAuthorization: String = ""
    @objc public var paymentMethodParams: PaymentMethodParams?

    public func description() -> [String: Any] {
        let props: [String: Any] = [
            "publishableKey": APIClient.shared.publishableKey ?? "",
            "profileId": APIClient.shared.profileId ?? "",
            "sdkAuthorization": self.sdkAuthorization,
            "paymentMethodType": "Card",
            "paymentMethodData": "",
        ]
        return props
    }
}
