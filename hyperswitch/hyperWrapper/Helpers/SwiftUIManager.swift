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

extension UIViewController {
    @available(iOS 13.0, *)
    func present<Content: View>(style: UIModalPresentationStyle = .automatic, @ViewBuilder builder: () -> Content) {
        
        let toPresent = UIHostingController(rootView: builder())
        toPresent.view.backgroundColor = UIColor.clear
        toPresent.modalPresentationStyle = style
        self.present(toPresent, animated: false, completion: nil)
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    var viewController: UIViewController? {
        get { return self[ViewControllerKey.self].value }
        set { self[ViewControllerKey.self].value = newValue }
    }
}
