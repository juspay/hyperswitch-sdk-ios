//
//  ClickToPayViewModel.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 31/10/25.
//

import SwiftUI

class ClickToPayViewModel: ObservableObject {

    let backendUrl = URL(string: "http://localhost:5252")!

    @Published var authenticationSession: AuthenticationSession?
    @Published var status: APIStatus = .loading
    @Published var cardsStatus: String = ""
    @Published var recognizedCards: [RecognizedCard] = []

    enum APIStatus {
        case loading
        case success
        case failure(String)
    }

    func prepareAuthenticationSession() {
        Task {
            do {
                let json = try await NetworkUtility.postData(to: "/create-authentication", body: [:], baseUrl: backendUrl)
                guard let paymentIntentClientSecret = json["clientSecret"] as? String,
                      let publishableKey = json["publishableKey"] as? String,
                      let profileId = json["profileId"] as? String,
                      let authenticationId = json["authenticationId"] as? String,
                      let merchantId = json["merchantId"] as? String

                else {
                    throw NSError(domain: "API Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
                }

                DispatchQueue.main.async {
                    self.status = .success
                    self.authenticationSession = AuthenticationSession(publishableKey: publishableKey)
                    self.authenticationSession?.initAuthenticationSession(clientSecret: paymentIntentClientSecret, profileId: profileId, authenticationId: authenticationId, merchantId: merchantId)

                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .failure(error.localizedDescription)
                }
            }
        }
    }
}
