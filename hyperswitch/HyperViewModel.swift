//
//  HyperViewModel.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 25/04/24.
//

import SwiftUI

class HyperViewModel: ObservableObject {

    let backendUrl = URL(string: "http://localhost:5252")!

    @Published var hyperswitch: Hyperswitch?
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
                    let hyperswitchConfiguration = HyperswitchConfiguration(publishableKey: publishableKey, profileId: profileId)
                    let paymentSessionConfiguration = PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)

                    self.hyperswitch = Hyperswitch(configuration: hyperswitchConfiguration)
                    self.paymentSession = self.hyperswitch?.initPaymentSession(configuration: paymentSessionConfiguration)
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }

    func updatePaymentIntent() {
        self.paymentSession?.updateIntent(
            authorizationProvider: { completion in
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
                                throw NSError(
                                    domain: "API Error",
                                    code: 500,
                                    userInfo: [NSLocalizedDescriptionKey: "Missing required fields"]
                                )
                            }
                            completion(sdkAuthorization)
                        } catch {
                            completion("")  //needs to be handled
                        }
                    }
                }
            },
            completion: { result in
                switch result {
                case .success:
                    print("updateIntent: success")
                case .cancelled:
                    print("updateIntent: cancelled")
                case .failure(let error):
                    print("updateIntent: failed — \(error.localizedDescription)")
                }
            }
        )
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
