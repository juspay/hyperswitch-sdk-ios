//
//  ApplePayViewManager.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 20/06/24.
//

import PassKit
import UIKit

@objc(ApplePayViewManager)
class ApplePayViewManager: RCTViewManager {
    
    override func view() -> (ApplePayView) {
        return ApplePayView()
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
    }
}

class ApplePayView : UIView {
    
    private var button: PKPaymentButton?
    private var paymentHandler = ApplePayHandler()
    private var applePayRequestData: String?
    @objc private var onPaymentResultCallback: RCTDirectEventBlock?
    
    @objc var buttonStyle: String = "" {
        didSet {
            setButton(setButtonType:buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadius)
        }
    }
    @objc var buttonType: String = "" {
        didSet {
            setButton(setButtonType:buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadius)
        }
    }
    @objc var color: String = "" {
        didSet {
            setButton(setButtonType:buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadius)
        }
    }
    @objc var cornerRadius: CGFloat = 0.0 {
        didSet {
            setButton(setButtonType: buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadius)
        }
    }
    @objc var requestData: String = "" {
        didSet {
            applePayRequestData = requestData
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let cornerRadiusValue: CGFloat = 4.0
        let buttonType = "plain"
        let buttonStyle = "black"
        setButton(setButtonType: buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadiusValue)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setButton(setButtonType: String?, setButtonStyle: String?, setButtonCornerRadius cornerRadius: CGFloat?) {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        var type: PKPaymentButtonType
        var style: PKPaymentButtonStyle
        
        switch setButtonType {
        case "buy":
            type = .buy
        case "setUp":
            type = .setUp
        case "inStore":
            type = .inStore
        case "donate":
            type = .donate
        case "checkout":
            type = .checkout
        case "book":
            type = .book
        case "subscribe":
            type = .subscribe
        default:
            type = .plain
        }
        
        switch setButtonStyle {
        case "white":
            style = .white
        case "whiteOutline":
            style = .whiteOutline
        default:
            style = .black
        }
        
        button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        button?.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        if let cornerRadius = cornerRadius {
            button?.cornerRadius = cornerRadius
        }
        
        if let buttonView = button{
            addSubview(buttonView)
        }
    }
    
    @objc private func touchUpInside(_ button: PKPaymentButton) {
        if let onPaymentResultCallback = onPaymentResultCallback {
            if let data = applePayRequestData {
                paymentHandler.startPayment(rnMessage: data, rnCallback: onPaymentResultCallback)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        button?.frame = bounds
    }
}
