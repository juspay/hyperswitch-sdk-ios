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
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        webView.uiDelegate = self
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            webView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            webView.widthAnchor.constraint(equalTo: view.widthAnchor),
            webView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
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
            }
            alert.addAction(ok)
            self.present(alert, animated: true)
            completionHandler()
        }
    }
}

extension WebViewController: WKScriptMessageHandler {
    
    internal func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == "sdkInitialised" {
            self.sendProps()
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
