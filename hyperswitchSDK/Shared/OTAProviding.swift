//
//  OTAProviding.swift
//  HyperswitchShared
//
//  Created by Harshit Srivastava on 26/09/26.
//

import Foundation

@objc(HyperswitchOTAProviding)
package protocol HyperswitchOTAProviding: NSObjectProtocol {
    /// Starts looking for updates of the JavaScript packaged in [baseBundle].
    init(publishableKey: String, baseBundle: Bundle)
    /// The JavaScript to load: the latest downloaded update, or else the packaged bundle.
    func bundleURL() -> URL?
}

package enum OTAProvider {
    /// The class name the Airborne plugin registers its provider under.
    static let className = "HyperswitchAirborneOTAProvider"

    /// The Airborne plugin's provider, started for [publishableKey], or nil when the app does
    /// not link the plugin.
    package static func start(publishableKey: String, baseBundle: Bundle) -> (any HyperswitchOTAProviding)? {
        guard let providerType = NSClassFromString(className) as? HyperswitchOTAProviding.Type else { return nil }
        return providerType.init(publishableKey: publishableKey, baseBundle: baseBundle)
    }
}
