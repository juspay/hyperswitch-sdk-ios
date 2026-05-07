//
//  HyperViewModel.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 25/04/24.
//

import SwiftUI

class HyperViewModel: ObservableObject {

    let backendUrl = URL(string: "http://localhost:5252")!

    @Published var paymentSession: PaymentSession?
    @Published var status: APIStatus = .loading
    internal var netceteraApiKey: String?
    internal var paymentId: String?

    enum APIStatus {
        case loading
        case success
        case failure(String)
    }

    func preparePaymentSheet() {
        Task {
            do {
                let json = try await NetworkUtility.fetchData(from: "/create-payment-intent", baseUrl: backendUrl)
                guard let sdkAuthorization = json["sdkAuthorization"] as? String,
                    let publishableKey = json["publishableKey"] as? String,
                    let profileId = json["profileId"] as? String
                else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                }
                self.paymentId = json["paymentId"] as? String

                DispatchQueue.main.async {
                    self.status = .success
                    self.paymentSession = PaymentSession(publishableKey: publishableKey, profileId: profileId)
                    self.paymentSession?.initPaymentSession(sdkAuthorization: sdkAuthorization)
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }

    func updatePaymentIntent() {
        self.paymentSession?.updateIntent { completion in
            if let paymentId = self.paymentId {
                Task {
                    do {
                        let json = try await NetworkUtility.postData(
                            to: "/update-payment",
                            body: ["paymentId": paymentId],
                            baseUrl: self.backendUrl
                        )
                        guard let sdkAuthorization = json["sdkAuthorization"] as? String
                        else {
                            throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                        }
                        completion(sdkAuthorization)
                    } catch {
                        completion("")  //needs to be handled
                    }
                }
            }
        }
    }

    func preparePaymentMethodManagement() {
        Task {
            do {
                let ephemeralKeyJson = try await NetworkUtility.fetchData(from: "/create-ephemeral-key", baseUrl: backendUrl)
                guard let ephemeralKey = ephemeralKeyJson["ephemeralKey"] as? String else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing ephemeral key"])
                }

                let json = try await NetworkUtility.fetchData(from: "/create-payment-intent", baseUrl: backendUrl)
                guard let sdkAuthorization = json["sdkAuthorization"] as? String,
                    let publishableKey = json["publishableKey"] as? String,
                    let profileId = json["profileId"] as? String
                else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                }

                DispatchQueue.main.async {
                    self.status = .success
                    self.paymentSession = PaymentSession(publishableKey: publishableKey, profileId: profileId)

                    self.paymentSession?.initPaymentManagementSession(ephemeralKey: ephemeralKey, sdkAuthorization: nil)
                    self.paymentSession?.initPaymentSession(sdkAuthorization: sdkAuthorization)
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
                let apiKey = try await NetworkUtility.fetchData(from: "/netcetera-sdk-api-key", baseUrl: backendUrl)
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
}
