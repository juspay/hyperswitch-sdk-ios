//
//  Helper.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 22/10/24.
//

import Foundation

enum Helper {

    static func getInfoPlist(_ key: String) -> String? {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let value = infoDictionary[key] as? String, !value.isEmpty else {
            return nil
        }
        return value
    }

    /// Dedicated serial queue protecting the read-then-write block
    private static let uuidQueue = DispatchQueue(label: "io.hyperswitch.helper.uuid")

    static func persistentUUID(for flow: String) -> String {
        uuidQueue.sync {
            /// never call this using another uuidQueue.sync (deadlock)
            let safeFlow = flow.lowercased().replacingOccurrences(of: " ", with: "_")
            let key = "uuid_\(safeFlow)"
            let defaults = UserDefaults.standard

            if let existing = defaults.string(forKey: key) {
                return existing
            }

            let newUUID = UUID().uuidString
            defaults.set(newUUID, forKey: key)
            return newUUID
        }
    }
}
