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

    private var needsButtonRebuild = true

    @objc internal var onPaymentResult: (() -> Void)?

    @objc internal var buttonStyle: String = "" {
        didSet {
            if oldValue != buttonStyle {
                setButtonNeedsRebuild()
            }
        }
    }
    @objc internal var buttonType: String = "" {
        didSet {
            if oldValue != buttonType {
                setButtonNeedsRebuild()
            }
        }
    }
    @objc internal var cornerRadius: CGFloat = 4.0 {
        didSet {
            button?.cornerRadius = cornerRadius
        }
    }

    @objc override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setButtonNeedsRebuild() {
        needsButtonRebuild = true
        setNeedsLayout()
    }

    private func rebuildButtonIfNeeded() {
        guard needsButtonRebuild else { return }
        needsButtonRebuild = false

        button?.removeFromSuperview()

        var type: PKPaymentButtonType
        var style: PKPaymentButtonStyle

        switch buttonType {
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

        switch buttonStyle {
        case "white":
            style = .white
        case "whiteOutline":
            style = .whiteOutline
        default:
            style = .black
        }

        let newButton: PKPaymentButton
        if #available(iOS 26.0, *) {  // TODO: temp fix need to clamp corner-radius to be < height/2
            newButton = PKPaymentButton(type: type, style: style, disableCardArt: true)
        } else {
            newButton = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        }
        newButton.addTarget(self, action: #selector(touchUpInside(_:)), for: .touchUpInside)
        newButton.cornerRadius = cornerRadius

        addSubview(newButton)
        button = newButton
    }

    @objc private func touchUpInside(_ button: PKPaymentButton) {
        onPaymentResult?()
    }

    internal override func layoutSubviews() {
        super.layoutSubviews()
        rebuildButtonIfNeeded()
        button?.frame = bounds
    }
}
