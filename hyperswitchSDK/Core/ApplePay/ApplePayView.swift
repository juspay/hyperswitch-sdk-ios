//
//  ApplePayView.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 20/06/24.
//

import PassKit
import UIKit

@objc(HSApplePayView)
internal class ApplePayView: UIView {

    private var button: PKPaymentButton?
    private var paymentHandler = ApplePayHandler()

    @objc internal var onPaymentResult: (() -> Void)?

    @objc internal var buttonStyle: String = "" {
        didSet {
            setButton(setButtonType: buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadius)
        }
    }
    @objc internal var buttonType: String = "" {
        didSet {
            setButton(setButtonType: buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadius)
        }
    }
    @objc internal var color: String = "" {
        didSet {
            setButton(setButtonType: buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadius)
        }
    }
    @objc internal var cornerRadius: CGFloat = 0.0 {
        didSet {
            setButton(setButtonType: buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadius)
        }
    }

    @objc override init(frame: CGRect) {
        super.init(frame: frame)

        let cornerRadiusValue: CGFloat = 4.0
        let buttonType = "plain"
        let buttonStyle = "black"
        setButton(setButtonType: buttonType, setButtonStyle: buttonStyle, setButtonCornerRadius: cornerRadiusValue)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
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

        if #available(iOS 26.0, *) {  // TODO: temp fix need to clamp corner-radius to be < height/2
            button = PKPaymentButton(type: type, style: style, disableCardArt: true)
        } else {
            button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        }
        button?.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        if let cornerRadius = cornerRadius {
            button?.cornerRadius = cornerRadius
        }

        if let buttonView = button {
            addSubview(buttonView)
        }
    }

    @objc private func touchUpInside(_ button: PKPaymentButton) {
        onPaymentResult?()
    }

    internal override func layoutSubviews() {
        super.layoutSubviews()
        button?.frame = bounds
    }
}
