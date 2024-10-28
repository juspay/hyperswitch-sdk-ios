//
//  Helper.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 22/10/24.
//

import Foundation

internal func getInfoPlist(_ key: String) -> String? {
    guard let infoDictionary = Bundle.main.infoDictionary,
          let value = infoDictionary[key] as? String, !value.isEmpty else {
        return nil
    }
    return value
}