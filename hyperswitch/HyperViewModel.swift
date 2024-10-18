//
//  HyperViewModel.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 25/04/24.
//

import SwiftUI

class HyperViewModel: ObservableObject {
    
    let backendUrl = URL(string: "http://localhost:5252")!
    
    @Published var paymentResult: PaymentSheetResult?
    @Published var paymentSession: PaymentSession?
    @Published var status: APIStatus = .loading
    
    enum APIStatus {
        case loading
        case success
        case failure(String)
    }
    
    private func fetchData(from endpoint: String) async throws -> [String: Any] {
        guard let url = URL(string: endpoint, relativeTo: backendUrl) else {
            throw NSError(domain: "Invalid URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Serialization Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unable to decode response"])
        }
        
        return json
    }
    
    func preparePaymentSheet() {
        Task {
            do {
                let json = try await fetchData(from: "/create-payment-intent")
                guard let paymentIntentClientSecret = json["clientSecret"] as? String,
                      let publishableKey = json["publishableKey"] as? String
                else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                }
                
                DispatchQueue.main.async {
                    self.status = .success
                    self.paymentSession = PaymentSession(publishableKey: publishableKey)
                    self.paymentSession?.initPaymentSession(paymentIntentClientSecret: paymentIntentClientSecret)
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    func preparePaymentMethodManagement() {
        Task {
            do {
                let paymentMethodsJson = try await fetchData(from: "/payment_methods")
                guard let publishableKey = paymentMethodsJson["publishableKey"] as? String,
                      let paymentManagementClientSecret = paymentMethodsJson["clientSecret"] as? String else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                }
                
                let ephemeralKeyJson = try await fetchData(from: "/create-ephemeral-key")
                guard let ephemeralKey = ephemeralKeyJson["ephemeralKey"] as? String else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing ephemeral key"])
                }
                
                DispatchQueue.main.async {
                    self.status = .success
                    self.paymentSession = PaymentSession(publishableKey: publishableKey)
                    self.paymentSession?.initPaymentManagementSession(ephemeralKey: ephemeralKey, paymentIntentClientSecret: paymentManagementClientSecret)
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result
        }
    }
}
