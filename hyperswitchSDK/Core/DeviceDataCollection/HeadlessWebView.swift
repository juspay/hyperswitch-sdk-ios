//
//  HeadlessWebView.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 25/05/26.
//

import WebKit

final internal class HeadlessWebView: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    private let url: String
    private let timeoutMs: NSNumber
    private let callback: RCTResponseSenderBlock
    private var webView: WKWebView?
    private var timeoutWorkItem: DispatchWorkItem?
    private var selfRetain: HeadlessWebView?
    private var callbackInvoked = false

    init(url: String, timeoutMs: NSNumber, callback: @escaping RCTResponseSenderBlock) {
        self.url = url
        self.timeoutMs = timeoutMs
        self.callback = callback
        super.init()
    }

    deinit {
        if !callbackInvoked { callback([""]) }
    }

    internal func startFlow() {
        selfRetain = self

        let contentController = WKUserContentController()
        let weakHandler = WeakScriptMessageHandler(delegate: self)
        contentController.add(weakHandler, name: "HSInterfaceDDC")

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.isHidden = false  // Keep visible to prevent freezing
        webView?.alpha = 0.01
        webView?.accessibilityElementsHidden = true  // Hide this element AND all its subviews from VoiceOver

        webView?.navigationDelegate = self
        webView?.uiDelegate = self

        guard let baseURL = URL(string: url) else {
            invokeCallback("")
            return
        }
        guard let window = keyWindow() else {
            invokeCallback("")
            return
        }
        if let webView = webView {
            window.addSubview(webView)
        }

        let baseHtml = """
                <html><body>
                <iframe src="\(url)" style="display:none;width:1px;height:1px;"></iframe>
                <script>
                window.addEventListener('message', function(event) {
                  var str = typeof event.data === 'string' ? event.data : JSON.stringify(event.data);
                  try { window.webkit.messageHandlers.HSInterfaceDDC.postMessage(str); } catch(e) {}
                });
                </script>
                </body></html>
            """

        webView?.loadHTMLString(baseHtml, baseURL: baseURL)

        let timeoutInterval = timeoutMs.doubleValue / 1000.0
        let workItem = DispatchWorkItem { [weak self] in
            self?.invokeCallback("")
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval, execute: workItem)
    }

    func invokeCallback(_ result: String) {
        guard !callbackInvoked else { return }
        callbackInvoked = true
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: "HSInterfaceDDC")
            webView?.stopLoading()
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
            webView?.removeFromSuperview()
            webView = nil
            callback([result])
            self.selfRetain = nil
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "HSInterfaceDDC",
            let body = message.body as? String
        else { return }
        invokeCallback(body)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        invokeCallback("")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        invokeCallback("")
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

    private func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
            ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
