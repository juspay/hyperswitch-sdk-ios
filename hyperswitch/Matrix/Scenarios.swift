import Foundation

enum Scenarios {

    static let all: [Scenario] = [
        Scenario(id: "M1", title: "Init prefetches once") { c in
            let a = try await c.newSession("A", amount: 1001)
            try await c.settle(); c.expect(a, client: 1, sessions: 1, config: 1)
        },
        Scenario(id: "M2", title: "Bind uses the cache") { c in
            let a = try c.session("A")
            c.bind(a, container: 1)
            try await c.settle(); c.expect(a)
        },
        Scenario(id: "M3", title: "Two sessions stay isolated") { c in
            let a = try c.session("A")
            let b = try await c.newSession("B", amount: 2002)
            try await c.settle(); c.expect(b, client: 1, sessions: 1, config: 1); c.expect(a)
            c.bind(b, container: 2)
            try await c.settle(); c.expect(b); c.expect(a)
        },
        Scenario(id: "M4", title: "One session, two widgets") { c in
            let s = try await c.newSession("C", amount: 2503)
            try await c.settle(); c.expect(s, client: 1, sessions: 1, config: 1)
            c.bind(s, container: 2); try await c.settle(); c.expect(s)
            c.bind(s, container: 3); try await c.settle(); c.expect(s)
        },
        Scenario(id: "M13", title: "updateIntent on a two-widget session") { c in
            let s = try c.session("C")
            let outcome = await c.updateIntent(s, amount: 2504, newLabel: "C'")
            c.check(c.isSuccess(outcome.result), "updateIntent Success (got \(c.code(outcome.result) ?? "success"))")
            try await c.settle(); c.expectAuth(outcome.newAuth, client: 1, sessions: 1, config: 1)
        },
        Scenario(id: "M5", title: "updateIntent with widgets") { c in
            let a = try c.session("A"); let b = try c.session("B")
            let outcome = await c.updateIntent(a, amount: 3003, newLabel: "A'")
            c.check(c.isSuccess(outcome.result), "updateIntent Success (got \(c.code(outcome.result) ?? "success"))")
            try await c.settle(); c.expectAuth(outcome.newAuth, client: 1, sessions: 1, config: 1); c.expect(b)
            c.bind(a, container: 3)
            try await c.settle(); c.expect(a)
        },
        Scenario(id: "M6", title: "updateIntent without widgets") { c in
            let d = try await c.newSession("D", amount: 4004)
            try await c.settle()
            let outcome = await c.updateIntent(d, amount: 4005, newLabel: "D'")
            c.check(c.isSuccess(outcome.result), "updateIntent Success")
            try await c.settle(); c.expectAuth(outcome.newAuth, client: 1, sessions: 1, config: 1)
            c.check(d.auth == outcome.newAuth, "session authorization equals D'")
        },
        Scenario(id: "M7", title: "Duplicate init is rejected") { c in
            let intent = try await c.backend.createIntent(amount: 5005)
            c.label(intent.sdkAuthorization, "E")
            let hyperswitch = c.instance(intent)
            let config = PaymentSessionConfiguration(sdkAuthorization: intent.sdkAuthorization)
            async let first: Result<PaymentSession, Error> = { do { return .success(try await hyperswitch.initPaymentSession(configuration: config)) } catch { return .failure(error) } }()
            async let second: Result<PaymentSession, Error> = { do { return .success(try await hyperswitch.initPaymentSession(configuration: config)) } catch { return .failure(error) } }()
            let results = await [first, second]
            let successes = results.filter { if case .success = $0 { return true } else { return false } }.count
            let duplicates = results.filter { if case .failure(let e) = $0 { return c.code(e) == "SESSION_INIT_IN_PROGRESS" } else { return false } }.count
            c.check(successes == 1 && duplicates == 1, "one Success and one SESSION_INIT_IN_PROGRESS (got \(successes) success, \(duplicates) duplicate)")
            try await c.settle(); c.expectAuth(intent.sdkAuthorization, client: 1, sessions: 1, config: 1)
        },
        Scenario(id: "M8", title: "Destroy and rebind") { c in
            let a = try c.session("A")
            c.releaseContainer(1)
            let f = try await c.newSession("F", amount: 6006)
            try await c.settle(); c.expect(f, client: 1, sessions: 1, config: 1); c.expect(a)
            c.bind(f, container: 1)
            try await c.settle(); c.expect(f); c.expect(a)
        },
        Scenario(id: "M9", title: "Rebind without destroy (Android only)") { c in
            c.log("  N/A on iOS: PaymentWidget is created per session; there is no rebind of a mounted view")
            c.check(true, "not applicable")
        },
        Scenario(id: "M10", title: "updateIntent prefetch times out") { c in
            let l = try await c.newSession("L", amount: 4014)
            try await c.settle()
            c.bind(l, container: 2); try await c.settle()
            _ = try await c.backend.addFault(pathContains: "/client", authorization: "*", mode: "delay", statusOrDelayMs: 40_000)
            let first = await c.updateIntent(l, amount: 4015, newLabel: "L'")
            c.check(c.code(first.result) == "PREFETCH_FAILED", "first updateIntent is PREFETCH_FAILED (got \(c.code(first.result) ?? "success"))")
            c.check(l.auth != first.newAuth, "session still on L")
            try await c.gate("Confirm the widget in container 2 shows the 40.14 intent with no overlay, then press Continue")
            try await c.settle(minimumWaitMs: 15_000); c.expectAuth(first.newAuth, client: 1, sessions: 1, config: 1)
            let second = await c.updateIntent(l, amount: 4016, newLabel: "L''")
            c.check(c.isSuccess(second.result), "second updateIntent Success")
            try await c.settle(); c.expectAuth(second.newAuth, client: 1, sessions: 1, config: 1)
        },
        Scenario(id: "M11", title: "Init prefetch times out, late completion repopulates") { c in
            _ = try await c.backend.addFault(pathContains: "/client", authorization: "*", mode: "delay", statusOrDelayMs: 40_000)
            let startedAt = Date()
            let n = try await c.newSession("N", amount: 4024)
            let seconds = Int(Date().timeIntervalSince(startedAt))
            c.check((28...36).contains(seconds), "init returned after about 30 seconds (got \(seconds)s)")
            c.bind(n, container: 3)
            try await c.settle(minimumWaitMs: 15_000); c.expect(n, client: 2, sessions: 2, config: 2)
            c.bind(n, container: 2)
            try await c.settle(); c.expect(n)
        },
        Scenario(id: "M12", title: "Concurrent updateIntent is rejected") { c in
            let p = try await c.newSession("P", amount: 4034)
            try await c.settle(); c.bind(p, container: 2); try await c.settle()
            async let one = c.updateIntent(p, amount: 4035, newLabel: "P'")
            async let two = c.updateIntent(p, amount: 4036, newLabel: "P''")
            let outcomes = await [one, two]
            let successes = outcomes.filter { c.isSuccess($0.result) }
            let rejected = outcomes.filter { c.code($0.result) == "ALREADY_IN_PROGRESS" }.count
            c.check(successes.count == 1 && rejected == 1, "one Success and one ALREADY_IN_PROGRESS (got \(successes.count) success, \(rejected) rejected)")
            try await c.settle()
            if let winner = successes.first { c.expectAuth(winner.newAuth, client: 1, sessions: 1, config: 1) }
        },
        Scenario(id: "M14", title: "Partial prefetch failure at init") { c in
            _ = try await c.backend.addFault(pathContains: "/session_tokens", authorization: "*", mode: "error", statusOrDelayMs: 500)
            let q = try await c.newSession("Q", amount: 4044)
            try await c.settle(); c.expect(q, client: 1, sessions: 1, config: 1)
            c.check(c.window.contains { $0.fault == "error" }, "the sessions row was faulted")
            c.bind(q, container: 3)
            try await c.settle(); c.expect(q, sessions: 1)
        },
        Scenario(id: "M15", title: "updateIntent prefetch API error falls back") { c in
            let r = try await c.newSession("R", amount: 4054)
            try await c.settle(); c.bind(r, container: 2); try await c.settle()
            _ = try await c.backend.addFault(pathContains: "/client", authorization: "*", mode: "error", statusOrDelayMs: 500)
            let outcome = await c.updateIntent(r, amount: 4055, newLabel: "R'")
            c.check(c.isSuccess(outcome.result), "updateIntent Success despite the faulted prefetch")
            try await c.settle(); c.expectAuth(outcome.newAuth, client: 2, sessions: 1, config: 1)
        },
        Scenario(id: "H1", title: "Headless get from cache") { c in
            let a = try c.session("A")
            let handler = await c.headlessGet(a)
            let methods = handler.getCustomerSavedPaymentMethodData()
            if case .success(let list) = methods { c.check(!list.isEmpty, "handler has saved methods") } else { c.check(false, "handler has saved methods (\(c.handlerCode(handler) ?? "unknown"))") }
            c.handlers["A"] = handler
            try await c.settle(); c.expect(a)
        },
        Scenario(id: "H2", title: "Confirm by token, then cache cleared") { c in
            let a = try c.session("A")
            guard let handler = c.handlers["A"] else { throw c.fail("run H1 first") }
            let result = try await c.confirmLastUsed(handler)
            c.check(c.isTerminal(result), "terminal result (\(c.describe(result)))")
            try await c.settle(); c.expect(a, confirm: 1)
            _ = await c.headlessGet(a)
            try await c.settle(); c.expect(a, client: 1)
        },
        Scenario(id: "H3", title: "Retry on a used handler") { c in
            guard let handler = c.handlers["A"] else { throw c.fail("run H1 first") }
            let result = try await c.confirmLastUsed(handler)
            c.check(c.code(result) == "HANDLER_ALREADY_USED", "HANDLER_ALREADY_USED (got \(c.describe(result)))")
        },
        Scenario(id: "H4", title: "Stale handler after update") { c in
            let g = try await c.newSession("G", amount: 4064)
            try await c.settle()
            let handler = await c.headlessGet(g)
            let outcome = await c.updateIntent(g, amount: 4065, newLabel: "G'")
            c.check(c.isSuccess(outcome.result), "updateIntent Success")
            try await c.settle()
            let result = try await c.confirmLastUsed(handler)
            c.check(c.code(result) == "STALE_PAYMENT_SESSION_HANDLER", "STALE_PAYMENT_SESSION_HANDLER (got \(c.describe(result)))")
            try await c.settle(); c.expect(g)
        },
        Scenario(id: "H5", title: "CVC widget confirm") { c in
            let j = try await c.newSession("J", amount: 4074)
            try await c.settle()
            let widget = try c.bindCvc(j)
            let handler = await c.headlessGet(j)
            try await c.settle()
            try await c.gate("Type CVC 123 into the CVC widget, then press Continue")
            let result = await c.confirmWithCvcWidget(handler, widget)
            c.check(c.isTerminal(result), "terminal result (\(c.describe(result)))")
            try await c.settle(); c.expect(j, confirm: 1)
        },
        Scenario(id: "H6", title: "Cancel keeps the cache") { c in
            let k = try await c.newSession("K", amount: 4084)
            try await c.settle()
            c.log("  dismiss the payment sheet without paying")
            let result = await c.presentSheet(k)
            if case .canceled = result { c.check(true, "Canceled") } else { c.check(false, "Canceled (got \(c.describe(result)))") }
            try await c.settle()
            _ = await c.headlessGet(k)
            try await c.settle(); c.expect(k)
        },
        Scenario(id: "H7", title: "Losing a confirm race keeps the handler usable") { c in
            let s = try await c.newSession("S", amount: 4094)
            try await c.settle()
            let h1 = await c.headlessGet(s)
            let h2 = await c.headlessGet(s)
            guard case .success(let method) = h1.getCustomerDefaultSavedPaymentMethodData() else { throw c.fail("h1 has no default method (\(c.handlerCode(h1) ?? "unknown"))") }
            try await c.settle()
            _ = try await c.backend.addFault(pathContains: "/confirm", authorization: s.auth, mode: "delay", statusOrDelayMs: 8_000)
            async let first = c.confirmToken(h1, token: method.paymentToken)
            try await c.sleep(1_000)
            let second = await c.confirmToken(h2, token: method.paymentToken)
            c.check(c.code(second) == "ALREADY_IN_PROGRESS", "h2 first attempt ALREADY_IN_PROGRESS (got \(c.describe(second)))")
            let firstResult = await first
            c.check(c.isTerminal(firstResult), "h1 terminal (\(c.describe(firstResult)))")
            let third = await c.confirmToken(h2, token: method.paymentToken)
            c.check(c.isTerminal(third), "h2 second attempt terminal, not ALREADY_IN_PROGRESS (\(c.describe(third)))")
            try await c.settle(); c.expect(s, confirm: 2)
        },
        Scenario(id: "H8", title: "Headless request timeout and duplicate get") { c in
            _ = try await c.backend.addFault(pathContains: "/client", authorization: "*", mode: "error", statusOrDelayMs: 500)
            let t = try await c.newSession("T", amount: 4104)
            try await c.settle()
            _ = try await c.backend.addFault(pathContains: "/client", authorization: "*", mode: "delay", statusOrDelayMs: 40_000)
            async let first = c.headlessGet(t)
            try await c.sleep(2_000)
            let second = await c.headlessGet(t)
            c.check(c.handlerCode(second) == "ALREADY_IN_PROGRESS", "second get ALREADY_IN_PROGRESS (got \(c.handlerCode(second) ?? "ok"))")
            let firstHandler = await first
            c.check(c.handlerCode(firstHandler) == "HEADLESS_TIMEOUT", "first get HEADLESS_TIMEOUT (got \(c.handlerCode(firstHandler) ?? "ok"))")
            try await c.settle(minimumWaitMs: 15_000); c.expect(t, client: 2, sessions: 1, config: 1)
            c.log("  MANUAL: check the Xcode console for 'dropping late response'")
        },
        Scenario(id: "H9", title: "Two sessions headless in parallel") { c in
            let u = try await c.newSession("U", amount: 4114)
            let v = try await c.newSession("V", amount: 4115)
            try await c.settle()
            async let hu = c.headlessGet(u)
            async let hv = c.headlessGet(v)
            let (handlerU, handlerV) = await (hu, hv)
            async let ru = c.confirmLastUsed(handlerU)
            async let rv = c.confirmLastUsed(handlerV)
            let (resultU, resultV) = try await (ru, rv)
            c.check(c.isTerminal(resultU) && c.isTerminal(resultV), "both confirms terminal (\(c.describe(resultU)), \(c.describe(resultV)))")
            try await c.settle(); c.expect(u, confirm: 1); c.expect(v, confirm: 1)
        },
        Scenario(id: "S1", title: "Sheet payment clears the cache") { c in
            let w = try await c.newSession("W", amount: 4124)
            try await c.settle()
            c.log("  pay with 4242 4242 4242 4242, any future expiry, CVC 123")
            let result = await c.presentSheet(w)
            if case .completed = result { c.check(true, "Completed") } else { c.check(false, "Completed (got \(c.describe(result)))") }
            try await c.settle()
            _ = await c.headlessGet(w)
            try await c.settle(); c.expect(w, client: 1)
        },
        Scenario(id: "W1", title: "Widget payment clears the cache") { c in
            let x = try await c.newSession("X", amount: 4134)
            try await c.settle()
            let ref = c.bind(x, container: 2)
            try await c.settle()
            try await c.gate("Enter 4242 4242 4242 4242, any future expiry, CVC 123 in the widget in container 2, then press Continue")
            let result = await c.confirmWidget(ref)
            if case .completed = result { c.check(true, "Completed") } else { c.check(false, "Completed (got \(c.describe(result)))") }
            try await c.settle()
            c.bind(x, container: 3)
            try await c.settle(); c.expect(x, client: 1)
        },
        Scenario(id: "E1", title: "Eviction by count") { c in
            var created: [SessionRef] = []
            for index in 1...6 {
                let s = try await c.newSession("I\(index)", amount: 5100 + index)
                try await c.settle(); c.expect(s, client: 1, sessions: 1, config: 1)
                created.append(s)
            }
            c.bind(created[0], container: 2)
            try await c.settle(); c.expect(created[0], client: 1)
            c.bind(created[5], container: 3)
            try await c.settle(); c.expect(created[5])
        },
    ]
}
