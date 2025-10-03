import XCTest
@testable import hyperswitchSDK
import UIKit

final class AppearanceCodableTests: XCTestCase {

    // MARK: - Helpers

    private func json(_ data: Data) throws -> Any {
        try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    private func jsonObject(_ data: Data) throws -> [String: Any] {
        (try json(data) as? [String: Any]) ?? [:]
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        let enc = JSONEncoder()
        // Do NOT change keys formatting; must match current API
        return try enc.encode(value)
    }

    // MARK: - UIColor

    func testUIColorEncodesToHex_noAlphaWhenOpaque() throws {
        let color = UIColor(red: 1, green: 0, blue: 0, alpha: 1) // #FF0000
        let data = try encode(color)
        let hex = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(hex.replacingOccurrences(of: "\"", with: ""), "#FF0000")
    }

    func testUIColorEncodesToHex_withAlphaWhenNotOpaque() throws {
        let color = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5) // #FF000080
        let data = try encode(color)
        let hex = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(hex.replacingOccurrences(of: "\"", with: ""), "#FF000080")
    }

    // MARK: - UIFont

    func testUIFontEncodesToNameOnly() throws {
        // Use a widely available font
        let f = UIFont(name: "Helvetica", size: 42) ?? UIFont.systemFont(ofSize: 42)
        let data = try encode(f)
        let name = try XCTUnwrap(String(data: data, encoding: .utf8)).replacingOccurrences(of: "\"", with: "")
        // Should be *only* the font name (not an object)
        XCTAssertFalse(name.contains("{"))
        XCTAssertEqual(name, f.fontName)
    }

    // MARK: - Theme

    func testThemeRawValues() throws {
        XCTAssertEqual(PaymentSheet.Appearance.Theme.default.rawValue, "Default")
        XCTAssertEqual(PaymentSheet.Appearance.Theme.light.rawValue, "Light")
        XCTAssertEqual(PaymentSheet.Appearance.Theme.dark.rawValue, "Dark")
        XCTAssertEqual(PaymentSheet.Appearance.Theme.minimal.rawValue, "Minimal")
        XCTAssertEqual(PaymentSheet.Appearance.Theme.flatMinimal.rawValue, "FlatMinimal")
    }

    // MARK: - Compatibility with DictionaryConverter

    func testColors_CodableMatchesToDictionary() throws {
        var colors = PaymentSheet.Appearance.Colors()
        colors.primary = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
        colors.background = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.5)
        colors.icon = UIColor.black

        // Old path (DictionaryConverter)
        // Requires keeping DictionaryConverter for now (as reviewer requested)
        let dictOld = (colors as DictionaryConverter).toDictionary()

        // New path (Codable -> JSON -> [String:Any])
        let jsonNew = try jsonObject(try encode(colors))

        // Compare string fields one by one (avoid ordering issues)
        func val(_ key: String, _ obj: [String: Any]) -> String? { obj[key] as? String }
        let keys = ["primary","background","icon"]
        for k in keys {
            XCTAssertEqual(val(k, dictOld), val(k, jsonNew), "Mismatch for key \(k)")
        }
    }

    func testPrimaryButton_CodableMatchesToDictionary() throws {
        var btn = PaymentSheet.Appearance.PrimaryButton()
        btn.backgroundColor = UIColor(red: 0.1, green: 0.8, blue: 0.2, alpha: 1)
        btn.textColor = UIColor.white
        btn.cornerRadius = 12
        btn.borderWidth = 2
        btn.borderColor = UIColor.black
        btn.font = UIFont(name: "Helvetica-Bold", size: 20)

        let dictOld = (btn as DictionaryConverter).toDictionary()
        let jsonNew = try jsonObject(try encode(btn))

        // Compare subset that was present in the old dictionary
        let keys = ["backgroundColor","textColor","cornerRadius","borderWidth","borderColor","font"]
        for k in keys {
            // Numbers come back as NSNumber; stringify for robust compare
            let oldVal = "\(dictOld[k] ?? "nil")"
            let newVal = "\(jsonNew[k] ?? "nil")"
            XCTAssertEqual(oldVal, newVal, "Mismatch for key \(k)")
        }
    }

    // MARK: - Round-trip

    func testAppearance_roundTrip() throws {
        var a = PaymentSheet.Appearance()
        a.cornerRadius = 10
        a.borderWidth = 1
        a.theme = .light
        a.colors.primary = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        a.font.base = UIFont(name: "Helvetica", size: 17)
        a.primaryButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)

        let data = try encode(a)
        let decoded = try JSONDecoder().decode(PaymentSheet.Appearance.self, from: data)
        XCTAssertEqual(a.cornerRadius, decoded.cornerRadius)
        XCTAssertEqual(a.borderWidth, decoded.borderWidth)
        XCTAssertEqual(a.theme, decoded.theme)
        XCTAssertEqual(a.colors.primary?.cgColor.__unsafeEqualTo(decoded.colors.primary?.cgColor), true)
        XCTAssertEqual(a.primaryButton.cornerRadius, decoded.primaryButton.cornerRadius)
        XCTAssertEqual(a.font.base?.fontName, decoded.font.base?.fontName)
    }
}

// MARK: - Tiny CGColor comparator to avoid flakiness
private extension CGColor {
    func __unsafeEqualTo(_ other: CGColor?) -> Bool {
        guard let other else { return false }
        return self == other || self.components == other.components
    }
}
