//
//  LogBuilder.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

enum LogType: String, Codable {
    case DEBUG, INFO, ERROR, WARNING
}

enum LogCategory: String, Codable {
    case API, USER_ERROR, USER_EVENT, MERCHANT_EVENT, OTA_LIFE_CYCLE
}

enum EventName: String, Codable {
    case HYPER_OTA_INIT, HYPER_OTA_FINISH , HYPER_OTA_EVENT
}

struct Log: Codable {
    let timestamp: String
    let log_type: LogType
    let component: String
    let category: LogCategory
    let version: String
    let code_push_version: String
    let client_core_version: String
    let value: String
    let internal_metadata: String
    let session_id: String
    var merchant_id: String
    let payment_id: String
    let app_id: String?
    let platform: String
    let user_agent: String
    let event_name: EventName
    let latency: String?
    let first_event: String
    let payment_method: String?
    let payment_experience: String?
    let source: String
    
    func toJson() -> String? {
        do {
            let jsonData = try JSONEncoder().encode(self)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error encoding log to JSON: \(error.localizedDescription)")
            return nil
        }
    }
}




class LogBuilder {
    private var timestamp: String = ""
    private var logType: LogType = .INFO
    private var component: String = "MOBILE"
    private var category: LogCategory = .OTA_LIFE_CYCLE
    private var version: String = SDKVersion.current
    private var codePushVersion: String = "0.0.2"
    private var clientCoreVersion: String = ""
    private var value: String = ""
    private var internalMetadata: String = ""
    private var sessionId: String = ""
    private var merchantId: String = ""
    private var paymentId: String = ""
    private var appId: String? = nil
    private var platform: String = "IOS"
    private var userAgent: String = ""
    private var eventName: EventName = .HYPER_OTA_INIT
    private var latency: String? = nil
    private var firstEvent: Bool = false
    private var paymentMethod: String? = nil
    private var paymentExperience: String? = nil
    private var source: String = ""
    
    func setLogType(_ logType: String) -> LogBuilder {
        switch logType.uppercased() {
        case "ERROR":
            self.logType = .ERROR
            break
        case "WARNING":
            self.logType = .WARNING
            break
        case "DEBUG":
            self.logType = .DEBUG
            break
        default:
            self.logType = .INFO
        }
        return self
    }
    
    func setClientCoreVersion(_ clientCoreVersion: String) -> LogBuilder {
        self.clientCoreVersion = clientCoreVersion
        return self
    }
    
    func setValue(_ value: String) -> LogBuilder {
        self.value = value
        return self
    }
    
    func setEventName(_ eventName: EventName) -> LogBuilder {
        self.eventName = eventName
        return self
    }
    
    func build() -> Log {
        self.timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        return Log(
            timestamp: timestamp,
            log_type: logType,
            component: component,
            category: category,
            version: version,
            code_push_version: codePushVersion,
            client_core_version: clientCoreVersion,
            value: value,
            internal_metadata: internalMetadata,
            session_id: sessionId,
            merchant_id: merchantId,
            payment_id: paymentId,
            app_id: appId,
            platform: platform,
            user_agent: userAgent,
            event_name: eventName,
            latency: latency,
            first_event: firstEvent ? "true" : "false",
            payment_method: paymentMethod,
            payment_experience: paymentExperience,
            source: source
        )
    }
}


