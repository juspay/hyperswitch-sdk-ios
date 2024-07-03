//
//  HyperViewModel.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 25/04/24.
//

import SwiftUI

class HyperViewModel: ObservableObject {
    
    let backendUrl = URL(string: "http://localhost:5252/create-payment-intent")!
    
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    @Published var paymentSession: PaymentSession?
    
    func preparePaymentSheet() {
        
        var request = URLRequest(url: backendUrl)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any],
                  let paymentIntentClientSecret = json["clientSecret"] as? String,
                  let publishableKey = json["publishableKey"] as? String,
                  let self = self else {
                // Handle error
                return
            }
            
            APIClient.shared.publishableKey = publishableKey
            var configuration = PaymentSheet.Configuration()
            configuration.displaySavedPaymentMethods = true
            
            var appearance = PaymentSheet.Appearance()
            appearance.font.base = UIFont(name: "montserrat", size: UIFont.systemFontSize)!
            appearance.font.sizeScaleFactor = 1.0
            appearance.shadow = .disabled
            appearance.colors.background = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.00)
            appearance.colors.primary = UIColor(red: 0.55, green: 0.74, blue: 0.00, alpha: 1.00)
            appearance.primaryButton.cornerRadius = 32
            configuration.appearance = appearance
            configuration.primaryButtonLabel = "Purchase ($2.00)"
            configuration.savedPaymentSheetHeaderLabel = "Payment methods"
            configuration.paymentSheetHeaderLabel = "Select payment method"
                        
            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
                self.paymentSession = PaymentSession(publishableKey: publishableKey)
                self.paymentSession?.initPaymentSession(paymentIntentClientSecret: paymentIntentClientSecret)
            }
        })
        task.resume()
    }
    func onPaymentCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result
        }
    }
}
