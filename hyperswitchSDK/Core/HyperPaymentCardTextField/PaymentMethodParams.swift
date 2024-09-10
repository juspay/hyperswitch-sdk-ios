//
//  PaymentMethodParams.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 10/05/23.
//

import Foundation
import UIKit

public class PaymentMethodParams: NSObject {
    
    public init(card: String?, billingDetails: String?, metadata: String?) {
        self.card = card
        self.billingDetails = billingDetails
        self.metadata = metadata
        
        super.init()
    }
    
    public var card: String? = ""
    public var billingDetails: String? = ""
    public var metadata: String? = ""
    
}
