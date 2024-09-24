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
    private func presentWithRootView(from presentingViewController: UIViewController, rootView: RCTRootView, completion: @escaping (PaymentSheetResult) -> ()) {
        
        /// Set the completion closure for handling the payment sheet result.
        self.completion = completion
        
        /// Set the response handler for the RNViewManager to be the current PaymentSheet instance.
        RNViewManager.sharedInstance.responseHandler = self
        
        /// Create a new UIViewController to present the payment sheet view.
        let paymentSheetViewController = HyperUIViewController()
        
        /// Set the modal presentation style to cover the entire screen.
        paymentSheetViewController.modalPresentationStyle = .overFullScreen
        
        /// Set the view of the payment sheet view controller to the provided root view.
        paymentSheetViewController.view = rootView
        
        /// Present the payment sheet view controller modally from the presenting view controller.
        presentingViewController.present(paymentSheetViewController, animated: false)
    }
    
    /// Method to present the payment sheet view with the default configuration.
    func present(from presentingViewController: UIViewController, completion: @escaping (PaymentSheetResult) -> ()) {
        
        // Present the payment sheet view with the root view obtained from the getRootView() method.
        self.presentWithRootView(from: presentingViewController, rootView: self.getRootView(), completion: completion)
    }
    
    /// Method to present the payment sheet view with custom parameters.
    func presentWithParams(from presentingViewController: UIViewController, props: [String: Any], completion: @escaping ((PaymentSheetResult) -> ())) {
        
        // Present the payment sheet view with the root view obtained from the getRootViewWithParams() method.
        self.presentWithRootView(from: presentingViewController, rootView: self.getRootViewWithParams(props: props), completion: completion)
    }
}
