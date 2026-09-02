//
//  TokeniseDispatcher.swift
//  HyperswitchVault
//
//  Pending native `HyperswitchVault.tokenise(completion:)` awaiting the
//  JS answer (HyperVaultModule.returnTokenizedValue).
//
//  One in-flight tokenise per vault SDK instance; a fresh registration
//  replaces any earlier completion and cancels its timeout.
//

import Foundation

internal final class TokeniseDispatcher {

    static let shared = TokeniseDispatcher()

    /// Same shape the JS vault package returns for a not-mounted form.
    private static let timeoutResult =
        #"{"status":"not_ready","error":{"code":"not_ready","message":"The card form is not ready yet."}}"#
    private static let timeoutSeconds: TimeInterval = 30

    private let lock = NSLock()
    private var pending: ((String) -> Void)? = nil
    private var timeout: DispatchWorkItem? = nil

    private init() {}

    /// Registers the completion for the next tokenise answer. The
    /// timeout safety net guarantees the completion fires exactly once even
    /// when no JS vault surface is mounted to answer.
    func register(completion: @escaping (String) -> Void) {
        let item = DispatchWorkItem { [weak self] in
            self?.resolve(Self.timeoutResult)
        }
        withLock {
            timeout?.cancel()
            pending = completion
            timeout = item
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeoutSeconds, execute: item)
    }

    func resolve(_ resultJson: String) {
        let entry: ((String) -> Void)? = withLock {
            timeout?.cancel()
            timeout = nil
            defer { pending = nil }
            return pending
        }
        guard let completion = entry else { return }
        DispatchQueue.main.async { completion(resultJson) }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
