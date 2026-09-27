//
//  PaymentsRuntimeEntryPoint.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 26/09/26.
//

import Foundation
import HyperswitchShared

@objc(HyperswitchPaymentsRuntime)
internal final class PaymentsRuntimeEntryPoint: NSObject, PaymentsRuntimeEntry {

    static func warmUp(configuration: HyperswitchConfiguration) {
        RNViewManager.shared.startOTA(publishableKey: configuration.publishableKey)
        RNViewManager.shared.warmUp()
    }

    static func activate(_ session: PaymentSession) async {
        session.runtime = PaymentSessionReactRuntime()
        await session.activateRuntime()
    }
}

extension PaymentSession {
    /// This session's surfaces on the payments React host.
    internal var reactRuntime: PaymentSessionReactRuntime {
        if let runtime = runtime as? PaymentSessionReactRuntime {
            return runtime
        }
        let runtime = PaymentSessionReactRuntime()
        self.runtime = runtime
        return runtime
    }
}

extension PaymentSessionReactRuntime: PaymentSessionRuntime {
    func updateIntent(
        of session: PaymentSession,
        authorizationProvider: @escaping (@escaping (String) -> Void) -> Void,
        completion: @escaping (UpdateIntentResult) -> Void
    ) {
        session.updateIntentOnReactHost(authorizationProvider: authorizationProvider, completion: completion)
    }
}
