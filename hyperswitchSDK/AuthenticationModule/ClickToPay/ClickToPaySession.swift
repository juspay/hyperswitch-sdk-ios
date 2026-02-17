//
//  ClickToPaySession.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 31/10/25.
//

import Foundation
@preconcurrency import WebKit

// MARK: - Internal Implementation

internal class ClickToPaySessionImpl: NSObject, ClickToPaySession, WKNavigationDelegate, WKUIDelegate {

    private var clientSecret: String
    private var authenticationId: String
    private let publishableKey: String
    private let customBackendUrl: String?
    private let customLogUrl: String?
    private let customParams: [String: Any]?

    private var webView: WKWebView?
    private weak var viewController: UIViewController?

    private var popupWebView: WKWebView?
    private var popupWebViewController: UIViewController?

    private var pendingRequests: [String: CheckedContinuation<String, Error>] = [:]
    private var sdkInitContinuation: CheckedContinuation<Void, Error>?

    private let pendingRequestsQueue = DispatchQueue(label: "io.hyperswitch.c2p.pendingRequests")

    private var isClosed = false

    private func getHyperLoaderURL() -> String {
        return SDKEnvironment.getEnvironment(publishableKey) == .PROD
        ? "https://checkout.hyperswitch.io/web/2025.11.28.04/v1/HyperLoader.js"
        : "https://beta.hyperswitch.io/web/2025.11.28.04/v1/HyperLoader.js"
    }

    private func getBaseURL() -> String {
        return SDKEnvironment.getEnvironment(publishableKey) == .PROD
        ? "https://secure.checkout.visa.com"
        : "https://sandbox.secure.checkout.visa.com"
    }

    private func logger(type: String, eventName: EventName, category: LogCategory, value: String) {
        let sessionId = Helper.persistentUUID(for: "click_to_pay")
        let log = LogBuilder()
            .setLogType(type)
            .setEventName(eventName)
            .setCategory(category)
            .setAuthenticationId(authenticationId)
            .setSessionId(sessionId)
            .setValue(value)
            .build()
        LogManager.addLog(log)
    }

    private func checkSessionClosed() throws {
        try pendingRequestsQueue.sync {
            if isClosed {
                throw ClickToPayException(message: "Session is closed", type: .error)
            }
        }
    }

    private func attachWebView() {
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
    }

    internal init(
        clientSecret: String,
        authenticationId: String,
        publishableKey: String,
        customBackendUrl: String? = nil,
        customLogUrl: String? = nil,
        customParams: [String: Any]? = nil,
        viewController: UIViewController?
    ) async throws {
        self.clientSecret = clientSecret
        self.authenticationId = authenticationId
        self.publishableKey = publishableKey
        self.customBackendUrl = customBackendUrl
        self.customLogUrl = customLogUrl
        self.customParams = customParams
        self.viewController = viewController
        super.init()

        LogManager.initialize(publishableKey: publishableKey)
        logger(type: "DEBUG", eventName: .createWebviewInit, category: .USER_EVENT, value: "")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            pendingRequestsQueue.async { [weak self] in
                self?.sdkInitContinuation = continuation
            }
            DispatchQueue.main.async { [weak self] in
                self?.setupWebView()
            }
        }

        logger(type: "DEBUG", eventName: .createWebviewReturned, category: .USER_EVENT, value: "")
    }

    private func setupWebView() {
        // zoom disable script
        let source: String = "var meta = document.createElement('meta');" +
        "meta.name = 'viewport';" +
        "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
        "var head = document.getElementsByTagName('head')[0];" +
        "head.appendChild(meta);"
        let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let contentController = WKUserContentController()
        let weakHandler = WeakScriptMessageHandler(delegate: self)
        contentController.add(weakHandler, name: "HSInterface")
        contentController.addUserScript(script)

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

        attachWebView()

        let backendUrlParam = customBackendUrl.map { "customBackendUrl: \"\($0)\"," } ?? ""
        let logUrlParam = customLogUrl.map { "customLogUrl: \"\($0)\"," } ?? ""
        let hyperLoaderUrl = getHyperLoaderURL()
        let baseUrl = getBaseURL()

        logger(type: "DEBUG", eventName: .initClickToPaySessionWebInit, category: .USER_EVENT, value: "loading \(hyperLoaderUrl) with \(baseUrl)")

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
                  src="\(hyperLoaderUrl)"
                  onload="initHyper()"
                  onerror="handleScriptError()"
                  async="true"
                ></script>
              </head>
              <body></body>
            </html>
        """
        webView?.loadHTMLString(baseHtml, baseURL: URL(string: baseUrl))
        logger(type: "DEBUG", eventName: .initClickToPaySessionWebReturned, category: .USER_EVENT, value: "success")
    }

    internal func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

        if navigationAction.targetFrame == nil {
            logger(type: "DEBUG", eventName: .createNewWebviewInit, category: .USER_EVENT, value: "")

            self.popupWebView = WKWebView(frame: .zero, configuration: configuration)
            self.popupWebViewController = UIViewController()

            popupWebView?.navigationDelegate = self
            popupWebView?.uiDelegate = self
            popupWebView?.translatesAutoresizingMaskIntoConstraints = false
            popupWebView?.isOpaque = true
            popupWebView?.scrollView.isScrollEnabled = false
            popupWebView?.scrollView.bounces = false
            popupWebView?.scrollView.contentInsetAdjustmentBehavior = .never

            if let topViewController = viewController ?? getTopViewController(),
               let popupWebView = popupWebView,
               let popupWebViewController = popupWebViewController {

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
            logger(type: "DEBUG", eventName: .createNewWebviewReturned, category: .USER_EVENT, value: "success")
            return popupWebView
        }
        return nil
    }

    internal func webViewDidClose(_ webView: WKWebView) {
        logger(type: "DEBUG", eventName: .closeNewWebview, category: .USER_EVENT, value: "")
        popupWebViewController?.dismiss(animated: true) { [weak self] in
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
        logger(type: "INFO", eventName: .initClickToPaySession, category: .USER_EVENT, value: "init c2p")
        logger(type: "DEBUG", eventName: .initClickToPaySessionInit, category: .USER_EVENT, value: "init c2p")
        try checkSessionClosed()

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

            logger(type: "DEBUG", eventName: .initClickToPaySessionWebInit, category: .USER_EVENT, value: "")
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any] else {
            logger(type: "ERROR", eventName: .initClickToPaySessionWebReturned, category: .USER_ERROR, value: "Failed to parse response")
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            logger(type: "ERROR", eventName: .initClickToPaySessionWebReturned, category: .USER_ERROR, value: "Type: \(typeString), Message: \(errorMessage)")
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        logger(type: "DEBUG", eventName: .initClickToPaySessionReturned, category: .USER_EVENT, value: "success")
    }

    internal func getActiveClickToPaySession(clientSecret: String,
                                             profileId: String,
                                             authenticationId: String,
                                             merchantId: String,
                                             viewController: UIViewController?) async throws {
        self.clientSecret = clientSecret
        self.authenticationId = authenticationId
        self.viewController = viewController
        await MainActor.run {
            self.attachWebView()
        }
        // INFO: always set before logging

        logger(type: "INFO", eventName: .getActiveClickToPaySession, category: .USER_EVENT, value: "get c2p")
        logger(type: "DEBUG", eventName: .getActiveClickToPaySessionInit, category: .USER_EVENT, value: "get c2p")
        try checkSessionClosed()

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
            
                        window.ClickToPaySession = await authenticationSession.getActiveClickToPaySession();
            
                        const data = window.ClickToPaySession.error ? window.ClickToPaySession : { success: true }
                        window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                            requestId: "\(requestId)",
                            data: data
                        }));
                    } catch (error) {
                        window.webkit.messageHandlers.HSInterface.postMessage(JSON.stringify({
                            requestId: "\(requestId)",
                            data: { error: {
                                    type: error.type || "getActiveClickToPaySessionError",
                                    message: error.message
                                }}
                        }));
                    }
                })();
            """

            logger(type: "DEBUG", eventName: .getActiveClickToPaySessionWebInit, category: .USER_EVENT, value: "")
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any] else {
            logger(type: "ERROR", eventName: .getActiveClickToPaySessionWebReturned, category: .USER_ERROR, value: "Failed to parse response")
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            logger(type: "ERROR", eventName: .getActiveClickToPaySessionWebReturned, category: .USER_ERROR, value: "Type: \(typeString), Message: \(errorMessage)")
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        logger(type: "DEBUG", eventName: .getActiveClickToPaySessionReturned, category: .USER_EVENT, value: "success")
    }

    internal func isCustomerPresent(request: CustomerPresenceRequest) async throws -> CustomerPresenceResponse {
        logger(type: "INFO", eventName: .isCustomerPresent, category: .USER_EVENT, value: "customer check")
        logger(type: "DEBUG", eventName: .isCustomerPresentInit, category: .USER_EVENT, value: "customer check")
        try checkSessionClosed()

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

            logger(type: "DEBUG", eventName: .isCustomerPresentWebInit, category: .USER_EVENT, value: "")
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any] else {
            logger(type: "ERROR", eventName: .isCustomerPresentWebReturned, category: .USER_ERROR, value: "Failed to parse response")
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            logger(type: "ERROR", eventName: .isCustomerPresentWebReturned, category: .USER_ERROR, value: "Type: \(typeString), Message: \(errorMessage)")
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        if let customerPresent = data["customerPresent"] as? Bool {
            logger(type: "DEBUG", eventName: .isCustomerPresentReturned, category: .USER_EVENT, value: "customerPresent: \(customerPresent)")
            return CustomerPresenceResponse(customerPresent: customerPresent)
        }
        logger(type: "ERROR", eventName: .isCustomerPresentReturned, category: .USER_ERROR, value: "Failed to decode response")
        throw ClickToPayException(message: "Failed to decode response", type: .error)
    }

    internal func getUserType() async throws -> CardsStatusResponse {
        logger(type: "INFO", eventName: .getUserType, category: .USER_EVENT, value: "get user type")
        logger(type: "DEBUG", eventName: .getUserTypeInit, category: .USER_EVENT, value: "get user type")
        try checkSessionClosed()

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

            logger(type: "DEBUG", eventName: .getUserTypeWebInit, category: .USER_EVENT, value: "")
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any] else {
            logger(type: "ERROR", eventName: .getUserTypeWebReturned, category: .USER_ERROR, value: "Failed to parse response")
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            logger(type: "ERROR", eventName: .getUserTypeWebReturned, category: .USER_ERROR, value: "Type: \(typeString), Message: \(errorMessage)")
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        guard let statusCodeStr = data["statusCode"] as? String,
              let statusCode = StatusCode(rawValue: statusCodeStr) else {
            logger(type: "ERROR", eventName: .getUserTypeReturned, category: .USER_ERROR, value: "Failed to parse status code")
            throw ClickToPayException(message: "Failed to parse status code", type: .error)
        }
        logger(type: "DEBUG", eventName: .getUserTypeReturned, category: .USER_EVENT, value: "statusCode: \(statusCode.rawValue)")
        return CardsStatusResponse(statusCode: statusCode)
    }

    internal func getRecognizedCards() async throws -> [RecognizedCard] {
        logger(type: "INFO", eventName: .getRecognisedCards, category: .USER_EVENT, value: "get recognized cards")
        logger(type: "DEBUG", eventName: .getRecognisedCardsInit, category: .USER_EVENT, value: "get recognized cards")
        try checkSessionClosed()

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

            logger(type: "DEBUG", eventName: .getRecognisedCardsWebInit, category: .USER_EVENT, value: "")
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] else {
            logger(type: "ERROR", eventName: .getRecognisedCardsWebReturned, category: .USER_ERROR, value: "Failed to parse response")
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let errorData = data as? [String: Any], let error = errorData["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            logger(type: "ERROR", eventName: .getRecognisedCardsWebReturned, category: .USER_ERROR, value: "Type: \(typeString), Message: \(errorMessage)")
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        guard let cardsData = data as? [[String: Any]] else {
            logger(type: "ERROR", eventName: .getRecognisedCardsWebReturned, category: .USER_ERROR, value: "Invalid response format")
            throw ClickToPayException(message: "Invalid response format", type: .error)
        }

        guard let cardsJsonData = try? JSONSerialization.data(withJSONObject: cardsData),
              let cards = try? JSONDecoder().decode([RecognizedCard].self, from: cardsJsonData) else {
            logger(type: "ERROR", eventName: .getRecognisedCardsReturned, category: .USER_ERROR, value: "Failed to decode response")
            throw ClickToPayException(message: "Failed to decode response", type: .error)
        }

        let visaCount = cards.count{$0.paymentCardDescriptor == .visa}
        let mastercardCount = cards.count{$0.paymentCardDescriptor == .mastercard}

        logger(type: "DEBUG", eventName: .getRecognisedCardsReturned, category: .USER_EVENT, value: "visa: \(visaCount) | mastercard: \(mastercardCount)")

        return cards
    }

    internal func validateCustomerAuthentication(otpValue: String) async throws -> [RecognizedCard] {
        logger(type: "INFO", eventName: .validateCustomerAuthentication, category: .USER_EVENT, value: "validate otp")
        logger(type: "DEBUG", eventName: .validateCustomerAuthenticationInit, category: .USER_EVENT, value: "validate otp")
        try checkSessionClosed()

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
            logger(type: "DEBUG", eventName: .validateCustomerAuthenticationWebInit, category: .USER_EVENT, value: "")
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] else {
            logger(type: "ERROR", eventName: .validateCustomerAuthenticationWebReturned, category: .USER_ERROR, value: "Failed to parse response")
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let errorData = data as? [String: Any], let error = errorData["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            logger(type: "ERROR", eventName: .validateCustomerAuthenticationWebReturned, category: .USER_ERROR, value: "Type: \(typeString), Message: \(errorMessage)")
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        guard let cardsData = data as? [[String: Any]] else {
            logger(type: "ERROR", eventName: .validateCustomerAuthenticationWebReturned, category: .USER_ERROR, value: "Invalid response format")
            throw ClickToPayException(message: "Invalid response format", type: .error)
        }

        guard let cardsJsonData = try? JSONSerialization.data(withJSONObject: cardsData),
              let cards = try? JSONDecoder().decode([RecognizedCard].self, from: cardsJsonData) else {
            logger(type: "ERROR", eventName: .validateCustomerAuthenticationReturned, category: .USER_ERROR, value: "Failed to decode response")
            throw ClickToPayException(message: "Failed to decode response", type: .error)
        }

        let visaCount = cards.count{$0.paymentCardDescriptor == .visa}
        let mastercardCount = cards.count{$0.paymentCardDescriptor == .mastercard}

        logger(type: "DEBUG", eventName: .validateCustomerAuthenticationReturned, category: .USER_EVENT, value: "visa: \(visaCount) | mastercard: \(mastercardCount)")
        return cards
    }

    internal func signOut() async throws -> SignOutResponse {
        logger(type: "INFO", eventName: .signOut, category: .USER_EVENT, value: "signout user")
        logger(type: "DEBUG", eventName: .signOutInit, category: .USER_EVENT, value: "signout user")
        try checkSessionClosed()

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

            logger(type: "DEBUG", eventName: .signOutWebInit, category: .USER_EVENT, value: "")
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any] else {
            logger(type: "ERROR", eventName: .signOutWebReturned, category: .USER_ERROR, value: "Failed to parse response")
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"
            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            logger(type: "ERROR", eventName: .signOutWebReturned, category: .USER_ERROR, value: "Type: \(typeString), Message: \(errorMessage)")
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        if let recognized = data["recognized"] as? Bool {
            logger(type: "DEBUG", eventName: .signOutReturned, category: .USER_EVENT, value: "recognized: \(recognized)")
            return SignOutResponse(recognized: recognized)
        }
        logger(type: "ERROR", eventName: .signOutReturned, category: .USER_ERROR, value: "Failed to decode response")
        throw ClickToPayException(message: "Failed to decode response", type: .error)
    }

    internal func checkoutWithCard(request: CheckoutRequest) async throws -> CheckoutResponse {
        logger(type: "INFO", eventName: .checkout, category: .USER_EVENT, value: "checkout with rememberMe: \(request.rememberMe ?? false)")
        logger(type: "DEBUG", eventName: .checkoutInit, category: .USER_EVENT, value: "checkout with rememberMe: \(request.rememberMe ?? false)")
        try checkSessionClosed()

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

            logger(type: "DEBUG", eventName: .checkoutWebInit, category: .USER_EVENT, value: "")
            DispatchQueue.main.async { [weak self] in
                self?.webView?.evaluateJavaScript(jsCode, completionHandler: nil)
            }
        }

        guard let jsonData = responseJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let data = json["data"] as? [String: Any] else {
            logger(type: "ERROR", eventName: .checkoutWebReturned, category: .USER_ERROR, value: "Failed to parse response")
            throw ClickToPayException(message: "Failed to parse response", type: .error)
        }

        if let error = data["error"] as? [String: Any] {
            let typeString = error["type"] as? String ?? "ERROR"
            let errorMessage = error["message"] as? String ?? "Unknown error"

            let errorType = ClickToPayErrorType(rawValue: typeString) ?? .error
            logger(type: "ERROR", eventName: .checkoutWebReturned, category: .USER_ERROR, value: "Type: \(typeString), Message: \(errorMessage)")
            throw ClickToPayException(message: errorMessage, type: errorType)
        }

        guard let responseData = try? JSONSerialization.data(withJSONObject: data),
              let checkoutResponse = try? JSONDecoder().decode(CheckoutResponse.self, from: responseData) else {
            logger(type: "ERROR", eventName: .checkoutReturned, category: .USER_ERROR, value: "Failed to decode response")
            throw ClickToPayException(message: "Failed to decode response", type: .error)
        }

        logger(type: "DEBUG", eventName: .checkoutReturned, category: .USER_EVENT, value: "success")
        return checkoutResponse
    }

    public func close() async {
        logger(type: "INFO", eventName: .close, category: .USER_EVENT, value: "close webview")
        logger(type: "DEBUG", eventName: .closeInit, category: .USER_EVENT, value: "close webview")

        let alreadyClosed = pendingRequestsQueue.sync { () -> Bool in
            if isClosed { return true }
            isClosed = true
            return false
        }

        guard !alreadyClosed else { return }
        logger(type: "DEBUG", eventName: .closeWebviewInit, category: .USER_EVENT, value: "")
        pendingRequestsQueue.sync {
            let pendingRequestsCopy = pendingRequests
            pendingRequests.removeAll()

            for (_, continuation) in pendingRequestsCopy {
                continuation.resume(throwing: ClickToPayException(
                    message: "Session was closed",
                    type: .error
                ))
            }

            if let initContinuation = sdkInitContinuation {
                sdkInitContinuation = nil
                initContinuation.resume(throwing: ClickToPayException(
                    message: "Session was closed during initialization",
                    type: .error
                ))
            }
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                if self.popupWebViewController?.presentingViewController != nil {
                    self.popupWebViewController?.dismiss(animated: false)
                }
                self.cleanupPopupWebView()
                self.cleanupMainWebView()
                logger(type: "DEBUG", eventName: .closeWebviewReturned, category: .USER_EVENT, value: "success")
                logger(type: "DEBUG", eventName: .closeReturned, category: .USER_EVENT, value: "success")
                continuation.resume()
            }
        }
    }

    /// Cleans up the popup WebView resources
    private func cleanupPopupWebView() {
        popupWebView?.stopLoading()
        popupWebView?.removeFromSuperview()
        popupWebView?.navigationDelegate = nil
        popupWebView?.uiDelegate = nil
        popupWebView = nil
    }

    /// Cleans up the main WebView resources
    private func cleanupMainWebView() {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "HSInterface")
        webView?.configuration.userContentController.removeAllUserScripts()
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView = nil
    }

    /// A weak wrapper for WKScriptMessageHandler to break the retain cycle
    private class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
        weak var delegate: WKScriptMessageHandler?

        init(delegate: WKScriptMessageHandler) {
            self.delegate = delegate
            super.init()
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            delegate?.userContentController(userContentController, didReceive: message)
        }
    }

    private func getKeyWindow() -> UIWindow? {

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
        let wasClosed = pendingRequestsQueue.sync { isClosed }
        guard !wasClosed else { return }

        // Capture references before self is deallocated
        let mainWebView = webView
        let popup = popupWebView
        let popupVC = popupWebViewController

        DispatchQueue.main.async {
            // Clean up main webView
            mainWebView?.configuration.userContentController.removeScriptMessageHandler(forName: "HSInterface")
            mainWebView?.configuration.userContentController.removeAllUserScripts()
            mainWebView?.stopLoading()
            mainWebView?.removeFromSuperview()
            mainWebView?.navigationDelegate = nil
            mainWebView?.uiDelegate = nil

            // Clean up popup webView
            if popupVC?.presentingViewController != nil {
                popupVC?.dismiss(animated: false)
            }
            popup?.stopLoading()
            popup?.removeFromSuperview()
            popup?.navigationDelegate = nil
            popup?.uiDelegate = nil
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
                    logger(type: "DEBUG", eventName: .initClickToPaySessionWebReturned, category: .USER_EVENT, value: "success")
                    if let continuation = self.sdkInitContinuation {
                        self.sdkInitContinuation = nil
                        continuation.resume()
                    }
                } else {
                    let errorMessage = json["error"] as? String ?? "Unknown SDK initialization error"
                    logger(type: "ERROR", eventName: .initClickToPaySessionWebReturned, category: .USER_ERROR, value: "failure")
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
                    continuation.resume(returning: body)
                }
            }
        }
    }
}
