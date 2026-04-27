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
    let authentication_id: String
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
    case hyperOTAInit = "HYPER_OTA_INIT"
    case hyperOTAFinish = "HYPER_OTA_FINISH"
    case hyperOTAEvent = "HYPER_OTA_EVENT"

    case authenticationSessionInit = "AUTHENTICATION_SESSION_INIT"
    case authenticationSessionReturned = "AUTHENTICATION_SESSION_RETURNED"
    case initClickToPaySessionInit = "INIT_CLICK_TO_PAY_SESSION_INIT"
    case initClickToPaySessionReturned = "INIT_CLICK_TO_PAY_SESSION_RETURNED"
    case initClickToPaySessionWebReturned = "INIT_CLICK_TO_PAY_SESSION_WEB_RETURNED"
    case createWebviewInit = "CREATE_WEBVIEW_INIT"
    case createWebviewReturned = "CREATE_WEBVIEW_RETURNED"
    case getActiveClickToPaySessionInit = "GET_ACTIVE_CLICK_TO_PAY_SESSION_INIT"
    case getActiveClickToPaySessionReturned = "GET_ACTIVE_CLICK_TO_PAY_SESSION_RETURNED"
    case isCustomerPresentInit = "IS_CUSTOMER_PRESENT_INIT"
    case isCustomerPresentReturned = "IS_CUSTOMER_PRESENT_RETURNED"
    case getUserTypeInit = "GET_USER_TYPE_INIT"
    case getUserTypeReturned = "GET_USER_TYPE_RETURNED"
    case getRecognisedCardsInit = "GET_RECOGNISED_CARDS_INIT"
    case getRecognisedCardsReturned = "GET_RECOGNISED_CARDS_RETURNED"
    case validateCustomerAuthenticationInit = "VALIDATE_CUSTOMER_AUTHENTICATION_INIT"
    case validateCustomerAuthenticationReturned = "VALIDATE_CUSTOMER_AUTHENTICATION_RETURNED"
    case checkoutInit = "CHECKOUT_INIT"
    case checkoutReturned = "CHECKOUT_RETURNED"
    case createNewWebviewInit = "CREATE_NEW_WEBVIEW_INIT"
    case createNewWebviewReturned = "CREATE_NEW_WEBVIEW_RETURNED"
    case signOutInit = "SIGN_OUT_INIT"
    case signOutReturned = "SIGN_OUT_RETURNED"
    case closeInit = "CLOSE_INIT"
    case closeReturned = "CLOSE_RETURNED"
    case closeWebviewInit = "CLOSE_WEBVIEW_INIT"
    case closeWebviewReturned = "CLOSE_WEBVIEW_RETURNED"
    case checkSessionClosed = "CHECK_SESSION_CLOSED"
    case userContentControllerWebReturned = "USER_CONTENT_CONTROLLER_WEB_RETURNED"
}
