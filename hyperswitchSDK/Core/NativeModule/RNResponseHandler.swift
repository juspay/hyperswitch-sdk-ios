//
//  RNResponseHandler.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 22/10/24.
//

import Foundation
import HyperswitchShared

internal protocol RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?)
}
