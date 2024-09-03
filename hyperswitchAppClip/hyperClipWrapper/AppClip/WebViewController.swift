//
//  WebViewController.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import UIKit
import WebKit

internal class WebViewController: UIViewController {
    
    internal override var shouldAutorotate: Bool {
        return false
    }
    internal override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    internal override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    
    private let baseUrl = URL(string: "https://rnweb.netlify.app/")
    private var webView: WKWebView = WKWebView()
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
    
    private func sendProps() {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: props as Any, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            let error = NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
            callback(.failed(error: error))
            return
        }
        
        let jsCode = "window.postMessage('\(jsonString)', '*');"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.webView.evaluateJavaScript(jsCode) { (result, error) in
                if let _ = error {
                    let error = NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                    self?.callback(.failed(error: error))
                } else {
                    // Message Sent
                }
            }
        }
    }
    private func sendScanCardData(scanProps: [String: Any]?) {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: scanProps as Any, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            let error = NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
            callback(.failed(error: error))
            return
        }
        
        let escapedJsonString = jsonString.replacingOccurrences(of: "'", with: "\\'")
        
        let jsCode = "window.postMessage('\(escapedJsonString)', '*');"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.webView.evaluateJavaScript(jsCode) { (result, error) in
                if let _ = error {
                    let error = NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                    self?.callback(.failed(error: error))
                } else {
                    // Message Sent
                }
            }
        }
    }
    private func callback(_ result: PaymentSheetResult) {
        DispatchQueue.main.async { [weak self] in
            self?.completion?(result)
            self?.webView.stopLoading()
            self?.dismiss(animated: false)
        }
    }
    func launchScanCard(vc: UIViewController) {
        DispatchQueue.main.async {
            var message: [String:Any] = [:]
            var callback: [String:Any] = [:]
            let cardScanSheet = CardScanSheet()
            cardScanSheet.present(from: vc) { result in
                switch result {
                case .completed(var card as ScannedCard?):
                    message["pan"] = card?.pan
                    message["expiryMonth"] =  card?.expiryMonth
                    message["expiryYear"] =  card?.expiryYear
                    callback["status"] = "Succeeded"
                    callback["scanCardData"] = message
                case .canceled:
                    callback["status"] = "Cancelled"
                case .failed(let error):
                    callback["status"] = "Failed"
                }
                self.sendScanCardData(scanProps: callback)
            }
        }
    }
    func launchApplePay() {
        let handler = ApplePayHandler()
        handler.startPayment(rnMessage: , rnCallback: )
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
            self.sendProps()
        }
        if message.name == "launchScanCard" {
            launchScanCard(vc: self)
        }
        if message.name == "launchApplePay" {
            guard let body = message.body as? String,
                  let data = body.data(using: .utf8),
                  let jsonDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                return
            }
        }
        if message.name == "exitPaymentSheet" {
            guard let body = message.body as? String,
                  let data = body.data(using: .utf8),
                  let jsonDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
                  let status = jsonDictionary["status"] else {
                let error = NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                callback(.failed(error: error))
                return
            }
            
            let result: PaymentSheetResult
            switch status {
            case "failed", "requires_payment_method":
                let errorDomain = jsonDictionary["code"] ?? "UNKNOWN_ERROR"
                let errorMessage = jsonDictionary["message"] ?? "An error has occurred."
                let error = NSError(domain: errorDomain, code: 0, userInfo: ["message": errorMessage])
                result = .failed(error: error)
            case "canceled":
                result = .canceled(data: jsonDictionary["message"] ?? "Payment was canceled")
            default:
                result = .completed(data: status)
            }
            callback(result)
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            let webView = WKWebView(frame: self.view.bounds, configuration: configuration)
            webView.uiDelegate = self
            webView.navigationDelegate = self
            
            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.backgroundColor = .clear
            webView.isOpaque = false
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            
            self.view.addSubview(webView)
            return webView
        }
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
    }
}
