//
//  Debouncer.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let lock = NSLock()

    init(delayInMillis: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delayInMillis / 1000.0
        self.queue = queue
    }

    func debounce(action: @escaping @Sendable () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        workItem?.cancel()
        let task = DispatchWorkItem { action() }
        workItem = task
        queue.asyncAfter(deadline: .now() + delay, execute: task)
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }

        workItem?.cancel()
        workItem = nil
    }
}
