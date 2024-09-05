//
//  HyperViewModel.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 25/04/24.
//

import SwiftUI

class HyperViewModel: ObservableObject {
    
    let backendUrl = URL(string: "http://localhost:5252/create-payment-intent")!
    
    @Published var paymentResult: PaymentSheetResult?
    @Published var paymentSession: PaymentSession?
    @Published var status: APIStatus = .loading
    
    enum APIStatus {
        case loading
        case success
        case failure(String)
    }
    
    func preparePaymentSheet() {
        
        var request = URLRequest(url: backendUrl)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self?.status = .failure(error.localizedDescription)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self?.status = .failure("API Status Failed")
                }
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String : Any],
                  let paymentIntentClientSecret = json["clientSecret"] as? String,
                  let publishableKey = json["publishableKey"] as? String,
                  let self = self else {
                DispatchQueue.main.async {
                    self?.status = .failure("API Serialization/Decode failure")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.status = .success
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
