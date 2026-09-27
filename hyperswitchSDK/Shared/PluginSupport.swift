//
//  PluginSupport.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 26/09/26.
//

import Foundation

package enum PluginSupport {

    /// Whether [publishableKey] belongs to the sandbox environment.
    package static func isSandbox(publishableKey: String) -> Bool {
        SDKEnvironment.getEnvironment(publishableKey) == .SANDBOX
    }

    /// Adds an OTA update event, reported by HyperOTA under [key], to the SDK's native log.
    package static func logOTAEvent(key: String?, level: String, value: String) {
        let eventName: EventName
        switch key {
        case "init_with_local_config_versions", "init":
            eventName = .hyperOTAInit
        case "update_end", "end":
            eventName = .hyperOTAFinish
        default:
            eventName = .hyperOTAEvent
        }
        LogManager.addLog(LogBuilder().setLogType(level).setValue(value).setEventName(eventName).build())
    }
}
