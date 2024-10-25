//
//  SwiftUIManager.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 02/12/22.
//

import SwiftUI

struct ViewControllerHolder {
    weak var value: UIViewController?
}

@available(iOS 13.0, *)
struct ViewControllerKey: EnvironmentKey {
    static var defaultValue: ViewControllerHolder {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return ViewControllerHolder(value: windowScene?.windows.first?.rootViewController)
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    var viewController: UIViewController? {
        get { return self[ViewControllerKey.self].value }
        set { self[ViewControllerKey.self].value = newValue }
    }
}
