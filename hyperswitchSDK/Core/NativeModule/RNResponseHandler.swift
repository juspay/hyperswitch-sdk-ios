//
//  RNResponseHandler.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 22/10/24.
//

import Foundation

internal protocol RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) -> Void
}