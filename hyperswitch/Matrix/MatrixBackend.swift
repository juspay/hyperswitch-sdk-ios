import Foundation

struct IntentInfo {
    let sdkAuthorization: String
    let paymentId: String
    let publishableKey: String
    let profileId: String
    let amount: Int
    let currency: String
}

struct LedgerRow {
    let seq: Int64
    let method: String
    let path: String
    let authorization: String?
    let fault: String?
}

final class MatrixBackend {
    let serverUrl: URL

    init(serverUrl: URL) {
        self.serverUrl = serverUrl
    }

    func createIntent(amount: Int, currency: String = "USD", customerId: String = "blah11111") async throws -> IntentInfo {
        let json = try await request("GET", "/create-payment-intent?amount=\(amount)&currency=\(currency)&customer_id=\(customerId)")
        guard let auth = json["sdkAuthorization"] as? String, let paymentId = json["paymentId"] as? String,
              let publishableKey = json["publishableKey"] as? String
        else { throw MatrixError("create-payment-intent response is missing fields") }
        return IntentInfo(
            sdkAuthorization: auth,
            paymentId: paymentId,
            publishableKey: publishableKey,
            profileId: json["profileId"] as? String ?? "",
            amount: json["amount"] as? Int ?? amount,
            currency: json["currency"] as? String ?? currency
        )
    }

    func updatePayment(paymentId: String, amount: Int, currency: String = "USD") async throws -> String {
        let json = try await request("POST", "/update-payment", body: ["paymentId": paymentId, "amount": amount, "currency": currency])
        guard let auth = json["sdkAuthorization"] as? String else { throw MatrixError("update-payment response is missing sdkAuthorization") }
        return auth
    }

    func ledger(since: Int64) async throws -> (rows: [LedgerRow], last: Int64) {
        let json = try await request("GET", "/ledger?since=\(since)")
        let rows = (json["rows"] as? [[String: Any]] ?? []).map { row in
            LedgerRow(
                seq: Int64(row["seq"] as? Int ?? 0),
                method: row["method"] as? String ?? "",
                path: row["path"] as? String ?? "",
                authorization: row["authorization"] as? String,
                fault: row["fault"] as? String
            )
        }
        return (rows, Int64(json["last"] as? Int ?? 0))
    }

    func ledgerLast() async throws -> Int64 {
        Int64(try await request("GET", "/ledger/last")["last"] as? Int ?? 0)
    }

    func clearLedger() async throws {
        _ = try await request("DELETE", "/ledger")
    }

    func addFault(pathContains: String, authorization: String, mode: String, statusOrDelayMs: Int, times: Int = 1) async throws -> Int {
        var body: [String: Any] = ["pathContains": pathContains, "authorization": authorization, "mode": mode, "times": times]
        body[mode == "error" ? "status" : "delayMs"] = statusOrDelayMs
        return try await request("POST", "/proxy-control", body: body)["id"] as? Int ?? 0
    }

    func clearFaults() async throws {
        _ = try await request("DELETE", "/proxy-control")
    }

    private func request(_ method: String, _ path: String, body: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: path, relativeTo: serverUrl) else { throw MatrixError("bad url \(path)") }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(status) else {
            throw MatrixError("\(method) \(path) -> HTTP \(status): \(String(data: data, encoding: .utf8) ?? "")")
        }
        if data.isEmpty { return [:] }
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}

struct MatrixError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
