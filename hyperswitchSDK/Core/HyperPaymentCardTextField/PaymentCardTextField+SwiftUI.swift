//
//  PaymentCardTextField+SwiftUI.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 10/05/23.
//

import SwiftUI
import Combine

extension PaymentCardTextField {
    
    @available(iOS 13.0, *)
    public struct Representable: UIViewRepresentable {
        @Binding var paymentMethodParams: PaymentMethodParams?
        
        public typealias UIViewType = PaymentCardTextField
        
        public init(paymentMethodParams: Binding<PaymentMethodParams?>) {
            _paymentMethodParams = paymentMethodParams
        }
        
        public func makeUIView(context: Context) -> PaymentCardTextField {
            let cardTextField = PaymentCardTextField()
            cardTextField.setContentHuggingPriority(.defaultHigh, for: .vertical)
            return cardTextField
        }
        
        public func updateUIView(_ uiView: PaymentCardTextField, context: Context) {
            
        }
    }
}
@available(iOS 13.0, *)
extension View {
    public func paymentConfirmationSheet(
        isConfirmingPayment: Binding<Bool>,
        paymentIntentParams: PaymentIntentParams,
        onCompletion: @escaping PaymentHandler.PaymentHandlerActionPaymentIntentCompletionBlock
    ) -> some View {
        self.modifier(PaymentConfirmationModifier(isConfirmingPayment: isConfirmingPayment, paymentIntentParams: paymentIntentParams, onCompletion: onCompletion))
    }
}
@available(iOS 13.0, *)
struct PaymentConfirmationModifier: ViewModifier {
    @Binding var isConfirmingPayment: Bool
    let paymentIntentParams: PaymentIntentParams
    let onCompletion: PaymentHandler.PaymentHandlerActionPaymentIntentCompletionBlock
    
    func body(content: Content) -> some View {
        content
            .onReceive(Just(isConfirmingPayment)) { newValue in
                if newValue {
                    DispatchQueue.main.async {
                        PaymentHandler.sharedHandler.confirmPayment(paymentIntentParams, with: UIViewController(), completion: onCompletion)
                        isConfirmingPayment = false
                    }
                }
            }
    }
}
