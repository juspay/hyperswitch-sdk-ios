//
//  CardForm.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

import Foundation
import HyperswitchReactNative
import HyperswitchShared
import UIKit

/// One card form. Make its fields with `CardNumberField(form:)` and its like, and place them
/// anywhere; they are one form because they were made with this one. The card lives as long
/// as this object does: releasing it clears the card. Use from the main thread.
public final class CardForm {

    public struct Configuration {
        public var locale: String?
        /// How every field of this form looks.
        public var appearance: CardFormAppearance?
        /// Lets the platform offer a card it has saved. Off by default: a card field in
        /// these SDKs otherwise tells the platform it holds a one-time code, which keeps
        /// the keyboard's own suggestions away from it.
        public var autofill: Bool

        public init(
            locale: String? = nil,
            appearance: CardFormAppearance? = nil,
            autofill: Bool = false
        ) {
            self.locale = locale
            self.appearance = appearance
            self.autofill = autofill
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
    /// What waits here must not hold the form: a form that never opens would then keep itself,
    /// and the card with it, for good.
    private var whenSettled: [() -> Void] = []
    /// Asked for before the form opened, so not yet in `pendingTokenize`.
    private var waitingTokenizes: [UUID: (TokenizeResult) -> Void] = [:]
    private var pendingTokenize: (id: String, resume: (TokenizeResult) -> Void)?

    internal let host: PaymentMethodsHost
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
        props["appearance"] = configuration.appearance.flatMap { try? $0.toDictionary() }
        props["autofill"] = configuration.autofill

        /// A root that never joins a window. Stopping it is what ends the form in the bundle.
        self.surface = HeadlessSurface(
            host: host,
            moduleName: PaymentMethodsProtocol.formComponent,
            initialProperties: ["props": props],
            owner: self
        )
    }

    deinit {
        /// Nobody is left to answer these, and an `await` that is never answered never returns.
        let released = TokenizeResult.failure(.local("form_released", "The card form was released."))
        pendingTokenize?.resume(released)
        waitingTokenizes.values.forEach { $0(released) }

        let surface = self.surface
        if Thread.isMainThread {
            surface?.stop()
        } else {
            DispatchQueue.main.async { surface?.stop() }
        }
    }

    // MARK: Tokenize

    /// Sends the card to the vault and returns its token. Never throws: a card that cannot
    /// be tokenized is a `.failure`, and the fields show why.
    public func tokenize() async -> TokenizeResult {
        await withCheckedContinuation { continuation in
            tokenize { continuation.resume(returning: $0) }
        }
    }

    public func tokenize(completion: @escaping (TokenizeResult) -> Void) {
        onMain { [weak self] in
            guard let self else {
                completion(.failure(.local("form_released", "The card form was released.")))
                return
            }
            let waiting = UUID()
            self.waitingTokenizes[waiting] = completion
            self.whenFormSettles { [weak self] in
                guard let self, let completion = self.waitingTokenizes.removeValue(forKey: waiting) else { return }
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
        onMain { [weak self] in
            self?.whenFormSettles { [weak self] in
                guard let self, case .ready = self.phase else { return }
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
