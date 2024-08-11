import Foundation
import PassKit
import UIKit

@objc(ApplePayButtonView)
class ApplePayButtonView: UIView {
    var applePayButton: PKPaymentButton?
    
    @objc private var onPaymentResultCallback: RCTDirectEventBlock?
    @objc var onPressAction: RCTDirectEventBlock?
    @objc var onShippingMethodSelectedAction: RCTDirectEventBlock?
    @objc var onShippingContactSelectedAction: RCTDirectEventBlock?
    @objc var onCouponCodeEnteredAction: RCTDirectEventBlock?
    @objc var onOrderTrackingAction: RCTDirectEventBlock?
    
    @objc var buttonType: NSString?
    @objc var buttonStyle: NSString?
    @objc var borderRadius: NSNumber?
    @objc var disabled = false
    
    @objc func handleApplePayButtonTapped() {
//        onShippingMethodSelectedAction
//        onShippingContactSelectedAction
//        onCouponCodeEnteredAction
//        onOrderTrackingAction
    }
    
    override func didSetProps(_ changedProps: [String]!) {
        if let applePayButton = self.applePayButton {
            applePayButton.removeFromSuperview()
        }
        
        let paymentButtonType: PKPaymentButtonType = switch buttonType {
            case "buy": .buy
            case "setUp": .setUp
            case "inStore": .inStore
            case "donate": .donate
            case "checkout": .checkout
            case "book": .book
            case "subscribe": .subscribe
            default: .plain
        }
        
        let paymentButtonStyle: PKPaymentButtonStyle = switch buttonStyle {
            case "white": .white
            case "whiteOutline": .whiteOutline
            default: .black
        }
        
        self.applePayButton = PKPaymentButton(paymentButtonType: paymentButtonType, paymentButtonStyle: paymentButtonStyle)
        if #available(iOS 12.0, *) {
            self.applePayButton?.cornerRadius = self.borderRadius as? CGFloat ?? 4.0
        }
        
        if let applePayButton = self.applePayButton {
            applePayButton.isEnabled = !disabled
            applePayButton.addTarget(self, action: #selector(handleApplePayButtonTapped), for: .touchUpInside)
            self.addSubview(applePayButton)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func layoutSubviews() {
        if let applePayButton = self.applePayButton {
            applePayButton.frame = self.bounds
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
