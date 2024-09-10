//
//  PaymentIntentParams.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 10/05/23.
//

import Foundation
import UIKit

public class PaymentIntentParams: NSObject {
    
    public init(clientSecret: String) {
        self.clientSecret = clientSecret
        super.init()
    }
    
    public var clientSecret: String = ""
    @objc public var paymentMethodParams: PaymentMethodParams?
    
    public func description() -> [String:Any] {
        let props: [String:Any] = [
            "publishableKey": APIClient.shared.publishableKey ?? "",
            "clientSecret": self.clientSecret,
            "paymentMethodType": "Card",
            "paymentMethodData": ""
        ]
        return props
    }
}
