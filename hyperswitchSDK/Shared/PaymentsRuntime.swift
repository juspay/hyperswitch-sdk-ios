//
//  PaymentsRuntime.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 26/09/26.
//

import Foundation

package protocol PaymentsRuntimeEntry: AnyObject {
    /// Boots the payments React host ahead of the first payment session.
    static func warmUp(configuration: HyperswitchConfiguration)
    /// Starts [session] on the payments React host; returns once its surfaces run.
    static func activate(_ session: PaymentSession) async
}

/// The payments SDK's side of a session it runs (`PaymentSession.runtime`).
package protocol PaymentSessionRuntime: AnyObject {
    /// `updateIntent` for [session]: its surfaces refetch with the new authorization first.
    func updateIntent(
        of session: PaymentSession,
        authorizationProvider: @escaping (@escaping (String) -> Void) -> Void,
        completion: @escaping (UpdateIntentResult) -> Void
    )
}

enum PaymentsRuntime {
    /// The payments SDK's entry point, or nil when the app does not link it.
    static var entry: PaymentsRuntimeEntry.Type? {
        NSClassFromString("HyperswitchPaymentsRuntime") as? PaymentsRuntimeEntry.Type
    }
}
