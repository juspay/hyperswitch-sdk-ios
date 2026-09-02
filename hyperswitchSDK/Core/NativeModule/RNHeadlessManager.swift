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

/// Tracks the temporary off-screen root views used for headless work.
/// Headless roots mount on the SAME ReactHost as visible UI (RNViewManager),
/// so the JS module cache (PrefetchCache) is shared between headless tasks and
/// sheets/widgets — no second JS runtime, no native data handoff.
///
/// There is intentionally no factory/bridge of its own and no reinvalidateBridge:
/// recreating a ReactHost here would tear down the shared UI runtime.
internal class RNHeadlessManager: NSObject {

    internal var responseHandler: RNResponseHandler?
    internal private(set) var rootView: UIView?

    internal static let sharedInstance = RNHeadlessManager()

    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?) -> UIView {
        let rootView = RNViewManager.sharedInstance.widgetViewForModule(
            moduleName,
            initialProperties: initialProperties
        )
        self.rootView = rootView
        return rootView
    }

    /// Unmounts one completed headless root without disturbing shared JS module state.
    internal func releaseRootView(_ completedRootView: UIView) {
        guard rootView === completedRootView else { return }
        rootView = nil
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
