//
//  HyperswitchEnvironment.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 18/05/26.
//

/// Raw values match the JS payment-methods package's `HyperswitchEnvironment` union
/// (`'PROD' | 'SANDBOX' | 'INTEG'`) and Android's `HyperswitchEnvironment.name` — this is
/// passed through as a plain string via `HyperswitchConfiguration.toDictionary()`, so a
/// mismatch here silently resolves the wrong vault-details base URL on the JS side.
public enum HyperswitchEnvironment: String, Codable {
    case production = "PROD"
    case sandbox = "SANDBOX"
    case integ = "INTEG"
}
