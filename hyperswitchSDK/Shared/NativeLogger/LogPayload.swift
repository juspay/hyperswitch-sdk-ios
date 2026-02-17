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
    case hyperOTAInit = "HYPER_OTA_INIT"
    case hyperOTAFinish = "HYPER_OTA_FINISH"
    case hyperOTAEvent = "HYPER_OTA_EVENT"

    case authenticationSession = "AUTHENTICATION_SESSION"
    case authenticationSessionInit = "AUTHENTICATION_SESSION_INIT"
    case authenticationSessionReturned = "AUTHENTICATION_SESSION_RETURNED"

    case initClickToPaySession = "INIT_CLICK_TO_PAY_SESSION"
    case initClickToPaySessionInit = "INIT_CLICK_TO_PAY_SESSION_INIT"

    case createWebviewInit = "CREATE_WEBVIEW_INIT"
    case createWebviewReturned = "CREATE_WEBVIEW_RETURNED"
    case initClickToPaySessionWebInit = "INIT_CLICK_TO_PAY_SESSION_WEB_INIT"
    case initClickToPaySessionWebReturned = "INIT_CLICK_TO_PAY_SESSION_WEB_RETURNED"
    case initClickToPaySessionReturned = "INIT_CLICK_TO_PAY_SESSION_RETURNED"
    case getActiveClickToPaySession = "GET_ACTIVE_CLICK_TO_PAY_SESSION"
    case getActiveClickToPaySessionInit = "GET_ACTIVE_CLICK_TO_PAY_SESSION_INIT"
    case getActiveClickToPaySessionWebInit = "GET_ACTIVE_CLICK_TO_PAY_SESSION_WEB_INIT"
    case getActiveClickToPaySessionWebReturned = "GET_ACTIVE_CLICK_TO_PAY_SESSION_WEB_RETURNED"
    case getActiveClickToPaySessionReturned = "GET_ACTIVE_CLICK_TO_PAY_SESSION_RETURNED"
    case isCustomerPresent = "IS_CUSTOMER_PRESENT"
    case isCustomerPresentInit = "IS_CUSTOMER_PRESENT_INIT"
    case isCustomerPresentWebInit = "IS_CUSTOMER_PRESENT_WEB_INIT"
    case isCustomerPresentWebReturned = "IS_CUSTOMER_PRESENT_WEB_RETURNED"
    case isCustomerPresentReturned = "IS_CUSTOMER_PRESENT_RETURNED"
    case getUserType = "GET_USER_TYPE"
    case getUserTypeInit = "GET_USER_TYPE_INIT"
    case getUserTypeWebInit = "GET_USER_TYPE_WEB_INIT"
    case getUserTypeWebReturned = "GET_USER_TYPE_WEB_RETURNED"
    case getUserTypeReturned = "GET_USER_TYPE_RETURNED"
    case getRecognisedCards = "GET_RECOGNISED_CARDS"
    case getRecognisedCardsInit = "GET_RECOGNISED_CARDS_INIT"
    case getRecognisedCardsWebInit = "GET_RECOGNISED_CARDS_WEB_INIT"
    case getRecognisedCardsWebReturned = "GET_RECOGNISED_CARDS_WEB_RETURNED"
    case getRecognisedCardsReturned = "GET_RECOGNISED_CARDS_RETURNED"
    case validateCustomerAuthentication = "VALIDATE_CUSTOMER_AUTHENTICATION"
    case validateCustomerAuthenticationInit = "VALIDATE_CUSTOMER_AUTHENTICATION_INIT"
    case validateCustomerAuthenticationWebInit = "VALIDATE_CUSTOMER_AUTHENTICATION_WEB_INIT"
    case validateCustomerAuthenticationWebReturned = "VALIDATE_CUSTOMER_AUTHENTICATION_WEB_RETURNED"
    case validateCustomerAuthenticationReturned = "VALIDATE_CUSTOMER_AUTHENTICATION_RETURNED"
    case checkout = "CHECKOUT"
    case checkoutInit = "CHECKOUT_INIT"
    case checkoutWebInit = "CHECKOUT_WEB_INIT"
    case createNewWebviewInit = "CREATE_NEW_WEBVIEW_INIT"
    case createNewWebviewReturned = "CREATE_NEW_WEBVIEW_RETURNED"
    case checkoutWebReturned = "CHECKOUT_WEB_RETURNED"
    case closeNewWebview = "CLOSE_NEW_WEBVIEW"
    case checkoutReturned = "CHECKOUT_RETURNED"
    case signOut = "SIGN_OUT"
    case signOutInit = "SIGN_OUT_INIT"
    case signOutWebInit = "SIGN_OUT_WEB_INIT"
    case signOutWebReturned = "SIGN_OUT_WEB_RETURNED"
    case signOutReturned = "SIGN_OUT_RETURNED"
    case close = "CLOSE"
    case closeInit = "CLOSE_INIT"
    case closeWebviewInit = "CLOSE_WEBVIEW_INIT"
    case closeWebviewReturned = "CLOSE_WEBVIEW_RETURNED"
    case closeReturned = "CLOSE_RETURNED"
    case webview = "WEBVIEW"
}
