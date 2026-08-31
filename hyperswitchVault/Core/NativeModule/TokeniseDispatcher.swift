//
//  TokeniseDispatcher.swift
//  HyperswitchVault
//
//  Pending native `HyperswitchCollect.tokenise(completion:)` calls awaiting
//  their JS answer (HyperVaultModule.submitTokeniseResult).
//

import Foundation

internal final class TokeniseDispatcher {

    static let shared = TokeniseDispatcher()

    /// Same shape the JS vault package returns for a not-mounted form.
    private static let timeoutResult =
        #"{"status":"not_ready","error":{"code":"not_ready","message":"The card form is not ready yet."}}"#
    private static let timeoutSeconds: TimeInterval = 30

    private let lock = NSLock()
    private var nextId: Int = 1
    private var pending: [Int: (String) -> Void] = [:]
    private var timeouts: [Int: DispatchWorkItem] = [:]

    private init() {}

    /// Registers a completion and returns the requestId to broadcast. The
    /// timeout safety net guarantees completion fires exactly once even when
    /// no JS vault surface is mounted to answer.
    func register(completion: @escaping (String) -> Void) -> NSNumber {
        let id: Int = withLock {
            let id = nextId
            nextId += 1
            pending[id] = completion
            return id
        }
        let item = DispatchWorkItem { [weak self] in
            self?.resolve(id: id, json: Self.timeoutResult)
        }
        withLock { timeouts[id] = item }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeoutSeconds, execute: item)
        return NSNumber(value: id)
    }

    func resolve(id: Int, json: String) {
        let entry: ((String) -> Void, DispatchWorkItem?)? = withLock {
            guard let completion = pending.removeValue(forKey: id) else { return nil }
            return (completion, timeouts.removeValue(forKey: id))
        }
        guard let (completion, timeout) = entry else { return }
        timeout?.cancel()
        DispatchQueue.main.async { completion(json) }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
