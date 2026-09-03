//
/*
 RNHeadlessManager.swift
 Hyperswitch
 */
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React

/// Headless roots mount on the SAME ReactHost as visible UI (RNViewManager),
/// so the JS module cache (PrefetchCache) is shared between headless tasks and
/// sheets/widgets — no second JS runtime, no native data handoff.
///
/// There is intentionally no factory/bridge of its own and no reinvalidateBridge:
/// recreating a ReactHost here would tear down the shared UI runtime.
internal class RNHeadlessManager: NSObject {

    internal static let sharedInstance = RNHeadlessManager()

    /// Mounts a headless root on the shared ReactHost. The caller owns the returned view;
    /// dropping the last reference stops its surface (RCTSurfaceHostingView deinit).
    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        return RNViewManager.sharedInstance.widgetViewForModule(
            moduleName,
            initialProperties: initialProperties
        )
    }

    internal func removePrefetchCache(sdkAuthorization: String) {
        guard !sdkAuthorization.isEmpty else { return }
        /* Must go through the module's codegen event channel: the RCTBridge compat layer is
           nil on the bridgeless runtime, so enqueueJSCall would silently drop the event. */
        RNViewManager.sharedInstance.hyperModule.emit(
            "clearPrefetchCache",
            ["sdkAuthorization": sdkAuthorization]
        )
    }
}
