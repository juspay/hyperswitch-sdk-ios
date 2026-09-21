//
//  CardForm.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

import Foundation
import UIKit

/// One card form. It hands out its fields as views to place anywhere; they are one form
/// because this object made them, with nothing to link or register. The card lives as long
/// as this object does: releasing it clears the card. Use from the main thread.
public final class CardForm {

    public struct Configuration {
        public var locale: String?

        public init(locale: String? = nil) {
            self.locale = locale
        }
    }

    /// The fields can take input and `tokenize()` can run.
    public var onReady: (() -> Void)?
    public var onChange: ((CardFormState) -> Void)?
    /// The form cannot work: the session was refused, or its vault cannot be shown here.
    public var onError: ((CardFormError) -> Void)?

    /// The latest card-free snapshot, or nil before the first field has reported.
    public private(set) var state: CardFormState?

    public var isReady: Bool {
        if case .ready = phase { return true }
        return false
    }

    internal let formId = UUID().uuidString

    private enum Phase {
        case opening
        case ready
        case failed(String)
    }

    private var phase = Phase.opening
    /// Commands reach the bundle only once it listens, which the form's first word proves.
    private var whenSettled: [() -> Void] = []
    private var pendingTokenize: (id: String, resume: (TokenizeResult) -> Void)?

    private let host: PaymentMethodsHost
    private var surface: HeadlessSurface?

    internal init(
        hyperswitchConfiguration: HyperswitchConfiguration,
        sessionConfiguration: PaymentMethodSessionConfiguration,
        configuration: Configuration,
        host: PaymentMethodsHost = .shared
    ) {
        self.host = host

        var props: [String: Any] = [
            "type": PaymentMethodsProtocol.formType,
            "protocolVersion": PaymentMethodsProtocol.version,
            "formId": formId,
            "hyper": hyperswitchConfiguration.paymentMethodsProps,
            "sdkAuthorization": sessionConfiguration.sdkAuthorization,
        ]
        props["locale"] = configuration.locale

        /// A root that never joins a window. Stopping it is what ends the form in the bundle.
        self.surface = HeadlessSurface(
            host: host,
            moduleName: PaymentMethodsProtocol.formComponent,
            initialProperties: ["props": props],
            owner: self
        )
    }

    deinit {
        let surface = self.surface
        if Thread.isMainThread {
            surface?.stop()
        } else {
            DispatchQueue.main.async { surface?.stop() }
        }
    }

    // MARK: Fields

    public func cardNumberField(_ options: CardFieldOptions = CardFieldOptions()) -> CardFieldView {
        CardFieldView(form: self, host: host, elementType: .cardNumber, options: options)
    }

    public func cardExpiryField(_ options: CardFieldOptions = CardFieldOptions()) -> CardFieldView {
        CardFieldView(form: self, host: host, elementType: .cardExpiry, options: options)
    }

    public func cardCvcField(_ options: CardFieldOptions = CardFieldOptions()) -> CardFieldView {
        CardFieldView(form: self, host: host, elementType: .cardCvc, options: options)
    }

    public func cardholderNameField(_ options: CardFieldOptions = CardFieldOptions()) -> CardFieldView {
        CardFieldView(form: self, host: host, elementType: .cardholderName, options: options)
    }

    // MARK: Tokenize

    /// Sends the card to the vault and returns its token. Never throws: a card that cannot
    /// be tokenized is a `.failure`, and the fields show why.
    public func tokenize() async -> TokenizeResult {
        await withCheckedContinuation { continuation in
            onMain { self.tokenize { continuation.resume(returning: $0) } }
        }
    }

    public func tokenize(completion: @escaping (TokenizeResult) -> Void) {
        onMain {
            self.whenFormSettles {
                if case .failed(let message) = self.phase {
                    completion(.failure(.local("form_unavailable", message)))
                    return
                }
                guard self.pendingTokenize == nil else {
                    completion(.failure(.local("tokenize_in_progress", "This form is already tokenizing.")))
                    return
                }
                let commandId = UUID().uuidString
                self.pendingTokenize = (commandId, completion)
                self.send(["commandId": commandId, "name": "tokenize"])
            }
        }
    }

    // MARK: Internal

    internal func send(fieldCommand name: String, for elementType: CardElementType) {
        onMain {
            self.whenFormSettles {
                guard case .ready = self.phase else { return }
                self.send([
                    "commandId": UUID().uuidString,
                    "name": name,
                    "elementType": elementType.rawValue,
                ])
            }
        }
    }

    private func send(_ command: [String: Any]) {
        guard let rootTag = surface?.rootTag else { return }
        var command = command
        command["rootTag"] = rootTag
        command["formId"] = formId
        host.module.send(command: command)
    }

    private func whenFormSettles(_ work: @escaping () -> Void) {
        if case .opening = phase {
            whenSettled.append(work)
        } else {
            work()
        }
    }

    private func settle(_ next: Phase) {
        guard case .opening = phase else { return }
        phase = next
        let waiting = whenSettled
        whenSettled = []
        waiting.forEach { $0() }
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

extension CardForm: PaymentMethodsEventTarget {

    internal func paymentMethodsEvent(_ name: String, payload: [String: Any]) {
        switch name {
        case PaymentMethodsProtocol.FormEvent.ready:
            settle(.ready)
            onReady?()

        case PaymentMethodsProtocol.FormEvent.change:
            let next = CardFormState(payload)
            guard next != state else { return }
            state = next
            onChange?(next)

        case PaymentMethodsProtocol.FormEvent.error:
            let message = payload["message"] as? String ?? "The card form could not be shown."
            settle(.failed(message))
            onError?(CardFormError(message: message))

        case PaymentMethodsProtocol.FormEvent.commandResult:
            guard let pending = pendingTokenize,
                  pending.id == payload["commandId"] as? String
            else { return }
            pendingTokenize = nil
            pending.resume(TokenizeResult(commandResult: payload))

        default:
            break
        }
    }
}

extension HyperswitchConfiguration {
    /// As the bundle's `HyperswitchConfiguration` spells it.
    fileprivate var paymentMethodsProps: [String: Any] {
        var props: [String: Any] = ["publishableKey": publishableKey]
        props["profileId"] = profileId
        props["environment"] = environment.map { $0 == .production ? "PROD" : "SANDBOX" }
        props["customEndpoints"] = customEndpoints.flatMap { try? $0.toDictionary() }
        return props
    }
}
