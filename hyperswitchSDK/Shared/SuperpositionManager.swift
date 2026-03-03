//
//  SuperpositionManager.swift
//  hyperswitch
//
//  Created on 23/02/26.
//

import Foundation

final class SuperpositionManager {
    static let shared = SuperpositionManager()

    private var configUrl: String?
    private var publishableKey: String?
    private(set) var cachedConfig: String? // raw JSON string

    private init() {}

    func initialise(configUrl: String, publishableKey: String) {
        self.configUrl = configUrl
        self.publishableKey = publishableKey
        self.cachedConfig = nil
    }

    func fetchConfig() {
        guard let urlString = configUrl,
              let url = URL(string: urlString),
              let scheme = url.scheme,
              let host = url.host
        else { return }

        let port = url.port.map { ":\($0)" } ?? ""
        let endpoint = url.path.isEmpty ? "/" : url.path

        let service = HTTPRequestService(
            host: "\(scheme)://\(host)\(port)",
            path: "",
            endpoint: endpoint,
            method: .get,
            headers: ["Content-Type": "application/json", "api-key": publishableKey ?? ""]
        )

        service.request(type: Data.self) { result, statusCode in
            switch result {
            case .success(let data):
                guard (200...299).contains(statusCode),
                      let jsonString = String(data: data, encoding: .utf8),
                      !jsonString.isEmpty else {
                    print("[SuperpositionManager] Fetch skipped: non-2xx or empty response")
                    return
                }
                self.cachedConfig = jsonString
                print("[SuperpositionManager] Config fetched successfully")
            case .failure(let error):
                print("[SuperpositionManager] Fetch failed: \(error.localizedDescription)")
            }
        }
    }
}
