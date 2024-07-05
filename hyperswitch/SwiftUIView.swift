//
//  SwiftUIView.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 25/04/23.
//

import SwiftUI

struct SwiftUIView: View {
    @ObservedObject var hyperViewModel = HyperViewModel()
    
    var body: some View {
        ZStack(alignment: .top){
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            LazyVStack(spacing: 94) {
                Button{hyperViewModel.preparePaymentSheet()}
            label: {
                Text("Reload Client Secret")
            }.padding(.vertical, 11)
                    .padding(.horizontal, 58)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10.0)
                Spacer()
                if let paymentSession = hyperViewModel.paymentSession {
                    PaymentSheet.PaymentButton(paymentSession: paymentSession, configuration: SwiftUIView.setupConfiguration()
                                               , onCompletion: hyperViewModel.onPaymentCompletion) {
                        Text("Launch Payment Sheet")
                            .padding(.vertical, 11)
                            .padding(.horizontal, 58)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10.0)
                    }
                    
                    if let result = hyperViewModel.paymentResult {
                        switch result {
                        case .completed:
                            Text("Payment complete")
                                .padding()
                        case .failed(let error as NSError):
                            Text("Payment failed: \(error)")
                                .padding()
                        case .canceled:
                            Text("Payment canceled.")
                                .padding()
                        }
                    }
                }
            }.onAppear { hyperViewModel.preparePaymentSheet() }
                .padding(.top, 80)
        }
    }
    static func setupConfiguration() -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.primaryButtonLabel = "Purchase ($2.00)"
        configuration.savedPaymentSheetHeaderLabel = "Payment methods"
        configuration.paymentSheetHeaderLabel = "Select payment method"
        configuration.displaySavedPaymentMethods = true
        
        var appearance = PaymentSheet.Appearance()
        appearance.font.base = UIFont(name: "montserrat", size: UIFont.systemFontSize)
        appearance.font.sizeScaleFactor = 1.0
        appearance.shadow = .disabled
        appearance.colors.background = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.00)
        appearance.colors.primary = UIColor(red: 0.55, green: 0.74, blue: 0.00, alpha: 1.00)
        appearance.primaryButton.cornerRadius = 32
        configuration.appearance = appearance
        
        return configuration
    }
}
