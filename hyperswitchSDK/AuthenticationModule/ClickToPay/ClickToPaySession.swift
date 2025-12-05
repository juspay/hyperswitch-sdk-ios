//
//  ClickToPaySession.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 31/10/25.
//

import Foundation
@preconcurrency import WebKit

// MARK: - Public Protocol

/// Public protocol defining the Click to Pay session interface
public protocol ClickToPaySession {
    /// Check if a customer has an existing Click to Pay profile
    func isCustomerPresent(request: CustomerPresenceRequest) async throws -> CustomerPresenceResponse

    /// Get the user type and card status
    func getUserType() async throws -> CardsStatusResponse

    /// Get list of recognized cards for the user
    func getRecognizedCards() async throws -> [RecognizedCard]

    /// Validate customer authentication with OTP
    func validateCustomerAuthentication(otpValue: String) async throws -> [RecognizedCard]

    /// Sign out of Click to Pay Session
    func signOut() async throws -> SignOutResponse

    /// Checkout with a selected card
    func checkoutWithCard(request: CheckoutRequest) async throws -> CheckoutResponse
}

// MARK: - Internal Implementation

internal class ClickToPaySessionImpl: NSObject, ClickToPaySession, WKNavigationDelegate, WKUIDelegate {

    private let publishableKey: String
    private let customBackendUrl: String?
    private let customLogUrl: String?
    private let customParams: [String: Any]?

    private var webView: WKWebView?
    private var viewController: UIViewController?

    private var popupWebView: WKWebView?
    private let popupWebViewController: UIViewController = UIViewController()

    private var pendingRequests: [String: CheckedContinuation<String, Error>] = [:]
    private var sdkInitContinuation: CheckedContinuation<Void, Error>?

    private let pendingRequestsQueue = DispatchQueue(label: "com.hyperswitch.c2p.pendingRequests")

    internal init(
        publishableKey: String,
        customBackendUrl: String? = nil,
        customLogUrl: String? = nil,
        customParams: [String: Any]? = nil,
        viewController: UIViewController?
    ) async throws {
        self.publishableKey = publishableKey
        self.customBackendUrl = customBackendUrl
        self.customLogUrl = customLogUrl
        self.customParams = customParams
        self.viewController = viewController
        super.init()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            pendingRequestsQueue.async { [weak self] in
                self?.sdkInitContinuation = continuation
            }
            DispatchQueue.main.async { [weak self] in
                self?.setupWebView()
            }
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
        webView?.accessibilityElementsHidden = true // Hide this element AND all its subviews from VoiceOver

        webView?.navigationDelegate = self
        webView?.uiDelegate = self

        if let webView = webView {
            if let viewController = viewController {
                viewController.view.addSubview(webView)
            }
            else {
                let scenes = UIApplication.shared.connectedScenes
                let windowScene = scenes.first as? UIWindowScene
                windowScene?.windows.forEach { window in
                    window.addSubview(webView)
                }
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
                  src="https://beta.hyperswitch.io/web/2025.11.28.00/v1/HyperLoader.js"
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

    internal func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        if navigationAction.targetFrame == nil {

            self.popupWebView = WKWebView(frame: .zero, configuration: configuration)

            popupWebView?.navigationDelegate = self
            popupWebView?.uiDelegate = self
            popupWebView?.translatesAutoresizingMaskIntoConstraints = false
            popupWebView?.isOpaque = true
            popupWebView?.scrollView.isScrollEnabled = false
            popupWebView?.scrollView.bounces = false
            popupWebView?.scrollView.contentInsetAdjustmentBehavior = .never

            if let topViewController = viewController ?? getTopViewController(),
               let popupWebView = popupWebView {

                popupWebViewController.modalPresentationStyle = .overFullScreen
                popupWebViewController.view.backgroundColor = .clear

                popupWebView.translatesAutoresizingMaskIntoConstraints = false
                popupWebViewController.view.addSubview(popupWebView)
                NSLayoutConstraint.activate([
                    popupWebView.topAnchor.constraint(equalTo: popupWebViewController.view.safeAreaLayoutGuide.topAnchor),
                    popupWebView.leadingAnchor.constraint(equalTo: popupWebViewController.view.safeAreaLayoutGuide.leadingAnchor),
                    popupWebView.trailingAnchor.constraint(equalTo: popupWebViewController.view.safeAreaLayoutGuide.trailingAnchor),
                    popupWebView.bottomAnchor.constraint(equalTo: popupWebViewController.view.safeAreaLayoutGuide.bottomAnchor)
                ])

                topViewController.present(popupWebViewController, animated: true)
            }
            return popupWebView
        }
        return nil
    }

    internal func webViewDidClose(_ webView: WKWebView) {
        popupWebViewController.dismiss(animated: true) { [weak self] in
            self?.popupWebView?.stopLoading()
            self?.popupWebView?.removeFromSuperview()
            self?.popupWebView?.navigationDelegate = nil
            self?.popupWebView?.uiDelegate = nil
            self?.popupWebView = nil
        }
    }

    internal func initClickToPaySession(
        clientSecret: String,
        profileId: String,
        authenticationId: String,
        merchantId: String,
        request3DSAuthentication: Bool
    ) async throws {

        let requestId = UUID().uuidString

        let responseJson: String = try await withCheckedThrowingContinuation { continuation in
            pendingRequestsQueue.async { [weak self] in
                self?.pendingRequests[requestId] = continuation
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
                                    type: error.type || "InitClickToPaySessionError",
                                    message: error.message
                                }}
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
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            throw ClickToPayException(message: errorMessage, type: errorType)
        }
    }

    internal func isCustomerPresent(request: CustomerPresenceRequest) async throws -> CustomerPresenceResponse {
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
                                                type: error.type || "IsCustomerPresentError",
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
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"

            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        if let customerPresent = data["customerPresent"] as? Bool {
            return CustomerPresenceResponse(customerPresent: customerPresent)
        }
        throw ClickToPayException(message: "Failed to parse response", type: .error)
    }

    internal func getUserType() async throws -> CardsStatusResponse {
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
                                                type: error.type || 'ERROR',
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
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"

            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        guard let statusCodeStr = data["statusCode"] as? String,
              let statusCode = StatusCode(rawValue: statusCodeStr) else {
            throw ClickToPayException(message: "Failed to parse status code", type: .error)
        }

        return CardsStatusResponse(statusCode: statusCode)
    }

    internal func getRecognizedCards() async throws -> [RecognizedCard] {
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
                                                type: error.type || "GetRecognizedCardsError",
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
              let data = json["data"] else {
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let errorData = data as? [String: Any], let error = errorData["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"

            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        guard let cardsData = data as? [[String: Any]] else {
            throw ClickToPayException(message: "Invalid response format", type: .error)
        }

        let cardsJsonData = try JSONSerialization.data(withJSONObject: cardsData)
        let cards = try JSONDecoder().decode([RecognizedCard].self, from: cardsJsonData)

        return cards
    }

    internal func validateCustomerAuthentication(otpValue: String) async throws -> [RecognizedCard] {
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
                                                type: error.type || 'ERROR',
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
              let data = json["data"] else {
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let errorData = data as? [String: Any], let error = errorData["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"

            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        guard let cardsData = data as? [[String: Any]] else {
            throw ClickToPayException(message: "Invalid response format", type: .error)
        }

        let cardsJsonData = try JSONSerialization.data(withJSONObject: cardsData)
        let cards = try JSONDecoder().decode([RecognizedCard].self, from: cardsJsonData)

        return cards
    }

    internal func signOut() async throws -> SignOutResponse {
        let requestId = UUID().uuidString

        let responseJson: String = try await withCheckedThrowingContinuation { continuation in
            pendingRequestsQueue.async { [weak self] in
                self?.pendingRequests[requestId] = continuation
            }

            let jsCode = """
            (async function() {
                try {
                    const signOutResponse = await window.ClickToPaySession.signOut()
                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                        requestId: "\(requestId)",
                        data: signOutResponse
                    }));
                } catch (error) {
                    window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                        requestId: "\(requestId)",
                        data: {
                            error: {
                                type: error.type || 'SignOutError',
                                message: error.message
                            }
                        }
                    }))
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
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        if let recognized = data["recognized"] as? Bool {
            return SignOutResponse(recognized: recognized)
        }
        throw ClickToPayException(message: "Failed to parse response", type: .error)
    }

    internal func checkoutWithCard(request: CheckoutRequest) async throws -> CheckoutResponse {
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
                                        rememberMe: \(request.rememberMe ?? false)
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
                                                type: error.type || "CheckoutWithCardError",
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
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"

            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        let responseData = try JSONSerialization.data(withJSONObject: data)
        let checkoutResponse = try JSONDecoder().decode(CheckoutResponse.self, from: responseData)

        return checkoutResponse
    }


    public func getKeyWindow() -> UIWindow? {

        var foregroundActiveScene: UIScene?
        var foregroundInactiveScene: UIScene?

        for scene in UIApplication.shared.connectedScenes {
            guard scene is UIWindowScene else {
                continue
            }
            if scene.activationState == .foregroundActive {
                foregroundActiveScene = scene
                break
            }
            if foregroundInactiveScene == nil && scene.activationState == .foregroundInactive {
                foregroundInactiveScene = scene
                // Don't break, we can have the active scene later in the set
            }
        }
        let sceneToUse = foregroundActiveScene ?? foregroundInactiveScene

        if let windowScene = sceneToUse as? UIWindowScene {
            return windowScene.keyWindow
        }
        return nil
    }

    private func getTopViewController() -> UIViewController? {
        guard let window = getKeyWindow(),
              let rootViewController = window.rootViewController else {
            return nil
        }
        return getTopViewController(from: rootViewController)
    }

    private func getTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return getTopViewController(from: presented)
        }
        if let navController = viewController as? UINavigationController,
           let visible = navController.visibleViewController {
            return getTopViewController(from: visible)
        }
        if let tabController = viewController as? UITabBarController,
           let selected = tabController.selectedViewController {
            return getTopViewController(from: selected)
        }
        return viewController // Could be UIViewController OR UIHostingController
    }
    deinit {
        pendingRequestsQueue.sync {
            if let sdkInit = sdkInitContinuation {
                sdkInit.resume(throwing: ClickToPayException(
                    message: "Session was deallocated during initialization",
                    type: .error
                ))
                sdkInitContinuation = nil
            }
            
            for (requestId, continuation) in pendingRequests {
                continuation.resume(throwing: ClickToPayException(
                    message: "Session cleanup - operation cancelled",
                    type: .error
                ))
            }
            pendingRequests.removeAll()
        }
        
        DispatchQueue.main.async { [weak webView] in
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: "HSInterface")
            webView?.stopLoading()
            webView?.subviews.forEach { $0.removeFromSuperview() }
            webView?.removeFromSuperview()
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
        }
    }
}

// MARK: - WKScriptMessageHandler

extension ClickToPaySessionImpl: WKScriptMessageHandler {
    internal func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

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

        if let sdkInitialised = json["sdkInitialised"] as? Bool {
            pendingRequestsQueue.async { [weak self] in
                guard let self = self else { return }

                if sdkInitialised {
                    if let continuation = self.sdkInitContinuation {
                        self.sdkInitContinuation = nil
                        continuation.resume()
                    }
                } else {
                    let errorMessage = json["error"] as? String ?? "Unknown SDK initialization error"
                    if let continuation = self.sdkInitContinuation {
                        self.sdkInitContinuation = nil
                        continuation.resume(throwing: ClickToPayException(
                            message: "SDK initialization failed: \(errorMessage)",
                            type: .hyperInitializationError
                        ))
                    }
                }
            }
            return
        }

        if let requestId = json["requestId"] as? String {
            pendingRequestsQueue.async { [weak self] in
                if let continuation = self?.pendingRequests.removeValue(forKey: requestId) {
                    if let data = json["data"] as? [String: Any],
                       let error = data["error"] as? [String: Any] {
                        let typeString = error["type"] as? String ?? "ERROR"
                        let errorMessage = error["message"] as? String ?? "Unknown error"
                        let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
                        continuation.resume(throwing: ClickToPayException(message: errorMessage, type: errorType))
                    } else {
                        continuation.resume(returning: body)
                    }
                }
            }
        }
    }
}
