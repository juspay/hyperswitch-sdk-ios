//
//  HyperNetworking.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

final class HyperNetworking {
    
    static func makeHttpRequest(
        urlString: String,
        method: String,
        headers: [String: String] = [:],
        body: String? = nil
    ) async throws -> [String: Any] {
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        if let body = body {
            request.httpBody = body.data(using: .utf8)
        }
        
        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                print("Invalid response type: \(urlResponse)")
                throw NetworkError.unknown
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: \(httpResponse.statusCode)")
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            
            do {
                if data.isEmpty {
                    return ["status": true , "message": "No data"]
                }
                
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                
                if let jsonDict = jsonObject as? [String: Any] {
                    return jsonDict
                } else {
                    return [:]
                }
            } catch {
                return [:]
            }
            
        } catch {
            throw NetworkError.networkFailure(error.localizedDescription)
        }
        
        
    }
    
    
    static func makePostRequest(_ urlString: String, _ body: String) async throws -> [String: Any] {
        return try await makeHttpRequest(
            urlString: urlString,
            method: "POST",
            headers: ["Content-Type": "application/json"],
            body: body
        )
    }
    
    static func makePostRequest(_ urlString: String, _ stringArray: [String]) async throws -> [String: Any] {
        let jsonData = try JSONSerialization.data(withJSONObject: stringArray, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return try await makePostRequest(urlString, jsonString)
    }
}

enum NetworkError: Error {
    case invalidURL
    case httpError(Int)
    case networkFailure(String)
    case unknown
    case decodingFailed
}
