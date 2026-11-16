//
//  HeadlessWebView.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 25/05/26.
//

import HyperswitchShared
internal import React
import UIKit
import WebKit

final internal class HeadlessWebView: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    private static let handlerName = "HSInterfaceDDC"

    private let url: String
    private let timeoutMs: NSNumber
    private let callback: RCTResponseSenderBlock
    private var webView: WKWebView?
    private var timeoutWorkItem: DispatchWorkItem?
    private var selfRetain: HeadlessWebView?
    private var callbackInvoked = false
    private var iframeOrigin: String?

    init(url: String, timeoutMs: NSNumber, callback: @escaping RCTResponseSenderBlock) {
        self.url = url
        self.timeoutMs = timeoutMs
        self.callback = callback
        super.init()
    }

    deinit {
        if !callbackInvoked { callback([""]) }
    }

    /// Normalised `scheme://host[:port]` for http(s) URLs without user info; nil for anything else.
    static func webOrigin(_ value: String) -> String? {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host?.lowercased(), !host.isEmpty,
              components.user == nil, components.password == nil
        else { return nil }
        return origin(scheme: scheme, host: host, port: components.port)
    }

    private static func origin(scheme: String, host: String, port: Int?) -> String? {
        if let port = port, !(1...65535).contains(port) { return nil }
        let defaultPort = scheme == "https" ? 443 : 80
        let portSuffix = (port == nil || port == defaultPort) ? "" : ":\(port!)"
        let formattedHost = host.contains(":") && !host.hasPrefix("[") ? "[\(host)]" : host
        return "\(scheme)://\(formattedHost)\(portSuffix)"
    }

    private static func origin(of securityOrigin: WKSecurityOrigin) -> String? {
        let scheme = securityOrigin.protocol.lowercased()
        guard scheme == "https" || scheme == "http", !securityOrigin.host.isEmpty else { return nil }
        return origin(scheme: scheme, host: securityOrigin.host.lowercased(),
                      port: securityOrigin.port == 0 ? nil : securityOrigin.port)
    }

    private static func htmlEscape(_ value: String) -> String {
        return value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func jsStringLiteral(_ value: String) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: [value]),
              let array = String(data: data, encoding: .utf8)
        else { return nil }
        return String(array.dropFirst().dropLast())
    }

    internal func startFlow() {
        selfRetain = self

        let timeoutSeconds = timeoutMs.doubleValue / 1000.0
        guard timeoutSeconds.isFinite, timeoutSeconds > 0,
              let origin = HeadlessWebView.webOrigin(url),
              let baseURL = URL(string: url),
              let originLiteral = HeadlessWebView.jsStringLiteral(origin)
        else {
            invokeCallback("")
            return
        }
        iframeOrigin = origin

        let contentController = WKUserContentController()
        let weakHandler = WeakScriptMessageHandler(delegate: self)
        contentController.add(weakHandler, name: HeadlessWebView.handlerName)

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

        guard let window = keyWindow() else {
            invokeCallback("")
            return
        }
        if let webView = webView {
            window.addSubview(webView)
        }

        let baseHtml = """
                <html><body>
                <iframe id="ddc-frame" src="\(HeadlessWebView.htmlEscape(url))" style="display:none;width:1px;height:1px;"></iframe>
                <script>
                window.addEventListener('message', function(event) {
                  if (event.source !== document.getElementById('ddc-frame').contentWindow ||
                      event.origin !== \(originLiteral)) return;
                  try {
                    var str = typeof event.data === 'string' ? event.data : JSON.stringify(event.data);
                    if (typeof str === 'string') window.webkit.messageHandlers.\(HeadlessWebView.handlerName).postMessage(str);
                  } catch(e) {}
                });
                </script>
                </body></html>
            """

        webView?.loadHTMLString(baseHtml, baseURL: baseURL)

        let workItem = DispatchWorkItem { [weak self] in
            self?.invokeCallback("")
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds, execute: workItem)
    }

    func invokeCallback(_ result: String) {
        guard !callbackInvoked else { return }
        callbackInvoked = true
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: HeadlessWebView.handlerName)
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
        guard message.name == HeadlessWebView.handlerName,
              message.frameInfo.isMainFrame,
              let iframeOrigin = iframeOrigin,
              HeadlessWebView.origin(of: message.frameInfo.securityOrigin) == iframeOrigin,
              let body = message.body as? String,
              let data = body.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return }
        // As on web: any message carrying next_action settles DDC, failing unless it is an http(s) redirect.
        guard json["next_action"] != nil else { return }
        let action = json["next_action"] as? [String: Any]
        let redirect = action?["url"] as? String
        let isValidRedirect = action?["type"] as? String == "redirect_to_url" &&
            redirect.flatMap(HeadlessWebView.webOrigin) != nil
        guard isValidRedirect,
              let serialized = try? JSONSerialization.data(withJSONObject: json),
              let result = String(data: serialized, encoding: .utf8)
        else {
            invokeCallback("")
            return
        }
        invokeCallback(result)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        invokeCallback("")
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
