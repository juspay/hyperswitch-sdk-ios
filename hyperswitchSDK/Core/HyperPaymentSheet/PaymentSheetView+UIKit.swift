//
//  PaymentSheetView+UIKit.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 15/12/23.
//

import Foundation
import React

/// Extension on the PaymentSheet class to handle the presentation of the payment sheet view.
internal extension PaymentSheet {

    /// Method to present the payment sheet view with a given root view and completion handler.
    private func presentWithRootView(
        from presentingViewController: UIViewController,
        rootView: RCTRootView,
        completion: @escaping (PaymentResult) -> Void
    ) {

        self.completion = completion

        let paymentSheetViewController = HyperUIViewController()
        paymentSheetViewController.paymentSheet = self
        paymentSheetViewController.modalPresentationStyle = .overFullScreen
        paymentSheetViewController.view = rootView

        /// Present the payment sheet view controller modally from the presenting view controller.
        presentingViewController.present(paymentSheetViewController, animated: false)
    }

    /// Method to present the payment sheet view with the default configuration.
    func present(from presentingViewController: UIViewController, completion: @escaping (PaymentResult) -> Void) {

        // Present the payment sheet view with the root view obtained from the getRootView() method.
        self.presentWithRootView(from: presentingViewController, rootView: self.getRootView(), completion: completion)
    }

    /// Method to present the payment sheet view with custom parameters.
    func presentWithParams(
        from presentingViewController: UIViewController,
        props: [String: Any],
        completion: @escaping ((PaymentResult) -> Void)
    ) {

        // Present the payment sheet view with the root view obtained from the getRootViewWithParams() method.
        self.presentWithRootView(from: presentingViewController, rootView: self.getRootViewWithParams(props: props), completion: completion)
    }
}
