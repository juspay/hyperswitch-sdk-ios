//
//  PaymentMethodManagementWidget.swift
//  hyperswitch
//
//  Created by Shivam Nan on 18/10/24.
//

import Foundation
import UIKit
import WebKit

/// PaymentSheetResult is an enum that represents the possible outcomes of a payment sheet operation.
@frozen public enum PaymentMethodManagementResult {
    case closed(data: String)
    case failed(error: Error)
}

internal class PaymentMethodManagementWidget: UIControl {
    internal static var onAddPaymentMethod: (() -> Void)?
    private var completion: ((PaymentMethodManagementResult) -> ())?
    
    // Initialize the widget with the ephemeral key and configuration.
    public init(onAddPaymentMethod: (() -> Void)?, completion: @escaping (PaymentMethodManagementResult) -> ()) {
        PaymentMethodManagementWidget.onAddPaymentMethod = onAddPaymentMethod
        self.completion = completion
        super.init(frame: .zero)
        commonInit()
    }
    
    required public init?(
        coder: NSCoder
    ) {
        super.init(coder: coder)
        commonInit()
    }
    
    public override init(
        frame: CGRect
    ) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        let hyperParams = HyperParams.getHyperParams()
        
        // Prepare the props to send to the React Native module.
        let props: [String : Any] = [
            "type": "paymentMethodsManagement",
            "hyperParams": hyperParams,
            "ephemeralKey": PaymentSession.ephemeralKey ?? "",
            "publishableKey": APIClient.shared.publishableKey as Any,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customLogUrl": APIClient.shared.customLogUrl as Any,
            "customParams": APIClient.shared.customParams as Any,
        ]
        
        RNViewManager.sharedInstance.responseHandler = self
        
        // Get the React Native view from RNViewManager.
        let rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props])
        
        rootView.frame = self.bounds
        
        // Add the React Native view to the current view.
        addSubview(rootView)
        
        rootView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rootView.topAnchor.constraint(equalTo: self.topAnchor),
            rootView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            rootView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            rootView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
}

/// An extension that conforms to the RNResponseHandler protocol, which handles the response from the payment sheet operation.
extension PaymentMethodManagementWidget: RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) {
        if let completion = completion {
            if let error = error {
                completion(.failed(error: error))
            }
            else if (response == "cancelled"){
                completion(.closed(data: "cancelled"))
            }
            else {
                completion(.closed(data: response ?? "failed"))
            }
        }
    }
}

