//
//  LiteCardScanner.swift
//  HyperswitchLite
//
//  Created by Harshit Srivastava on 28/09/26.
//

import UIKit

/// Card scanning for the Lite sheet, shipped as a product of its own (HyperswitchLiteScanCard).
/// The product registers a class conforming to this under a known Objective-C name.
package protocol LiteCardScanner: AnyObject {
    /// Presents the scanner over [viewController]; [completion] receives the result as the web
    /// sheet reads it (`status`, and the card under `data`).
    static func scan(from viewController: UIViewController, completion: @escaping ([String: Any]) -> Void)
}

enum LiteCardScanning {
    /// The scanner, or nil when the app does not link HyperswitchLiteScanCard.
    static var scanner: LiteCardScanner.Type? {
        NSClassFromString("HyperswitchLiteCardScanner") as? LiteCardScanner.Type
    }
}
