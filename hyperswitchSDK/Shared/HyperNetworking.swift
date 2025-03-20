//
//  HyperswitchNetworking.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

// MARK: HTTP Methods
enum HTTPMethod: String, Encodable {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case connect = "CONNECT"
    case options = "OPTIONS"
    case trace = "TRACE"
    case patch = "PATCH"
}

// MARK: HTTPClient
/// The protocol used to define the specifications necessary for a `HTTPClient`.
protocol HTTPClient {
    /// The host, conforming to RFC 1808.
    var host: String { get }

    /// The path, conforming to RFC 1808
    var path: String { get }

    /// API Endpoint
    var endpoint: String { get }

    /// The HTTP method used in the request.
    var method: HTTPMethod { get }

    /// The HTTP JSON request parameters.
    var jsonParameters: [String: Any]? { get }
    
    /// The HTTP Data request parameters.
    var bodyData: Data? { get }

    /// A dictionary containing all the HTTP header fields
    var headers: [String: String]? { get }
}

/// HTTPClient Errors
enum HTTPClientError: Error {
    case badURL
}

extension HTTPClient {
    /// The URL of the receiver.
    fileprivate var url: String {
        return host + path + endpoint
    }

    func request<T: Codable>(type: T.Type, completionHandler: @escaping (Result<T, Error>, Int) -> Void) {
        guard let url = URL(string: url) else {
            completionHandler(.failure(HTTPClientError.badURL), 400)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        if let parameters = jsonParameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                completionHandler(.failure(error), 400)
                return
            }
        } else if let bodyData = bodyData {
            request.httpBody = bodyData
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0 // 10 seconds
        configuration.timeoutIntervalForResource = 10.0 // 10 seconds
        let session = URLSession(configuration: configuration)
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            var responseCode = 400
            if let httpResponse = response as? HTTPURLResponse {
                responseCode = httpResponse.statusCode
            }
            if let error = error {
                completionHandler(.failure(error), responseCode)
                return
            }

            if let data = data {
                do {
                    if T.self == Data.self {
                        completionHandler(.success(data as! T), responseCode)
                    } else {
                        completionHandler(.success(try JSONDecoder().decode(type, from: data)), responseCode)
                    }
                } catch {
                    completionHandler(.failure(error), responseCode)
                    return
                }
            }
        })

        dataTask.resume()
    }
}

class HTTPRequestService: HTTPClient {

    let host: String
    let path: String
    let endpoint: String
    let method: HTTPMethod

    var jsonParameters: [String : Any]?
    var bodyData: Data?
    var headers: [String : String]?

    init(host: String, path: String, endpoint: String, method: HTTPMethod, jsonParameters: [String : Any]? = nil, bodyData: Data? = nil, headers: [String : String]? = nil) {
        self.host = host
        self.path = path
        self.endpoint = endpoint
        self.method = method
        self.jsonParameters = jsonParameters
        self.bodyData = bodyData
        self.headers = headers
    }

    func getDictionary() -> [String: Any] {
        return ["host": host, "path": path, "endpoint": endpoint, "method": method.rawValue,"jsonParameters": jsonParameters ?? "nil", "headers": headers ?? "nil"]
    }
}
