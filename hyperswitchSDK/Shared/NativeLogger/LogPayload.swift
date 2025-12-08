//
//  LogPayload.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

struct LogPayload: Codable {
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
            return nil
        }
    }
}

enum LogType: String, Codable {
    case DEBUG, INFO, ERROR, WARNING
}

enum LogCategory: String, Codable {
    case API, USER_ERROR, USER_EVENT, MERCHANT_EVENT, OTA_LIFE_CYCLE
}

enum EventName: String, Codable {
    case HYPER_OTA_INIT, HYPER_OTA_FINISH , HYPER_OTA_EVENT, CLICK_TO_PAY_FLOW
}
