//
//  ProviderType.swift
//  AuthenticationSdk
//
//  Created by Shivam Nan on 02/09/25.
//

import Foundation

public enum ProviderType: String, CaseIterable {
    case netcetera = "Netcetera"
    case cardinal = "Cardinal"
    case trident = "Trident"
    
    public var displayName: String {
        return self.rawValue
    }
}
