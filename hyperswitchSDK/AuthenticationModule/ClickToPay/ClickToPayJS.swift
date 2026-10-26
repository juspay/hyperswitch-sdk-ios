//
//  ClickToPayJS.swift
//  hyperswitch
//

import Foundation

/// Builds JavaScript literals for values passed into the Click to Pay web views.
///
/// Values must never be interpolated into JavaScript source as raw text: a quote,
/// backslash or `</script>` inside a server-, merchant- or user-supplied value would
/// end its string literal and run as code in a web view that handles card data.
/// Every literal produced here is JSON (which is valid JavaScript) and is also safe
/// inside an inline HTML `<script>` block.
enum ClickToPayJS {

    /// A JavaScript string literal for `value`.
    static func string(_ value: String) -> String {
        encode(value) ?? "\"\""
    }

    /// A JavaScript object literal containing the `entries` whose value is not nil.
    static func object(_ entries: KeyValuePairs<String, Any?>) -> String {
        var dictionary = [String: Any]()
        for (key, value) in entries {
            if let value = value {
                dictionary[key] = value
            }
        }
        return encode(dictionary) ?? "{}"
    }

    /// A JavaScript literal for a value received as JSON text, such as the token
    /// returned by the UCTP session. Objects and arrays are re-serialised, so only
    /// well-formed data reaches the page; anything else is passed as a string.
    static func json(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8),
            let value = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
            value is [String: Any] || value is [Any],
            let encoded = encode(value)
        else {
            return string(raw)
        }
        return encoded
    }

    private static func encode(_ value: Any) -> String? {
        guard
            let data = try? JSONSerialization.data(
                withJSONObject: value,
                options: [.fragmentsAllowed, .sortedKeys]
            ),
            let text = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return harden(text)
    }

    // JSON escapes quotes, backslashes and control characters. Inside an HTML
    // <script> block, "</script>" and "<!--" still end or change the script, and
    // U+2028/U+2029 end lines in older JavaScript engines, so escape those too.
    private static func harden(_ json: String) -> String {
        var result = ""
        result.reserveCapacity(json.count)
        for scalar in json.unicodeScalars {
            switch scalar {
            case "<": result += "\\u003c"
            case ">": result += "\\u003e"
            case "&": result += "\\u0026"
            case "\u{2028}": result += "\\u2028"
            case "\u{2029}": result += "\\u2029"
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result
    }
}
