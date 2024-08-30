//
//  PaymentSheetView+SwiftUI.swift
//  Hyperswitch
//
//  Created by Balaganesh on 09/12/22.
//

import Foundation
import SwiftUI
import React

/// Extension on the PaymentSheet class to provide a SwiftUI integration for presenting the payment sheet.
extension PaymentSheet {
    
    /// A SwiftUI View struct that represents a button for presenting the payment sheet.
    @available(iOS 13.0, *)
    public struct PaymentButton<Content: View>: View {
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
                    let paymentSheet = PaymentSheet(paymentIntentClientSecret: PaymentSession.paymentIntentClientSecret ?? "", configuration: configuration)
                    paymentSheet.present(from: vc, completion: completion)
                }
            }) {
                content
            }
        }
    }
    
    /// A UIViewRepresentable struct that handles presenting the payment sheet view.
    @available(iOS 13.0, *)
    struct PaymentSheetPresenter: UIViewRepresentable {
        
        private let paymentSheet: PaymentSheet
        
        init(paymentSheet: PaymentSheet) {
            self.paymentSheet = paymentSheet
        }
        
        typealias UIViewType = RCTRootView
        
        func makeUIView(context: Context) -> RCTRootView {
            
            return self.paymentSheet.getRootView()
        }
        
        func updateUIView(_ uiView: RCTRootView, context: Context) {
            
        }
    }
}
