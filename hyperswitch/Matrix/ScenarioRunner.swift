import Foundation
import UIKit

protocol MatrixUI: AnyObject {
    func log(_ line: String)
    func gate(_ message: String) async -> Bool
    func paymentContainer(_ index: Int) -> UIView
    func cvcContainer() -> UIView
    func setStatus(_ id: String, _ status: String)
    var presenter: UIViewController { get }
}

struct Scenario {
    let id: String
    let title: String
    let run: @MainActor (Ctx) async throws -> Void
}

final class AuthBox {
    var value = ""
}

final class WidgetRef {
    let widget: PaymentWidget
    var onResult: ((PaymentResult) -> Void)?
    init(widget: PaymentWidget) { self.widget = widget }
}

final class SessionRef {
    let name: String
    var auth: String
    let paymentId: String
    let session: PaymentSession
    var widgets: [WidgetRef] = []
    var cvcWidget: CVCWidget?
    init(name: String, auth: String, paymentId: String, session: PaymentSession) {
        self.name = name; self.auth = auth; self.paymentId = paymentId; self.session = session
    }
}

struct UpdateOutcome {
    let result: UpdateIntentResult
    let newAuth: String
}

struct ScenarioFailure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

@MainActor
final class Ctx {
    let backend: MatrixBackend
    unowned let ui: MatrixUI
    let configuration: PaymentSheet.Configuration
    private let instanceFor: (IntentInfo) -> Hyperswitch
    private(set) var hyperswitch: Hyperswitch?

    var sessions: [String: SessionRef] = [:]
    var handlers: [String: PaymentSessionHandler] = [:]
    private var labels: [String: String] = [:]
    private var containerOwners: [Int: (SessionRef, WidgetRef)] = [:]
    private var windowStart: Int64 = 0
    private(set) var window: [LedgerRow] = []
    var failures: [String] = []

    init(backend: MatrixBackend, ui: MatrixUI, configuration: PaymentSheet.Configuration, instanceFor: @escaping (IntentInfo) -> Hyperswitch) {
        self.backend = backend; self.ui = ui; self.configuration = configuration; self.instanceFor = instanceFor
    }

    // MARK: lifecycle

    func begin() async throws {
        failures = []
        try await backend.clearFaults()
        windowStart = try await backend.ledgerLast()
        window = []
    }

    func end() async {
        _ = try? await backend.clearFaults()
    }

    func reset() async {
        for index in Array(containerOwners.keys) { releaseContainer(index) }
        sessions = [:]; handlers = [:]; labels = [:]
        _ = try? await backend.clearFaults()
        _ = try? await backend.clearLedger()
        windowStart = 0; window = []
    }

    // MARK: labels and logging

    @discardableResult
    func label(_ auth: String, _ name: String? = nil) -> String {
        if let name { labels[auth] = name }
        if let existing = labels[auth] { return existing }
        let generated = "?\(labels.count + 1)"
        labels[auth] = generated
        return generated
    }

    func log(_ message: String) { ui.log(message) }

    func check(_ condition: Bool, _ message: String) {
        if condition { ui.log("  ok   \(message)") } else { ui.log("  FAIL \(message)"); failures.append(message) }
    }

    func fail(_ message: String) -> ScenarioFailure { ScenarioFailure(message) }

    // MARK: ledger

    @discardableResult
    func settle(minimumWaitMs: Int = 0) async throws -> [LedgerRow] {
        if minimumWaitMs > 0 { try await Task.sleep(nanoseconds: UInt64(minimumWaitMs) * 1_000_000) }
        let started = Date()
        var lastNewAt = started
        var cursor = windowStart
        var collected: [LedgerRow] = []
        while true {
            let (rows, last) = try await backend.ledger(since: cursor)
            if !rows.isEmpty { collected += rows; cursor = last; lastNewAt = Date() }
            let now = Date()
            if now.timeIntervalSince(lastNewAt) >= 1.5 || now.timeIntervalSince(started) >= 35 { break }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        window = collected
        windowStart = cursor
        for row in collected {
            let auth = row.authorization.map { label($0) } ?? "-"
            let fault = row.fault.map { " fault=\($0)" } ?? ""
            ui.log("  ledger \(row.method) \(row.path.components(separatedBy: "?").first ?? row.path) auth=\(auth)\(fault)")
        }
        return collected
    }

    private func kind(_ row: LedgerRow) -> String? {
        let path = row.path.components(separatedBy: "?").first ?? row.path
        if row.method == "GET", path.range(of: #"^/payments/[^/]+/client$"#, options: .regularExpression) != nil { return "client" }
        if row.method == "POST", path == "/payments/session_tokens" { return "sessions" }
        if path.hasPrefix("/v1/sdk/configs/") { return "config" }
        if row.method == "POST", path.range(of: #"^/payments/[^/]+/confirm$"#, options: .regularExpression) != nil { return "confirm" }
        return nil
    }

    func counts(for auth: String) -> [Int] {
        var counts: [String: Int] = [:]
        for row in window where row.authorization == auth { counts[kind(row) ?? "other", default: 0] += 1 }
        return ["client", "sessions", "config", "confirm"].map { counts[$0] ?? 0 }
    }

    func expectAuth(_ auth: String, client: Int = 0, sessions: Int = 0, config: Int = 0, confirm: Int = 0) {
        let actual = counts(for: auth)
        let expected = [client, sessions, config, confirm]
        let fmt = { (values: [Int]) in values.map(String.init).joined(separator: "/") }
        check(actual == expected, "\(label(auth)) client/sessions/config/confirm expected \(fmt(expected)) actual \(fmt(actual))")
    }

    func expect(_ session: SessionRef, client: Int = 0, sessions: Int = 0, config: Int = 0, confirm: Int = 0) {
        expectAuth(session.auth, client: client, sessions: sessions, config: config, confirm: confirm)
    }

    // MARK: sessions

    func instance(_ intent: IntentInfo) -> Hyperswitch {
        let created = instanceFor(intent)
        hyperswitch = created
        return created
    }

    func newSession(_ name: String, amount: Int) async throws -> SessionRef {
        let intent = try await backend.createIntent(amount: amount)
        label(intent.sdkAuthorization, name)
        let session = try await instance(intent).initPaymentSession(configuration: PaymentSessionConfiguration(sdkAuthorization: intent.sdkAuthorization))
        let ref = SessionRef(name: name, auth: intent.sdkAuthorization, paymentId: intent.paymentId, session: session)
        sessions[name] = ref
        return ref
    }

    func session(_ name: String) throws -> SessionRef {
        guard let ref = sessions[name] else { throw fail("session \(name) was not created by an earlier scenario") }
        return ref
    }

    // MARK: widgets

    func releaseContainer(_ index: Int) {
        guard let (session, ref) = containerOwners.removeValue(forKey: index) else { return }
        ref.widget.removeFromSuperview()
        session.widgets.removeAll { $0 === ref }
    }

    @discardableResult
    func bind(_ session: SessionRef, container index: Int) -> WidgetRef {
        releaseContainer(index)
        let container = ui.paymentContainer(index)
        var ref: WidgetRef!
        let widget = PaymentWidget(paymentSession: session.session, configuration: configuration) { result in
            ref.onResult?(result)
        }
        ref = WidgetRef(widget: widget)
        mount(widget, in: container)
        session.widgets.append(ref)
        containerOwners[index] = (session, ref)
        return ref
    }

    func bindCvc(_ session: SessionRef) throws -> CVCWidget {
        guard let hyperswitch else { throw fail("no Hyperswitch instance yet; create a session first") }
        let container = ui.cvcContainer()
        container.subviews.forEach { $0.removeFromSuperview() }
        let widget = CVCWidget(hyperswitch: hyperswitch, configuration: configuration)
        mount(widget, in: container)
        session.cvcWidget = widget
        return widget
    }

    private func mount(_ view: UIView, in container: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    // MARK: SDK actions

    func updateIntent(_ session: SessionRef, amount: Int, newLabel: String) async -> UpdateOutcome {
        let box = AuthBox()
        let result: UpdateIntentResult = await withCheckedContinuation { continuation in
            session.session.updateIntent(
                authorizationProvider: { [backend] completion in
                    Task {
                        let auth = (try? await backend.updatePayment(paymentId: session.paymentId, amount: amount)) ?? ""
                        await MainActor.run {
                            box.value = auth
                            if !auth.isEmpty { self.label(auth, newLabel) }
                            completion(auth)
                        }
                    }
                },
                completion: { result in continuation.resume(returning: result) }
            )
        }
        let newAuth = box.value
        if case .success = result, !newAuth.isEmpty { session.auth = newAuth }
        return UpdateOutcome(result: result, newAuth: newAuth)
    }

    func headlessGet(_ session: SessionRef) async -> PaymentSessionHandler {
        await withCheckedContinuation { continuation in
            session.session.getCustomerSavedPaymentMethods({ handler in continuation.resume(returning: handler) })
        }
    }

    func confirmDefault(_ handler: PaymentSessionHandler) async -> PaymentResult {
        await withCheckedContinuation { continuation in
            handler.confirmWithCustomerDefaultPaymentMethod { result in continuation.resume(returning: result) }
        }
    }

    /* Mirrors Android's confirmWithCustomerLastUsedPaymentMethod: resolve the last-used
       token, then confirm by token (iOS has no last-used callback without a CVC widget). */
    func confirmLastUsed(_ handler: PaymentSessionHandler) async throws -> PaymentResult {
        guard case .success(let method) = handler.getCustomerLastUsedPaymentMethodData() else {
            throw fail("no customer last-used payment method data")
        }
        return await confirmToken(handler, token: method.paymentToken)
    }

    func confirmToken(_ handler: PaymentSessionHandler, token: String) async -> PaymentResult {
        await withCheckedContinuation { continuation in
            handler.confirmWithCustomerPaymentToken(paymentToken: token) { result in continuation.resume(returning: result) }
        }
    }

    func confirmWithCvcWidget(_ handler: PaymentSessionHandler, _ widget: CVCWidget) async -> PaymentResult {
        await withCheckedContinuation { continuation in
            handler.confirmWithCustomerLastUsedPaymentMethod(widget) { result in continuation.resume(returning: result) }
        }
    }

    func confirmWidget(_ ref: WidgetRef) async -> PaymentResult {
        await withCheckedContinuation { continuation in
            ref.onResult = { result in ref.onResult = nil; continuation.resume(returning: result) }
            ref.widget.confirm()
        }
    }

    func presentSheet(_ session: SessionRef) async -> PaymentResult {
        await withCheckedContinuation { continuation in
            session.session.presentPaymentSheet(viewController: ui.presenter, configuration: configuration) { result in
                continuation.resume(returning: result)
            }
        }
    }

    func gate(_ message: String) async throws {
        ui.log("  gate: \(message)")
        if !(await ui.gate(message)) { throw fail("gate timed out: \(message)") }
    }

    func sleep(_ ms: Int) async throws { try await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000) }

    // MARK: codes

    func code(_ error: Error) -> String {
        if let pm = error as? PMError { return pm.code }
        return (error as NSError).domain
    }

    func code(_ result: PaymentResult) -> String? {
        if case .failed(let error) = result { return code(error) }
        return nil
    }

    func code(_ result: UpdateIntentResult) -> String? {
        if case .failure(let error) = result { return code(error) }
        return nil
    }

    func handlerCode(_ handler: PaymentSessionHandler) -> String? {
        if case .failure(let error) = handler.getCustomerDefaultSavedPaymentMethodData() { return error.code }
        return nil
    }

    func isTerminal(_ result: PaymentResult) -> Bool {
        switch result { case .completed, .failed: return true; case .canceled: return false }
    }

    func describe(_ result: PaymentResult) -> String {
        switch result {
        case .completed(let data): return "Completed(\(data))"
        case .canceled(let data): return "Canceled(\(data))"
        case .failed(let error): return "Failed(\(code(error)))"
        }
    }

    func isSuccess(_ result: UpdateIntentResult) -> Bool {
        if case .success = result { return true }
        return false
    }
}

@MainActor
final class ScenarioRunner {
    private let ctx: Ctx
    init(ctx: Ctx) { self.ctx = ctx }

    func run(_ scenario: Scenario) async -> Bool {
        ctx.ui.setStatus(scenario.id, "running")
        ctx.log("── \(scenario.id) \(scenario.title)")
        let startedAt = Date()
        do {
            try await ctx.begin()
            try await scenario.run(ctx)
        } catch {
            ctx.failures.append("threw: \(error)")
        }
        await ctx.end()
        let seconds = Int(Date().timeIntervalSince(startedAt))
        let passed = ctx.failures.isEmpty
        let verdict = passed ? "PASS \(scenario.id)" : "FAIL \(scenario.id): \(ctx.failures[0])"
        ctx.log("\(verdict) (\(seconds)s)")
        ctx.ui.setStatus(scenario.id, passed ? "PASS" : "FAIL")
        return passed
    }
}
