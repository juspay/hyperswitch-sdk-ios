//
//  PazeHandler.swift
//  Hyperswitch
//
//  Created for Paze wallet integration.
//

import Foundation
@preconcurrency import WebKit

internal class PazeHandler: NSObject {

    private var webView: WKWebView?
    private var callback: (([[String: Any]]) -> Void)?

    internal func startPayment(rnMessage: String, rnCallback: @escaping ([[String: Any]]) -> Void) {
        callback = rnCallback

        guard let data = rnMessage.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            callback?([["error": "Invalid Paze request JSON"]])
            callback = nil
            return
        }

        let publishableKey = dict["publishable_key"] ?? ""
        let clientId = dict["client_id"] ?? ""
        let clientName = dict["client_name"] ?? ""
        let clientProfileId = dict["client_profile_id"] ?? ""
        let emailAddress = dict["email_address"] ?? ""
        let transactionAmount = dict["transaction_amount"] ?? ""
        let transactionCurrencyCode = dict["transaction_currency_code"] ?? ""
        let sessionId = dict["session_id"] ?? ""

        let pazeScriptUrl = publishableKey.hasPrefix("pk_snd")
            ? "https://sandbox.digitalwallet.earlywarning.com/web/resources/js/digitalwallet-sdk.js"
            : "https://checkout.paze.com/web/resources/js/digitalwallet-sdk.js"

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let contentController = WKUserContentController()
            contentController.add(self, name: "pazeSuccess")
            contentController.add(self, name: "pazeError")
            contentController.add(self, name: "pazeCancel")

            let configuration = WKWebViewConfiguration()
            configuration.userContentController = contentController
            if #available(iOS 14.0, *) {
                configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            } else {
                configuration.preferences.javaScriptEnabled = true
            }
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

            let wv = WKWebView(frame: .zero, configuration: configuration)
            wv.navigationDelegate = self
            self.webView = wv

            // Attach to the window so it can execute JS
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                wv.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
                wv.alpha = 0
                window.addSubview(wv)
            }

            // Store parameters for use in onPageFinished
            let js = self.buildPazeFlowScript(
                pazeScriptUrl: pazeScriptUrl,
                clientId: clientId,
                clientName: clientName,
                clientProfileId: clientProfileId,
                emailAddress: emailAddress,
                transactionAmount: transactionAmount,
                transactionCurrencyCode: transactionCurrencyCode,
                sessionId: sessionId
            )

            let html = """
            <html>
            <head><meta name='viewport' content='width=device-width, initial-scale=1.0'></head>
            <body>
            <script>\(js)</script>
            </body>
            </html>
            """
            wv.loadHTMLString(html, baseURL: nil)
        }
    }

    private func buildPazeFlowScript(
        pazeScriptUrl: String,
        clientId: String,
        clientName: String,
        clientProfileId: String,
        emailAddress: String,
        transactionAmount: String,
        transactionCurrencyCode: String,
        sessionId: String
    ) -> String {
        return """
        (function() {
            var script = document.createElement('script');
            script.src = '\(pazeScriptUrl)';
            script.onload = function() {
                (async function() {
                    try {
                        await DIGITAL_WALLET_SDK.initialize({
                            client: {
                                id: '\(clientId)',
                                name: '\(clientName)',
                                profileId: '\(clientProfileId)'
                            }
                        });

                        var canCheckout = await DIGITAL_WALLET_SDK.canCheckout({
                            emailAddress: '\(emailAddress)'
                        });

                        var transactionValue = {
                            transactionAmount: '\(transactionAmount)',
                            transactionCurrencyCode: '\(transactionCurrencyCode)'
                        };

                        await DIGITAL_WALLET_SDK.checkout({
                            acceptedPaymentCardNetworks: ['VISA', 'MASTERCARD'],
                            emailAddress: canCheckout.consumerPresent ? '\(emailAddress)' : '',
                            sessionId: '\(sessionId)',
                            actionCode: 'START_FLOW',
                            transactionValue: transactionValue,
                            shippingPreference: 'ALL'
                        });

                        var completeResponse = await DIGITAL_WALLET_SDK.complete({
                            transactionOptions: {
                                billingPreference: 'ALL',
                                merchantCategoryCode: 'US',
                                payloadTypeIndicator: 'PAYMENT'
                            },
                            transactionId: '',
                            sessionId: '\(sessionId)',
                            transactionType: 'PURCHASE',
                            transactionValue: transactionValue
                        });

                        var responseStr = '';
                        if (completeResponse && completeResponse.completeResponse) {
                            responseStr = completeResponse.completeResponse;
                        } else if (typeof completeResponse === 'string') {
                            responseStr = completeResponse;
                        } else {
                            responseStr = JSON.stringify(completeResponse);
                        }

                        window.webkit.messageHandlers.pazeSuccess.postMessage(responseStr);
                    } catch(e) {
                        var errMsg = e.message || JSON.stringify(e) || 'Unknown error';
                        window.webkit.messageHandlers.pazeError.postMessage(errMsg);
                    }
                })();
            };
            script.onerror = function() {
                window.webkit.messageHandlers.pazeError.postMessage('Failed to load Paze SDK script');
            };
            document.head.appendChild(script);
        })();
        """
    }

    private func cleanup() {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.removeFromSuperview()
            self?.webView = nil
        }
    }
}

extension PazeHandler: WKScriptMessageHandler {
    internal func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "pazeSuccess":
            let completeResponse = message.body as? String ?? ""
            callback?([["paymentMethodData": completeResponse]])
            callback = nil
            cleanup()
        case "pazeError":
            let errorMessage = message.body as? String ?? "Unknown error"
            callback?([["error": errorMessage]])
            callback = nil
            cleanup()
        case "pazeCancel":
            callback?([["error": "Cancel"]])
            callback = nil
            cleanup()
        default:
            break
        }
    }
}

extension PazeHandler: WKNavigationDelegate {
    internal func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        callback?([["error": error.localizedDescription]])
        callback = nil
        cleanup()
    }

    internal func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        callback?([["error": error.localizedDescription]])
        callback = nil
        cleanup()
    }
}
