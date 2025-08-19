//
//  HyperViewModel.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 25/04/24.
//

import SwiftUI

class AuthChallengeStatusReceiver: ChallengeStatusReceiver {
    func completed() {
        print("-- Challenge completed successfully")
    }
    
    func cancelled() {
        print("-- Challenge was cancelled")
    }
    
    func timedout() {
        print("-- Challenge timed out")
    }
    
    func protocolError() {
        print("-- Challenge protocol error occurred")
    }
    
    func runtimeError() {
        print("-- Challenge runtime error occurred")
    }
}

class HyperViewModel: ObservableObject {
    
    let backendUrl = URL(string: "http://localhost:5252")!
    
    @Published var paymentSession: PaymentSession?
    @Published var status: APIStatus = .loading
    internal var netceteraApiKey: String?
    private var transaction: Transaction?
    
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
                let ephemeralKeyJson = try await fetchData(from: "/create-ephemeral-key")
                guard let ephemeralKey = ephemeralKeyJson["ephemeralKey"] as? String else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing ephemeral key"])
                }
                
                let json = try await fetchData(from: "/create-payment-intent")
                guard let paymentIntentClientSecret = json["clientSecret"] as? String,
                      let publishableKey = json["publishableKey"] as? String
                else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                }
                
                DispatchQueue.main.async {
                    self.status = .success
                    self.paymentSession = PaymentSession(publishableKey: publishableKey)
                    
                    self.paymentSession?.initPaymentManagementSession(ephemeralKey: ephemeralKey, paymentIntentClientSecret: nil)
                    self.paymentSession?.initPaymentSession(paymentIntentClientSecret: paymentIntentClientSecret)
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    func fetchNetceteraSDKApiKey() {
        Task {
            do {
                let apiKey = try await fetchData(from: "/netcetera-sdk-api-key");
                guard let netceteraApiKey = apiKey["netceteraApiKey"] as? String else {
                    DispatchQueue.main.async {
                        self.netceteraApiKey = nil
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.netceteraApiKey = netceteraApiKey
                }
            } catch {
                DispatchQueue.main.async {
                    self.netceteraApiKey = nil
                }
            }
        }
    }
    
    func prepareAuthentication() {
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
                    self.paymentSession?.initAuthenticationSession(authIntentClientSecret: paymentIntentClientSecret, configuration: AuthenticationConfiguration(apiKey: self.netceteraApiKey, environment: "SANDBOX"))
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    func createTransaction() {
        self.transaction = self.paymentSession?.createTransaction(messageVersion: "2.3.1", directoryServerId: "A000000004", cardNetwork: "VISA")
    }
    
    func generateAuthRequest() {
        self.transaction?.getAuthenticationRequestParameters {
            params in
            print("-- recieved arreq params: ", params)
            // TODO: Handle the received authentication request parameters
            // and generate challenge params based on these aReqs using 3ds-server s2s calls
        }
    }
    
    func presentChallenge() {
        self.transaction?.doChallenge(
            challengeParameters: ChallengeParameters(
                threeDSServerTransactionID: "23c13695-8efc-4875-a322-0ccb13c3a8c4",
                acsTransactionID: "649c6f76-13e6-49e3-b14f-a30686b7f109",
                acsRefNumber: "3DS_LOA_ACS_201_13579",
                acsSignedContent: "acs-signed-content",
                threeDSRequestorAppURL: ""),
            challengeStatusReceiver: AuthChallengeStatusReceiver(),
            timeOut: 5)
    }
}
