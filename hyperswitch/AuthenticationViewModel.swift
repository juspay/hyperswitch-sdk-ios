//
//  AuthenticationViewModel.swift
//  hyperswitch
//
//  Created by Shivam Nan on 10/10/25.
//

import Foundation

class AuthenticationViewModel: ObservableObject {
    
    let localBackendUrl = URL(string: "http://localhost:5252")!
    
    @Published var publishableKey: String?
    @Published var clientSecret: String?
    @Published var authenticationSessionId: String?
    @Published var errorMessage: String?
    @Published var challengeParams: ChallengeParameters?
    
    func prepareAuthentication() {
        Task {
            do {
                let json = try await NetworkUtility.fetchData(from: "/create-auth-intent", baseUrl: localBackendUrl)
                guard let paymentIntentClientSecret = json["clientSecret"] as? String,
                      let publishableKey = json["publishableKey"] as? String
                else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                }
                
                DispatchQueue.main.async {
                    self.publishableKey = publishableKey
                    self.clientSecret = paymentIntentClientSecret
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func createAuthSession(completion: @escaping (String?, Error?) -> Void) {
        Task {
            do {
                
                let json = try await NetworkUtility.fetchData(from: "/authentication", baseUrl: localBackendUrl)
                
                if let error = json["error"] as? [String: Any] {
                    let errorMessage = error["message"] as? String ?? "Something went wrong."
                    throw NSError(domain: "Authentication Error", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
                
                guard let authId = json["authentication_id"] as? String else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing authentication_id in response"])
                }
                
                DispatchQueue.main.async {
                    self.authenticationSessionId = authId
                    completion(authId, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(nil, error)
                }
            }
        }
    }
    
    func checkEligibility(completion: @escaping (Error?) -> Void) {
        Task { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(NSError(domain: "Object deallocated", code: 500))
                }
                return
            }
            
            do {
                guard let authSessionId = self.authenticationSessionId else {
                    let error = NSError(domain: "Missing Authentication Session", code: 400, userInfo: [NSLocalizedDescriptionKey: "Authentication session ID is required"])
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        completion(error)
                    }
                    return
                }
                
                let endpoint = "/authentication/\(authSessionId)/eligibility"
                
                let json = try await NetworkUtility.fetchData(from: endpoint, baseUrl: localBackendUrl)
                
                // Check for errors in response
                if let error = json["error"] as? [String: Any] {
                    let errorMessage = error["message"] as? String ?? "Eligibility check failed."
                    let nsError = NSError(domain: "Eligibility Error", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    DispatchQueue.main.async {
                        self.errorMessage = nsError.localizedDescription
                        completion(nsError)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(error)
                }
            }
        }
    }
    
    func fetchChallengeParams(_ aReqs: AuthenticationRequestParameters, completion: @escaping (ChallengeParameters?, Error?) -> Void) {
        Task {
            do {
                
                var ephemeralPublicKey: Any = aReqs.sdkEphemeralPublicKey
                
                if let ephemeralKeyString = aReqs.sdkEphemeralPublicKey as? String {
                    if let ephemeralKeyData = ephemeralKeyString.data(using: .utf8),
                       let ephemeralKeyDict = try? JSONSerialization.jsonObject(with: ephemeralKeyData, options: []) as? [String: Any] {
                        var stringifiedDict: [String: String] = [:]
                        for (key, value) in ephemeralKeyDict {
                            let _key = key.prefix(1).uppercased() + key.dropFirst()
                            stringifiedDict[_key] = String(describing: value)
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
                
                let endpoint = "/authentication/\(String(describing: self.authenticationSessionId ?? ""))/authenticate"
                let json = try await NetworkUtility.postData(to: endpoint, body: requestBody, baseUrl: localBackendUrl)
                
                if let threeDSServerTransactionId = json["three_ds_server_transaction_id"] as? String,
                   let acsTransactionId = json["acs_trans_id"] as? String,
                   let acsRefNumber = json["acs_reference_number"] as? String,
                   let acsSignedContent = json["acs_signed_content"] as? String,
                   let threeDSRequestorAppURL = json["three_ds_requestor_url"] as? String?
                {
                    let challengeParameters = ChallengeParameters(
                        threeDSServerTransactionID: threeDSServerTransactionId,
                        acsTransactionID: acsTransactionId,
                        acsRefNumber: acsRefNumber,
                        acsSignedContent: acsSignedContent,
                        threeDSRequestorAppURL: threeDSRequestorAppURL
                    )
                    
                    DispatchQueue.main.async {
                        self.challengeParams = challengeParameters
                        completion(challengeParameters, nil)
                    }
                } else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required challenge parameters in response"])
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    completion(nil, error)
                }
            }
        }
    }
}
