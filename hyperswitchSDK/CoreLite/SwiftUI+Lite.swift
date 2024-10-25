//
//  SwiftUI+Lite.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 25/10/24.
//

import Foundation
import SwiftUI

/// Extension on the PaymentSheet class to provide a SwiftUI integration for presenting the payment sheet.
extension PaymentSheet {
    
    /// A SwiftUI View struct that represents a button for presenting the payment sheet.
    @available(iOS 13.0, *)
    public struct PaymentButtonLite<Content: View>: View {
        private let paymentSession: PaymentSession
        private let configuration: Configuration
        private let content: Content
        private let completion: (PaymentSheetResult) -> ()
        
        @Environment(\.viewController) private var viewControllerHolder: UIViewController?
        
        /// Initializer for the PaymentButton.
        public init(
            paymentSession: PaymentSession,
            configuration: Configuration,
            onCompletion: @escaping (PaymentSheetResult) -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.paymentSession = paymentSession
            self.configuration = configuration
            self.completion = onCompletion
            self.content = content()
        }
        
        /// The body of the PaymentButton view.
        public var body: some View {
            Button(action: {
                if let vc = viewControllerHolder {
                    paymentSession.presentPaymentSheetLite(viewController: vc, configuration: configuration, completion: completion)
                }
            }) {
                content
            }
        }
    }
}