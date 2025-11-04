//
//  ClickToPaySession.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 31/10/25.
//

import Foundation
@preconcurrency import WebKit

public class ClickToPaySession: NSObject, WKNavigationDelegate, WKUIDelegate {

    private let publishableKey: String
    private let customBackendUrl: String?
    private let customLogUrl: String?
    private let customParams: [String: Any]?

    private var webView: WKWebView?
    private var pendingRequests: [String: CheckedContinuation<String, Error>] = [:]
    private var pendingVoidRequests: [String: CheckedContinuation<Void, Error>] = [:]
    private let pendingRequestsQueue = DispatchQueue(label: "com.hyperswitch.c2p.pendingRequests")
    private var isSDKInitialized = false
    private var sdkInitContinuation: CheckedContinuation<Void, Never>?

    public init(
        publishableKey: String,
        customBackendUrl: String? = nil,
        customLogUrl: String? = nil,
        customParams: [String: Any]? = nil
    ) {
        self.publishableKey = publishableKey
        self.customBackendUrl = customBackendUrl
        self.customLogUrl = customLogUrl
        self.customParams = customParams

        super.init()

        DispatchQueue.main.async { [weak self] in
            self?.setupWebView()
        }
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "HSInterface")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.isHidden = false  // Keep visible to prevent freezing
        webView?.alpha = 0.01
        webView?.navigationDelegate = self
        webView?.uiDelegate = self

        if let webView = webView {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            windowScene?.windows.forEach { window in
                window.addSubview(webView)
            }
        }

        let backendUrlParam = customBackendUrl.map { "customBackendUrl: \"\($0)\"," } ?? ""
        let logUrlParam = customLogUrl.map { "customLogUrl: \"\($0)\"," } ?? ""

        let baseHtml = """
            <!DOCTYPE html>
            <html lang="en">
              <head>
                <script>
                  function handleScriptError() {
                      console.error('Failed to load HyperLoader.js');
                      window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                          "sdkInitialised": false,
                          "error": "Script load failed"
                      }));
                  }
        
                  async function initHyper() {
                      try {
                          if (typeof Hyper === 'undefined') {
                              window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                  "sdkInitialised": false,
                                  "error": "Hyper is not defined"
                              }));
                              return;
                          }
        
                          window.hyperInstance = Hyper.init("\(publishableKey)", {
                              \(backendUrlParam)
                              \(logUrlParam)
                          });
        
                          window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                              "sdkInitialised": true
                          }));
                      } catch (error) {
                          console.error('Hyper initialization failed:', error);
                          window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                              "sdkInitialised": false,
                              "error": error.message
                          }));
                      }
                  }
                </script>
                <script
                  src="https://beta.hyperswitch.io/v2/HyperLoader.js"
                  onload="initHyper()"
                  onerror="handleScriptError()"
                  async="true"
                ></script>
              </head>
              <body></body>
            </html>
        """
        webView?.loadHTMLString(baseHtml, baseURL: URL(string: "https://sandbox.src.mastercard.com"))
    }


    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        if navigationAction.targetFrame == nil {

            configuration.userContentController.removeScriptMessageHandler(forName: "closePopupWebView")
            configuration.userContentController.add(self, name: "closePopupWebView")
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

            let webView = WKWebView(frame: .zero, configuration: configuration)

            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.backgroundColor = .clear
            webView.isOpaque = true
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            webView.scrollView.contentInsetAdjustmentBehavior = .never

            webView.translatesAutoresizingMaskIntoConstraints = false

            if let topVC = getTopViewController(),
               let view = topVC.view {
                view.addSubview(webView)
                NSLayoutConstraint.activate([
                    webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                    webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                    webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                    webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
            }

            return webView
        }
        return nil
    }

    public func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
    }

    public func initClickToPaySession(
        clientSecret: String,
        profileId: String,
        authenticationId: String,
        merchantId: String,
        request3DSAuthentication: Bool
    ) async throws {
        if !isSDKInitialized {
            await withCheckedContinuation { continuation in
                pendingRequestsQueue.async { [weak self] in
                    if self?.isSDKInitialized == true {
                        continuation.resume()
                    } else {
                        self?.sdkInitContinuation = continuation
                    }
                }
            }
        }

        let requestId = UUID().uuidString

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            pendingRequestsQueue.async { [weak self] in
                self?.pendingVoidRequests[requestId] = continuation
            }

            let jsCode = """
                (async function() {
                    try {
            
                        const authenticationSession = window.hyperInstance.initAuthenticationSession({
                              clientSecret: "\(clientSecret)",
                              profileId: "\(profileId)",
                              authenticationId: "\(authenticationId)",
                              merchantId: "\(merchantId)",
                        });
            
                        window.ClickToPaySession = await authenticationSession.initClickToPaySession({
                            request3DSAuthentication: \(request3DSAuthentication),
                        });
            
                        const data = window.ClickToPaySession.error ? window.ClickToPaySession : { success: true }
                        window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                            requestId: "\(requestId)",
                            data: data
                        }));
                    } catch (error) {
                        window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                            requestId: "\(requestId)",
                            data: { error: {
                                    type: "InitClickToPaySessionError",
                                    message: error.message
                                }}
                        }));
                    }
                })();
            """

            // Execute immediately since SDK is already initialized
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode) { result, error in
                    if let error = error {

                    } else {
                        // handle
                    }
                }
            }
        }
    }

    public func isCustomerPresent(request: CustomerPresenceRequest) async throws -> CustomerPresenceResponse? {
        let requestId = UUID().uuidString

        let responseJson: String = try await withCheckedThrowingContinuation { continuation in
            pendingRequestsQueue.async { [weak self] in
                self?.pendingRequests[requestId] = continuation
            }

            let emailParam = request.email.map { "email: \"\($0)\"" } ?? ""

            let jsCode = """
                           (async function() {
                                try {
                                    const isCustomerPresent = await window.ClickToPaySession.isCustomerPresent({
                                        \(emailParam)
                                    });
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: isCustomerPresent
                                    }));
                                } catch (error) {
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: {
                                            error: {
                                                type: "IsCustomerPresentError",
                                                message: error.message
                                            }
                                        }
                                    }));
                                }
                            })();
            """

            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any] else {
            throw NSError(domain: "ClickToPay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        if let customerPresent = data["customerPresent"] as? Bool { // needs improvement
            return CustomerPresenceResponse(customerPresent: customerPresent)
        }
        throw NSError(domain: "ClickToPay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }

    public func getUserType() async throws -> CardsStatusResponse? {
        let requestId = UUID().uuidString

        let responseJson: String = try await withCheckedThrowingContinuation { continuation in
            pendingRequestsQueue.async { [weak self] in
                self?.pendingRequests[requestId] = continuation
            }

            let jsCode = """
                            (async function() {
                                try {
                                    const userType = await window.ClickToPaySession.getUserType();
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: userType
                                    }));
                                } catch (error) {
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: {
                                            error: {
                                                type: "GetUserTypeError",
                                                message: error.message
                                            }
                                        }
                                    }));
                                }
                            })();
            """

            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any],
              let statusCodeStr = data["statusCode"] as? String,
              let statusCode = StatusCode(rawValue: statusCodeStr) else {
            throw NSError(domain: "ClickToPay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        return CardsStatusResponse(statusCode: statusCode)
    }

    public func getRecognizedCards() async throws -> [RecognizedCard]? {
        let requestId = UUID().uuidString

        let responseJson: String = try await withCheckedThrowingContinuation { continuation in
            pendingRequestsQueue.async { [weak self] in
                self?.pendingRequests[requestId] = continuation
            }

            let jsCode = """
            (async function() {
                                try {
                                    const cards = await window.ClickToPaySession.getRecognizedCards();
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: cards
                                    }));
                                } catch (error) {
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: {
                                            error: {
                                                type: "GetRecognizedCardsError",
                                                message: error.message
                                            }
                                        }
                                    }));
                                }
                            })();
            """

            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let cardsData = json["data"] as? [[String: Any]] else {
            throw NSError(domain: "ClickToPay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        let cardsJsonData = try JSONSerialization.data(withJSONObject: cardsData)
        let cards = try JSONDecoder().decode([RecognizedCard].self, from: cardsJsonData)

        return cards
    }

    public func validateCustomerAuthentication(otpValue: String) async throws -> [RecognizedCard]? {
        let requestId = UUID().uuidString

        let responseJson: String = try await withCheckedThrowingContinuation { continuation in
            pendingRequestsQueue.async { [weak self] in
                self?.pendingRequests[requestId] = continuation
            }

            let jsCode = """
            (async function() {
                                try {
                                    const cards = await window.ClickToPaySession.validateCustomerAuthentication({
                                        value: "\(otpValue)"
                                    });
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: cards
                                    }));
                                } catch (error) {
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: {
                                            error: {
                                                type: "ValidateCustomerAuthenticationError",
                                                message: error.message
                                            }
                                        }
                                    }));
                                }
                            })();
            """

            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let cardsData = json["data"] as? [[String: Any]] else {
            throw NSError(domain: "ClickToPay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        print(json)
        let cardsJsonData = try JSONSerialization.data(withJSONObject: cardsData)
        let cards = try JSONDecoder().decode([RecognizedCard].self, from: cardsJsonData)

        return cards
    }

    public func checkoutWithCard(request: CheckoutRequest) async throws -> CheckoutResponse? {
        let requestId = UUID().uuidString

        let responseJson: String = try await withCheckedThrowingContinuation { continuation in
            pendingRequestsQueue.async { [weak self] in
                self?.pendingRequests[requestId] = continuation
            }

            let jsCode = """
            
             (async function() {
                                try {
                                    const checkoutResponse = await window.ClickToPaySession.checkoutWithCard({
                                        srcDigitalCardId: "\(request.srcDigitalCardId)",
                                        rememberMe: \(request.rememberMe)
                                    });
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: checkoutResponse
                                    }));
                                } catch (error) {
                                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                                        requestId: "\(requestId)",
                                        data: {
                                            error: {
                                                type: "CheckoutWithCardError",
                                                message: error.message
                                            }
                                        }
                                    }));
                                }
                            })();
            """

            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any] else {
            throw NSError(domain: "ClickToPay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        let responseData = try JSONSerialization.data(withJSONObject: data)
        let checkoutResponse = try JSONDecoder().decode(CheckoutResponse.self, from: responseData)

        return checkoutResponse
    }

    func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }

        return getTopViewController(from: rootViewController)
    }

    func getTopViewController(from viewController: UIViewController) -> UIViewController {
        // If it's presenting another VC, get that one
        if let presented = viewController.presentedViewController {
            return getTopViewController(from: presented)
        }

        // If it's a navigation controller, get the visible VC
        if let navController = viewController as? UINavigationController,
           let visible = navController.visibleViewController {
            return getTopViewController(from: visible)
        }

        // If it's a tab bar controller, get the selected VC
        if let tabController = viewController as? UITabBarController,
           let selected = tabController.selectedViewController {
            return getTopViewController(from: selected)
        }

        // Otherwise, return this VC
        return viewController
    }
}

// MARK: - WKScriptMessageHandler

extension ClickToPaySession: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        guard message.name == "HSInterface" else {
            return
        }

        guard let body = message.body as? String else {
            return
        }


        guard let jsonData = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }

        // Handle SDK initialization messages
        if let sdkInitialised = json["sdkInitialised"] as? Bool {
            if sdkInitialised {
                pendingRequestsQueue.async { [weak self] in
                    self?.isSDKInitialized = true
                    if let continuation = self?.sdkInitContinuation {
                        self?.sdkInitContinuation = nil
                        continuation.resume()
                    }
                }
            } else if let error = json["error"] as? String {
            }
            return
        }

        // Handle request responses
        if let requestId = json["requestId"] as? String {

            pendingRequestsQueue.async { [weak self] in
                // Check for void continuations first
                if let voidContinuation = self?.pendingVoidRequests.removeValue(forKey: requestId) {
                    // Check if the response contains an error
                    if let data = json["data"] as? [String: Any],
                       let success = data["success"] as? Bool,
                       !success,
                       let errorMessage = data["error"] as? String {
                        voidContinuation.resume(throwing: NSError(
                            domain: "ClickToPay",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        ))
                    } else {
                        voidContinuation.resume()
                    }
                } else if let continuation = self?.pendingRequests.removeValue(forKey: requestId) {
                    // Check if the response contains an error
                    if let data = json["data"] as? [String: Any],
                       let success = data["success"] as? Bool,
                       !success,
                       let errorMessage = data["error"] as? String {
                        continuation.resume(throwing: NSError(
                            domain: "ClickToPay",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errorMessage]
                        ))
                    } else {
                        continuation.resume(returning: body)
                    }
                } else {
                }
            }
        } else {
        }
    }
}
