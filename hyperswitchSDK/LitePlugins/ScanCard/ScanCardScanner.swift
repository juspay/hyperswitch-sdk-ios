//
//  ScanCardScanner.swift
//  HyperswitchLiteScanCard
//
//  Created by Harshit Srivastava on 28/09/26.
//

import HyperswitchLite
internal import HyperswitchScanCard
import UIKit

/// How HyperswitchLite finds card scanning when the app links the HyperswitchLiteScanCard
/// product.
@objc(HyperswitchLiteCardScanner)
final class ScanCardScanner: NSObject, LiteCardScanner {
    static func scan(from viewController: UIViewController, completion: @escaping ([String: Any]) -> Void) {
        CardScanSheet().present(from: viewController) { result in
            var callback: [String: Any] = [:]
            switch result {
            case .completed(let card):
                var data: [String: Any] = ["pan": card.pan]
                data["expiryMonth"] = card.expiryMonth
                data["expiryYear"] = card.expiryYear
                callback["status"] = "Succeeded"
                callback["data"] = data
            case .canceled:
                callback["status"] = "Cancelled"
            case .failed:
                callback["status"] = "Failed"
            }
            completion(callback)
        }
    }
}
