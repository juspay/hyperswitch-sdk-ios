//
//  HyperAPI.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 10/05/23.
//

@objc public class HyperAPI: NSObject {
    
    @objc public static var defaultPublishableKey: String?
    @objc public static var customBackendUrl: String?
    @objc public static var customParams: [String : Any]?
    @objc public static var customLogUrl: String?
}
