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
    // PMM is demo-app-only: the App Clip target compiles this file too but has
    // none of the PMM SDK sources, so the reference is guarded out there.
    #if !APPCLIP
    @Published var paymentMethodManagement: PaymentMethodManagement?
    #endif
    @Published var status: APIStatus = .loading
    internal var netceteraApiKey: String?
    internal var paymentId: String?

    enum APIStatus {
        case loading
        case success
        case failure(String)
        case info(String)
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

                let hyperswitchConfiguration = HyperswitchConfiguration(publishableKey: publishableKey, profileId: profileId)
                let paymentSessionConfiguration = PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)

                let hyperswitch = Hyperswitch(configuration: hyperswitchConfiguration)
                let paymentSession = try await hyperswitch.initPaymentSession(configuration: paymentSessionConfiguration)

                DispatchQueue.main.async {
                    self.hyperswitch = hyperswitch
                    self.paymentSession = paymentSession
                    self.status = .success
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
                let text: String
                switch result {
                case .success:
                    text = "updateIntent → success"
                case .cancelled:
                    text = "updateIntent → cancelled"
                case .failure(let error):
                    text = "updateIntent → failed: \((error as NSError).domain) \(error.localizedDescription)"
                }
                print(text)
                DispatchQueue.main.async { self.status = .info(text) }
            }
        )
    }

    #if !APPCLIP
    func preparePaymentMethodManagement() {
        Task {
            do {
                let json = try await NetworkUtility.postData(
                    to: "/create-payment-method-session",
                    body: ["storage_type": "persistent", "keep_alive": true],
                    baseUrl: backendUrl
                )
                guard let sdkAuthorization = json["sdkAuthorization"] as? String,
                    let publishableKey = json["publishableKey"] as? String,
                    let profileId = json["profileId"] as? String
                else {
                    let serverMessage = (json["error"] as? [String: Any])?["message"] as? String
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: serverMessage ?? "Missing required fields"])
                }

                let hyperswitchConfiguration = HyperswitchConfiguration(publishableKey: publishableKey, profileId: profileId)
                let hyperswitch = Hyperswitch(configuration: hyperswitchConfiguration)
                let paymentMethodManagement = hyperswitch.initPaymentMethodManagement(
                    configuration: PaymentMethodManagementConfiguration(sdkAuthorization: sdkAuthorization)
                )

                DispatchQueue.main.async {
                    self.hyperswitch = hyperswitch
                    self.paymentMethodManagement = paymentMethodManagement
                    self.status = .success
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
    #endif

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
