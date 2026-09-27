//
//  ThreeDSProviderFactory.swift
//  AuthenticationSdk
//
//  Created by Shivam Nan on 02/09/25.
//

import Foundation
import HyperswitchShared

public class ThreeDSProviderFactory {

    public static func createProvider(preferredProvider: ThreeDSProviderType? = nil) throws -> ThreeDSProvider {

        let availableProviders = getAvailableProviders()

        // No providers available
        if availableProviders.isEmpty {
            throw AuthenticationError.noProviderAvailable(
                "No 3DS SDK provider found. Please ensure at least one supported 3DS SDK framework (Netcetera, Trident) is included in your project."
            )
        }

        // If preferred provider is specified, try that
        if let preferred = preferredProvider {
            if let provider = tryCreateProvider(type: preferred) {
                return provider
            }
            throw AuthenticationError.preferredProviderUnavailable(
                "Preferred provider '\(preferred.displayName)' is not available. Available providers: \(availableProviders.map { $0.displayName }.joined(separator: ", "))"
            )
        }

        // No preference specified
        if availableProviders.count == 1 {
            // Only one provider available, use it automatically
            if let provider = tryCreateProvider(type: availableProviders[0]) {
                return provider
            } else {
                throw AuthenticationError.noProviderAvailable(
                    "No 3DS SDK provider found. Please ensure at least one supported 3DS SDK framework (Netcetera,  Trident) is included in your project."
                )
            }
        } else {
            // Multiple providers available, require explicit selection
            throw AuthenticationError.noProviderAvailable(
                "Multiple 3DS SDK providers are available: \(availableProviders.map { $0.displayName }.joined(separator: ", ")). Please specify a preferred provider in your configuration."
            )
        }
    }

    private static func tryCreateProvider(type: ThreeDSProviderType) -> ThreeDSProvider? {
        switch type {
        case .netcetera:
            let entry = NSClassFromString(ThreeDSProviderType.netceteraClassName) as? ThreeDSProviderEntry.Type
            return entry?.makeProvider()

        case .cardinal:
            #if HYPERSWITCH_CARDINAL
            return CardinalProvider()
            #else
            return nil
            #endif

        case .trident:
            #if HYPERSWITCH_TRIDENT
            return TridentProvider()
            #else
            return nil
            #endif
        }
    }

    public static func getAvailableProviders() -> [ThreeDSProviderType] {
        return ThreeDSProviderType.allCases.filter { tryCreateProvider(type: $0) != nil }
    }
}

/// A 3DS provider shipped as a product of its own (HyperswitchAuthenticationNetcetera3DS). The
/// product registers a class conforming to this under a known Objective-C name.
package protocol ThreeDSProviderEntry: AnyObject {
    static func makeProvider() -> ThreeDSProvider
}

extension ThreeDSProviderType {
    /// The Objective-C name of HyperswitchAuthenticationNetcetera3DS's `ThreeDSProviderEntry`.
    static let netceteraClassName = "HyperswitchNetceteraThreeDSProvider"
}
