//
//  PaymentSession.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Combine
import Foundation

@frozen public enum PaymentResult {
    case completed(data: String)
    case canceled(data: String)
    case failed(error: Error)
}

public enum UpdateIntentResult {
    case success
    case cancelled
    case failure(Error)
}

internal struct UpdateIntentPayload {
    let sdkAuthorization: String
}

public class PaymentSession {

    internal var paymentSessionConfiguration: PaymentSessionConfiguration
    internal var hyperswitchConfiguration: HyperswitchConfiguration?

    internal let updateIntentDidStart = PassthroughSubject<Void, Never>()
    internal let updateIntentDidComplete = PassthroughSubject<UpdateIntentPayload, Never>()
    internal let updateIntentInitReturned = PassthroughSubject<String, Never>()
    internal let updateIntentCompleteReturned = PassthroughSubject<String, Never>()
    /* per-updateIntent subscriptions; drained at finish so they don't accumulate
       (+2 per call). */
    private var updateIntentCancellables = Set<AnyCancellable>()
    private var activeWidgetIds = Set<ObjectIdentifier>()
    private let activeWidgetLock = NSLock()
    private var updateIntentInProgress = false
    private let updateIntentLock = NSLock()

    internal init(paymentSessionConfiguration: PaymentSessionConfiguration, hyperswitchConfiguration: HyperswitchConfiguration? = nil) {
        self.paymentSessionConfiguration = paymentSessionConfiguration
        self.hyperswitchConfiguration = hyperswitchConfiguration

        if let hyperswitchConfiguration = hyperswitchConfiguration {
            #if canImport(HyperOTA)
            OTAServices.shared.initialize(publishableKey: hyperswitchConfiguration.publishableKey)
            LogManager.initialize(publishableKey: hyperswitchConfiguration.publishableKey)
            #endif
        }
    }

    public func updateIntent(
        authorizationProvider: @escaping (@escaping (String) -> Void) -> Void,
        completion: @escaping (UpdateIntentResult) -> Void
    ) {
        guard beginIntentUpdate() else {
            completion(.failure(NSError(
                domain: "ALREADY_IN_PROGRESS",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "updateIntent already in progress"]
            )))
            return
        }
        let targetCount = activeWidgetCount

        let requestAuthorization = { [weak self] in
            guard let self = self else { return }
            authorizationProvider { [weak self] sdkAuthorization in
                guard let self = self else { return }
                let newSessionConfiguration = PaymentSessionConfiguration(
                    sdkAuthorization: sdkAuthorization
                )

                #if canImport(React)
                Task {
                    let newPrefetchedData: [String: Any]?
                    do {
                        newPrefetchedData = try await self.fetchIntentUpdate(
                            configuration: newSessionConfiguration
                        )
                    } catch {
                        /* SESSION_INIT_IN_PROGRESS: another in-progress session owns this
                           authorization's entry and its cache write. Do not clear it. Widgets
                           already show their overlay since init, so release them. */
                        await MainActor.run {
                            if targetCount > 0 {
                                self.updateIntentDidComplete.send(
                                    UpdateIntentPayload(sdkAuthorization: "")
                                )
                            }
                            self.finishIntentUpdate(completion: completion, result: .failure(error))
                        }
                        return
                    }
                    await MainActor.run {
                        self.deliverUpdatedIntent(
                            newSessionConfiguration: newSessionConfiguration,
                            newPrefetchedData: newPrefetchedData,
                            targetCount: targetCount,
                            completion: completion
                        )
                    }
                }
                #else
                self.paymentSessionConfiguration = newSessionConfiguration
                self.finishIntentUpdate(completion: completion, result: .success)
                #endif
            }
        }

        guard targetCount > 0 else {
            requestAuthorization()
            return
        }

        /* timeout must sit upstream of collect: on expiry it finishes the stream and collect
           emits whatever arrived. Downstream of collect it finishes without a value, the sink
           never runs, and the update-intent lock stays wedged. */
        updateIntentInitReturned
            .prefix(targetCount)
            .timeout(.seconds(30), scheduler: DispatchQueue.main)
            .collect()
            .receive(on: DispatchQueue.main)
            .sink { _ in requestAuthorization() }
            .store(in: &updateIntentCancellables)

        updateIntentDidStart.send(())
    }

    internal func registerWidget(_ widget: AnyObject) {
        activeWidgetLock.lock()
        activeWidgetIds.insert(ObjectIdentifier(widget))
        activeWidgetLock.unlock()
    }

    internal func unregisterWidget(_ widget: AnyObject) {
        activeWidgetLock.lock()
        activeWidgetIds.remove(ObjectIdentifier(widget))
        activeWidgetLock.unlock()
    }

    private var activeWidgetCount: Int {
        activeWidgetLock.lock()
        defer { activeWidgetLock.unlock() }
        return activeWidgetIds.count
    }

    private func beginIntentUpdate() -> Bool {
        updateIntentLock.lock()
        defer { updateIntentLock.unlock() }
        guard !updateIntentInProgress else { return false }
        updateIntentInProgress = true
        return true
    }

    private func finishIntentUpdate(
        completion: @escaping (UpdateIntentResult) -> Void,
        result: UpdateIntentResult
    ) {
        updateIntentLock.lock()
        updateIntentInProgress = false
        updateIntentLock.unlock()
        updateIntentCancellables.removeAll()
        completion(result)
    }

    private func deliverUpdatedIntent(
        newSessionConfiguration: PaymentSessionConfiguration,
        newPrefetchedData: [String: Any]?,
        targetCount: Int,
        completion: @escaping (UpdateIntentResult) -> Void
    ) {
        let sdkAuthorization = newSessionConfiguration.sdkAuthorization
        guard targetCount > 0 else {
            if newPrefetchedData != nil {
                commitIntentUpdate(configuration: newSessionConfiguration)
                finishIntentUpdate(completion: completion, result: .success)
            } else {
                clearUnappliedPrefetch(sdkAuthorization: sdkAuthorization)
                finishIntentUpdate(
                    completion: completion,
                    result: prefetchFailedUpdateResult()
                )
            }
            return
        }

        /* A failed prefetch must reach the caller WITHOUT switching the widgets to the new
           intent — the native session stays on the old authorization. The widgets have shown
           their update overlay since init, so they still need a completion: an empty
           authorization is the JS abort signal (UpdateIntentHook resets loading and replies
           invalid_sdk_authorization without switching). Replies are not awaited. */
        guard newPrefetchedData != nil else {
            clearUnappliedPrefetch(sdkAuthorization: sdkAuthorization)
            updateIntentDidComplete.send(UpdateIntentPayload(sdkAuthorization: ""))
            finishIntentUpdate(completion: completion, result: prefetchFailedUpdateResult())
            return
        }

        updateIntentCompleteReturned
            .prefix(targetCount)
            .timeout(.seconds(30), scheduler: DispatchQueue.main)
            .collect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                guard let self = self else { return }
                let parsedResults = results.map(self.parseUpdateIntentResult)
                /* An empty collection only arises from the timeout fallback: no widget
                   acknowledged the new intent, so nothing was committed — the merchant
                   must hear a failure, not a silent success. */
                guard !parsedResults.isEmpty else {
                    self.clearUnappliedPrefetch(sdkAuthorization: sdkAuthorization)
                    self.finishIntentUpdate(
                        completion: completion,
                        result: updateTimeoutResult()
                    )
                    return
                }
                if parsedResults.contains(where: { result in
                    if case .success = result { return true }
                    return false
                }) {
                    self.commitIntentUpdate(configuration: newSessionConfiguration)
                } else {
                    self.clearUnappliedPrefetch(sdkAuthorization: sdkAuthorization)
                }
                self.finishIntentUpdate(
                    completion: completion,
                    result: self.aggregateUpdateIntentResults(parsedResults)
                )
            }
            .store(in: &updateIntentCancellables)

        updateIntentDidComplete.send(UpdateIntentPayload(
            sdkAuthorization: sdkAuthorization
        ))
    }

    private func aggregateUpdateIntentResults(_ results: [UpdateIntentResult]) -> UpdateIntentResult {
        var sawCancellation = false
        for result in results {
            switch result {
            case .failure(let error):
                return .failure(error)
            case .cancelled:
                sawCancellation = true
            case .success:
                continue
            }
        }
        return sawCancellation ? .cancelled : .success
    }

    private func prefetchFailedUpdateResult() -> UpdateIntentResult {
        .failure(NSError(
            domain: "PREFETCH_FAILED",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "No API data was returned for the updated payment intent."]
        ))
    }

    private func updateTimeoutResult() -> UpdateIntentResult {
        .failure(NSError(
            domain: "UPDATE_INTENT_TIMEOUT",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Widgets did not acknowledge the updated payment intent in time."]
        ))
    }

    private func commitIntentUpdate(configuration: PaymentSessionConfiguration) {
        let previousAuthorization = paymentSessionConfiguration.sdkAuthorization
        paymentSessionConfiguration = configuration
        #if canImport(React)
        if previousAuthorization != configuration.sdkAuthorization {
            clearPrefetch(for: previousAuthorization)
        }
        #endif
    }

    private func clearUnappliedPrefetch(sdkAuthorization: String) {
        #if canImport(React)
        if sdkAuthorization != paymentSessionConfiguration.sdkAuthorization {
            clearPrefetch(for: sdkAuthorization)
        }
        #endif
    }

    internal func handlePaymentResult(
        _ result: PaymentResult,
        sdkAuthorization: String? = nil
    ) {
        guard case .canceled = result else {
            #if canImport(React)
            clearPrefetch(
                for: sdkAuthorization ?? paymentSessionConfiguration.sdkAuthorization
            )
            #endif
            return
        }
    }

    private func parseUpdateIntentResult(_ data: String) -> UpdateIntentResult {
        guard
            let bytes = data.data(using: .utf8),
            let json = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: String]
        else {
            return .failure(
                NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid update intent result"])
            )
        }
        switch json["status"] {
        case "cancelled":
            return .cancelled
        case "failed", "error":
            let code = json["code"].flatMap { $0.isEmpty ? nil : $0 } ?? "UNKNOWN_ERROR"
            let message = json["message"].flatMap { $0.isEmpty ? nil : $0 } ?? (json["status"] ?? "failed")
            return .failure(NSError(domain: code, code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        default:
            return .success
        }
    }
}
