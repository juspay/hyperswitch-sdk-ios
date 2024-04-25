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
        private let paymentSheet: PaymentSheet
        private let content: Content
        
        @Environment(\.viewController) private var viewControllerHolder: UIViewController?
        
        /// Initializer for the PaymentButton.
        public init(
            paymentSheet: PaymentSheet,
            onCompletion: @escaping (PaymentSheetResult) -> Void,
            @ViewBuilder content: () -> Content
        ) {
            self.paymentSheet = paymentSheet
            self.paymentSheet.completion = onCompletion
            self.content = content()
        }
        
        /// The body of the PaymentButton view.
        public var body: some View {
            Button(action: {
                RNViewManager.sharedInstance.responseHandler = self.paymentSheet
                self.viewControllerHolder?.present(style: .overCurrentContext) {
                    PaymentSheetPresenter(paymentSheet: self.paymentSheet)
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
