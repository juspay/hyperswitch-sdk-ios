//
//  PaymentHandler.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 10/05/23.
//

public class PaymentHandler: NSObject {
    
    @objc public static let sharedHandler: PaymentHandler = PaymentHandler()
    @objc var completion: PaymentHandlerActionPaymentIntentCompletionBlock?
    @objc public class func shared() -> PaymentHandler {
        return PaymentHandler.sharedHandler
    }
    internal init(apiClient: APIClient = .shared)
    {
        self.apiClient = apiClient
        super.init()
    }
    internal var apiClient: APIClient
    
    @objc(confirmPayment:withAuthenticationContext:completion:)
    public func confirmPayment(
        _ paymentParams: PaymentIntentParams,
        with authenticationContext: UIViewController,
        completion: @escaping PaymentHandlerActionPaymentIntentCompletionBlock
    )
    {
        self.completion = completion
        
        RNViewManager.sharedInstance.responseHandler = self
        HyperModule.shared?.confirm(data: paymentParams.description())
    }
    public typealias PaymentHandlerActionPaymentIntentCompletionBlock = (
        PaymentHandlerActionStatus, PaymentIntent?, NSError?
    ) -> Void
    
    @objc public enum PaymentHandlerActionStatus: Int {
        case succeeded
        case canceled
        case failed
    }
}

public class PaymentIntent: NSObject {
    
}

extension PaymentHandler: RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) {
        if let completion = completion {
            if let error = error {
                completion(.failed, nil, error as NSError)
            }
            else if response == "cancelled" {
                completion(.canceled, nil, nil)
            }
            else {
                completion(.succeeded, nil, nil)
            }
        }
    }
}
