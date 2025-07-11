//
//  WebViewController.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import UIKit
@preconcurrency import WebKit
#if canImport(HyperswitchScanCard)
import HyperswitchScanCard
#endif

internal class WebViewController: HyperUIViewController {
    
    private let applePayPaymentHandler = ApplePayHandlerLite()
    
    private let baseUrl = URL(string: "https://dev.hyperswitch.io/mobile/v1/index.html")
    private var webView: WKWebView = WKWebView()
    private var popupWebView: WKWebView?
    private var props: [String: Any]?
    private var completion: ((PaymentSheetResult) -> ())?
    
    typealias scanCallback = ([[String: Any]]) -> ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
    }
    
    init(props: [String : Any], completion: ((PaymentSheetResult) -> ())?) {
        self.props = props
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureWebView() {
        
        let contentController = WKUserContentController()
        contentController.add(self, name: "sdkInitialised")
        contentController.add(self, name: "exitPaymentSheet")
        contentController.add(self, name: "launchScanCard")
        contentController.add(self, name: "launchApplePay")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        webView = WKWebView(frame: self.view.bounds, configuration: configuration)
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        view.addSubview(webView)
        
        guard let baseUrl = baseUrl else {
            return
        }
        
        let request = URLRequest(url: baseUrl)
        webView.load(request)
    }
    
    private func sendPropsToJS(props: [String: Any]?) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: props as Any)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let escapedJsonString = jsonString.replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
                
                let jsCode = "window.postMessage(\"\(escapedJsonString)\", '*');"
                webView.evaluateJavaScript(jsCode) { (result, error) in
                    if let error = error {
                        print("Error sending message: \(error)")
                    }
                }
            }
        } catch {
            print("Error creating JSON: \(error)")
        }
    }
    
    private func callback(_ result: PaymentSheetResult) {
        DispatchQueue.main.async { [weak self] in
            self?.completion?(result)
            self?.webView.stopLoading()
            self?.dismiss(animated: false)
        }
    }
}
extension WebViewController: WKUIDelegate {
    internal func webView(_ webView: WKWebView,
                          runJavaScriptAlertPanelWithMessage message: String,
                          initiatedByFrame frame: WKFrameInfo,
                          completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let title = NSLocalizedString("OK", comment: "OK Button")
            let ok = UIAlertAction(title: title, style: .default) { (action: UIAlertAction) -> Void in
                alert.dismiss(animated: true, completion: nil)
                completionHandler()
            }
            alert.addAction(ok)
            self.present(alert, animated: true)
        }
    }
}

extension WebViewController: WKScriptMessageHandler {
    internal func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "sdkInitialised" {
            self.sendPropsToJS(props: self.props)
        }
        if message.name == "launchApplePay" {
            guard let body = message.body as? String else {
                return
            }
            applePayPaymentHandler.startPayment(rnMessage: body, rnCallback: { props in
                let applePayProps = [
                    "applePayData" : props[0]
                ]
                self.sendPropsToJS(props: applePayProps)
            })
        }
        if message.name == "launchScanCard" {
#if canImport(HyperswitchScanCard)
            DispatchQueue.main.async {
                var message: [String:Any] = [:]
                var callback: [String:Any] = [:]
                let cardScanSheet = CardScanSheet()
                cardScanSheet.present(from: self) { result in
                    switch result {
                    case .completed(let card as ScannedCard?):
                        message["pan"] = card?.pan
                        message["expiryMonth"] = card?.expiryMonth
                        message["expiryYear"] = card?.expiryYear
                        callback["status"] = "Succeeded"
                        callback["data"] = message
                    case .canceled:
                        callback["status"] = "Cancelled"
                    case .failed(_):
                        callback["status"] = "Failed"
                    }
                    self.sendPropsToJS(props: ["scanCardData": callback])
                }
            }
#endif
        }
        if message.name == "exitPaymentSheet" {
            do {
                guard let body = message.body as? String,
                      let data = body.data(using: .utf8),
                      let jsonDictionary = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
                    throw NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                }
                
                let result: PaymentSheetResult
                
                if let status = jsonDictionary["status"] {
                    switch status {
                    case "failed", "requires_payment_method":
                        let errorDomain = jsonDictionary["code"] ?? "UNKNOWN_ERROR"
                        let errorMessage = jsonDictionary["message"] ?? "An error has occurred."
                        let error = NSError(domain: errorDomain, code: 0, userInfo: ["message": errorMessage])
                        result = .failed(error: error)
                    case "cancelled":
                        result = .canceled(data: jsonDictionary["message"] ?? "Payment was canceled")
                    default:
                        result = .completed(data: status)
                    }
                } else {
                    throw NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                }
                callback(result)
            } catch {
                callback(.failed(error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])))
            }
        }
        
        if message.name == "closePopupWebView" {
            popupWebView?.removeFromSuperview()
            self.popupWebView = nil
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            
            configuration.userContentController.removeScriptMessageHandler(forName: "closePopupWebView")
            configuration.userContentController.add(self, name: "closePopupWebView")
            
            let webView = WKWebView(frame: self.view.bounds, configuration: configuration)
            webView.uiDelegate = self
            webView.navigationDelegate = self
            
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.backgroundColor = .clear
            webView.isOpaque = true
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            
            
            webView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(webView)
            
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
            
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                let js = """
                    var closeButtonContainer = document.createElement('div');
                    closeButtonContainer.style.position = 'fixed';
                    closeButtonContainer.style.top = '16px';
                    closeButtonContainer.style.right = '20px';
                    closeButtonContainer.style.zIndex = '1000';
                    closeButtonContainer.style.cursor = 'pointer';
                    
                    closeButtonContainer.innerHTML = `
                        <svg height="24" width="24" fill="rgba(53, 64, 82, 0.25)" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
                            <path d="M13.7429 2.27713C13.3877 1.92197 12.8117 1.92197 12.4618 2.27713L8.01009 6.71659L3.55299 2.26637C3.19771 1.91121 2.62173 1.91121 2.27184 2.26637C1.91656 2.62152 1.91656 3.19731 2.27184 3.54709L6.72356 7.99731L2.26646 12.4529C1.91118 12.8081 1.91118 13.3839 2.26646 13.7336C2.62173 14.0888 3.19771 14.0888 3.5476 13.7336L7.99932 9.28341L12.451 13.7336C12.8063 14.0888 13.3823 14.0888 13.7322 13.7336C14.0875 13.3785 14.0875 12.8027 13.7322 12.4529L9.28047 8.00269L13.7322 3.55247C14.0875 3.20807 14.0875 2.62152 13.7429 2.27713Z" fill="#8D8D8D"></path>
                        </svg>
                    `;
                    
                    closeButtonContainer.onclick = function() {
                        window.webkit.messageHandlers.closePopupWebView.postMessage(`{\"type\":\"\",\"code\":\"\",\"message\":\"\",\"status\":\"cancelled\"}`);
                    };
                    
                    document.body.appendChild(closeButtonContainer);
                """
                
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
            
            popupWebView = webView
            return webView
        }
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
    }
}
