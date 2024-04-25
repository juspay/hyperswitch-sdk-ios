//
//  PaymentCardTextField.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 10/05/23.
//

import Foundation

public class PaymentCardTextField: UIControl {
    
    required public init?(
        coder aDecoder: NSCoder
    ) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(
        frame: CGRect
    ) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        commonInit()
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: self.frame.width, height: 52.0)
    }
    
    @objc public var paymentMethodParams: PaymentMethodParams?
    
    func commonInit() {
        
        let cardView =  RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties:
                                                                    ["props":["type": "card",]])
        cardView.backgroundColor = UIColor.clear
        addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        cardView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        cardView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        cardView.heightAnchor.constraint(equalToConstant: 52.0).isActive = true
    }
}
