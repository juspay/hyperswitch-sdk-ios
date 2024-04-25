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
                    if let paymentSheet = hyperViewModel.paymentSheet {
                        PaymentSheet.PaymentButton(paymentSheet: paymentSheet, onCompletion: hyperViewModel.onPaymentCompletion) {
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
}
