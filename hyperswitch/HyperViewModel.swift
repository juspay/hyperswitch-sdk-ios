//
//  HyperViewModel.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 25/04/24.
//

import SwiftUI

class AuthChallengeStatusReceiver: ChallengeStatusReceiver {
    func completed(_ completionEvent: CompletionEvent) {
        print("-- Challenge completed successfully")
    }
    
    func cancelled() {
        print("-- Challenge was cancelled")
    }
    
    func timedout() {
        print("-- Challenge timed out")
    }
    
    func protocolError(_ protocolErrorEvent: ProtocolErrorEvent) {
        print("-- Challenge protocol error occurred")
    }
    
    func runtimeError(_ runtimeErrorEvent: RuntimeErrorEvent) {
        print("-- Challenge runtime error occurred")
    }
}

class HyperViewModel: ObservableObject {
    
    let backendUrl = URL(string: "http://localhost:5252")!
    
    @Published var paymentSession: PaymentSession?
    @Published var authSession: AuthenticationSession?
    @Published var status: APIStatus = .loading
    internal var netceteraApiKey: String?
    private var transaction: Transaction?
    private var challengeParams: ChallengeParameters?
    private var authenticationSessionId: String?
    
    enum APIStatus {
        case loading
        case success
        case failure(String)
    }
    
    private func fetchData(from endpoint: String, baseUrl: URL? = nil) async throws -> [String: Any] {
        guard let url = URL(string: endpoint, relativeTo: baseUrl ?? backendUrl) else {
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
    
    private func postData(to endpoint: String, body: [String: Any], baseUrl: URL? = nil, headers: [String: String]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: endpoint, relativeTo: baseUrl ?? backendUrl) else {
            throw NSError(domain: "Invalid URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("accept-encoding", forHTTPHeaderField: "gzip")
        request.setValue("connection", forHTTPHeaderField: "Keep-Alive")
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        } catch {
            throw NSError(domain: "Serialization Error", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize request body"])
        }
        
        print("-- request: ", request)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        //        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        //            throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        //        }
        
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
                    self.authSession = AuthenticationSession(publishableKey: publishableKey)
                    self.authSession?.initThreeDsSession(authIntentClientSecret: paymentIntentClientSecret, configuration: AuthenticationConfiguration(apiKey: self.netceteraApiKey)) {
                        status in
                        switch status {
                            case .success:
                            print("-- Authentication successful")
                        case .failure(let error):
                            print("-- Authentication failed: \(error)")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    func createAuthSession() {
        Task {
            do {
                let hyperswitchServerUrl = "https://sandbox.hyperswitch.io"
                
                guard let hyperswitchBaseUrl = URL(string: hyperswitchServerUrl) else {
                    throw NSError(domain: "Invalid URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Hyperswitch server URL"])
                }
                
                let headers = [
                    "X-Profile-Id": "",
                    "api-key": ""
                ]
                
                let requestBody: [String: Any] = [
                    "amount": 1050,
                    "currency": "EUR",
                    "acquirer_details": [
                        "acquirer_merchant_id": "12134",
                        "acquirer_bin": "438309",
                        "merchant_country_code": "004"
                    ],
                    "authentication_connector": "juspaythreedsserver"
                ]
                
                let json = try await postData(to: "/authentication", body: requestBody, baseUrl: hyperswitchBaseUrl, headers: headers)
                
                if let error = json["error"] as? [String: Any] {
                    let errorMessage = error["message"] as? String ?? "Something went wrong."
                    print("Error - ", error)
                    throw NSError(domain: "Authentication Error", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
                
                guard let authId = json["authentication_id"] as? String else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing authentication_id in response"])
                }
                
                DispatchQueue.main.async {
                    self.status = .success
                    self.authenticationSessionId = authId
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    func createTransaction() {
        self.transaction = self.authSession?.createTransaction(messageVersion: "2.3.1", directoryServerId: "A000000004", cardNetwork: "MASTERCARD")
        
        self.createAuthSession()
    }
    
    func fetchChallengeParams(_ aReqs: AuthenticationRequestParameters) {
        Task {
            do {
                let hyperswitchServerUrl = "https://sandbox.hyperswitch.io"
                
                guard let hyperswitchBaseUrl = URL(string: hyperswitchServerUrl) else {
                    throw NSError(domain: "Invalid URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Hyperswitch server URL"])
                }
                
                let headers = [
                    "Content-Type": "application/json",
                    "api-key": ""
                ]
                
                var ephemeralPublicKey: Any = aReqs.sdkEphemeralPublicKey
                
                if let ephemeralKeyString = aReqs.sdkEphemeralPublicKey as? String {
                    if let ephemeralKeyData = ephemeralKeyString.data(using: .utf8),
                       let ephemeralKeyDict = try? JSONSerialization.jsonObject(with: ephemeralKeyData, options: []) as? [String: Any] {
                        var stringifiedDict: [String: String] = [:]
                        for (key, value) in ephemeralKeyDict {
                            stringifiedDict[key] = String(describing: value)
                        }
                        ephemeralPublicKey = stringifiedDict
                    }
                }
                
                let requestBody: [String: Any] = [
                    "device_channel": "APP",
                    "threeds_method_comp_ind": "N",
                    "sdk_information": [
                        "sdk_app_id": aReqs.sdkAppID,
                        "sdk_enc_data": aReqs.deviceData,
                        "sdk_ephem_pub_key": ephemeralPublicKey,
                        "sdk_trans_id": aReqs.sdkTransactionID,
                        "sdk_reference_number": aReqs.sdkReferenceNumber,
                        "sdk_max_timeout": 15
                    ]
                ]
                
                let bodyData = try? JSONSerialization.data(withJSONObject: requestBody)
                
                let endpoint = "/authentication/\(String(describing: self.authenticationSessionId ?? ""))/authenticate"
                let json = try await postData(to: endpoint, body: requestBody, baseUrl: hyperswitchBaseUrl, headers: headers)
                
                print("-- challenge params json: ", json)
                
                if let threeDSServerTransactionId = json["three_ds_server_transaction_id"] as? String,
                   let acsTransactionId = json["acs_trans_id"] as? String,
                   let acsRefNumber = json["acs_reference_number"] as? String,
                   let acsSignedContent = json["acs_signed_content"] as? String,
                   let threeDSRequestorAppURL = json["three_ds_requestor_url"] as? String?
                {
                    self.challengeParams = ChallengeParameters(threeDSServerTransactionId: threeDSServerTransactionId, acsTransactionId: acsTransactionId, acsRefNumber: acsRefNumber, acsSignedContent: acsSignedContent, threeDSRequestorAppURL: threeDSRequestorAppURL)
                }
            } catch {
                print("Failed to fetch challenge params: \(error)")
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
    
    func generateAuthRequest() {
        self.checkEligibility() {
            status in
            switch status {
                case .success:
                    self.transaction?.getAuthenticationRequestParameters { params in
                        // Handle the received authentication request parameters
                        // and generate challenge params based on these aReqs using 3ds-server s2s calls
                        self.fetchChallengeParams(params)
                    }
                case .failure(let error):
                    print("-- Eligibility check failed: ", error)
                default:
                    print("-- Eligibility check failed.")
            }
        }
    }
    
    func presentChallenge() {
        if let challengeParams = self.challengeParams {
            DispatchQueue.main.async{
                self.transaction?.doChallenge(
                    challengeParameters: challengeParams,
                    challengeStatusReceiver: AuthChallengeStatusReceiver(),
                    timeOut: 5)
            }
        } else {
            print("Error: No challenge params to present.")
        }
    }
    
    func checkEligibility(completion: @escaping ((_ status: APIStatus) -> Void)) {
        Task { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.failure("Object deallocated"))
                }
                return
            }
            
            do {
                let hyperswitchServerUrl = "https://sandbox.hyperswitch.io"
                
                guard let hyperswitchBaseUrl = URL(string: hyperswitchServerUrl) else {
                    let error = NSError(domain: "Invalid URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Hyperswitch server URL"])
                    DispatchQueue.main.async {
                        self.status = .failure(error.localizedDescription)
                        completion(.failure(error.localizedDescription))
                    }
                    return
                }
                
                let headers = [
                    "Content-Type": "application/json",
                    "api-key": ""
                ]
                
                let requestBody: [String: Any] = [
                    "payment_method": "card",
                    "payment_method_data": [
                        "card": [
                            "card_number": "5306889942833340",
                            "card_exp_month": "10",
                            "card_exp_year": "24",
                            "card_holder_name": "joseph Doe",
                            "card_cvc": "123"
                        ]
                    ],
                    "billing": [
                        "address": [
                            "line1": "1467",
                            "line2": "Harrison Street",
                            "line3": "Harrison Street",
                            "city": "San Fransico",
                            "state": "CA",
                            "zip": "94122",
                            "country": "US",
                            "first_name": "PiX"
                        ],
                        "phone": [
                            "number": "123456789",
                            "country_code": "12"
                        ]
                    ],
                    "shipping": [
                        "address": [
                            "line1": "1467",
                            "line2": "Harrison Street",
                            "line3": "Harrison Street",
                            "city": "San Fransico",
                            "state": "California",
                            "zip": "94122",
                            "country": "US",
                            "first_name": "PiX"
                        ],
                        "phone": [
                            "number": "123456789",
                            "country_code": "12"
                        ]
                    ],
                    "email": "sahkasssslplanet@gmail.com",
                    "browser_information": [
                        "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36",
                        "accept_header": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
                        "language": "nl-NL",
                        "color_depth": 24,
                        "screen_height": 723,
                        "screen_width": 1536,
                        "time_zone": 0,
                        "java_enabled": true,
                        "java_script_enabled": true,
                        "ip_address": "115.99.183.2"
                    ]
                ]
                
                guard let authSessionId = self.authenticationSessionId else {
                    let error = NSError(domain: "Missing Authentication Session", code: 400, userInfo: [NSLocalizedDescriptionKey: "Authentication session ID is required"])
                    DispatchQueue.main.async {
                        self.status = .failure(error.localizedDescription)
                        completion(.failure(error.localizedDescription))
                    }
                    return
                }
                
                let endpoint = "/authentication/\(authSessionId)/eligibility"
                
                let json = try await self.postData(to: endpoint, body: requestBody, baseUrl: hyperswitchBaseUrl, headers: headers)
                
                // Check for errors in response
                if let error = json["error"] as? [String: Any] {
                    let errorMessage = error["message"] as? String ?? "Eligibility check failed."
                    print("Eligibility Error - ", error)
                    let nsError = NSError(domain: "Eligibility Error", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    DispatchQueue.main.async {
                        self.status = .failure(nsError.localizedDescription)
                        completion(.failure(nsError.localizedDescription))
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.status = .success
                    completion(.success)
                }
                
            } catch {
                print("Failed to check eligibility: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                    completion(.failure(error.localizedDescription))
                }
            }
        }
    }
}
