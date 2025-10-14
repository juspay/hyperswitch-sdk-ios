//
//  NetworkUtils.swift
//  hyperswitch
//
//  Created by Shivam Nan on 10/10/25.
//

import Foundation

class NetworkUtility {
    
    static func fetchData(from endpoint: String, baseUrl: URL) async throws -> [String: Any] {
        guard let url = URL(string: endpoint, relativeTo: baseUrl) else {
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
    
    static func postData(to endpoint: String, body: [String: Any], baseUrl: URL, headers: [String: String]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: endpoint, relativeTo: baseUrl) else {
            throw NSError(domain: "Invalid URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Serialization Error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unable to decode response"])
        }
        
        return json
    }
}

