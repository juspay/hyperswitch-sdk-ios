//
//  SDKEnvironment.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//


enum SDKEnvironment {
    case PROD, SANDBOX

    static func checkEnvironment(publishableKey: String) -> SDKEnvironment {
        return publishableKey.contains("sandbox") || publishableKey.contains("_snd_") ? .SANDBOX : .PROD
    }
}
