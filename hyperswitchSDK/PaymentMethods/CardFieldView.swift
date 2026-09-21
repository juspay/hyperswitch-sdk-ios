//
//  CardFieldView.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

import Foundation
import React
import UIKit

/// One field of a `CardForm`. Get one from the form and place it like any other view. What
/// is typed into it cannot be read back; `state` says whether it is complete and valid.
public final class CardFieldView: UIView {

    public let elementType: CardElementType

    public var onReady: (() -> Void)?
    public var onChange: ((CardFieldState) -> Void)?
    public var onFocus: (() -> Void)?
    public var onBlur: (() -> Void)?

    /// The latest snapshot, or nil before the field has reported.
    public private(set) var state: CardFieldState?

    /// Kept so the form, and with it the card, lasts while any of its fields is in use.
    private let form: CardForm
    private var contentHeight: CGFloat = 0

    internal init(form: CardForm, host: PaymentMethodsHost, elementType: CardElementType, options: CardFieldOptions) {
        self.form = form
        self.elementType = elementType
        super.init(frame: .zero)

        var props = options.props
        props["type"] = PaymentMethodsProtocol.fieldType
        props["protocolVersion"] = PaymentMethodsProtocol.version
        props["formId"] = form.formId
        props["elementType"] = elementType.rawValue

        let rootView = host.viewForModule(
            PaymentMethodsProtocol.fieldComponent,
            initialProperties: ["props": props],
            owner: self
        )
        /// The width is the app's to decide and the height is the field's: React measures the
        /// content at that width and the root view takes that height as its own.
        (rootView as? RCTSurfaceHostingProxyRootView)?.sizeFlexibility = .height
        rootView.backgroundColor = .clear
        rootView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rootView)
        NSLayoutConstraint.activate([
            rootView.topAnchor.constraint(equalTo: topAnchor),
            rootView.bottomAnchor.constraint(equalTo: bottomAnchor),
            rootView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Get a CardFieldView from a CardForm.")
    }

    /// The height its content asked for, so the view sizes itself in a stack or with
    /// Auto Layout; a height constraint of your own still wins.
    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentHeight > 0 ? contentHeight : UIView.noIntrinsicMetric)
    }

    public func focus() {
        form.send(fieldCommand: "focus", for: elementType)
    }

    public func blur() {
        form.send(fieldCommand: "blur", for: elementType)
    }

    public func clear() {
        form.send(fieldCommand: "clear", for: elementType)
    }
}

extension CardFieldView: PaymentMethodsEventTarget {

    internal func paymentMethodsEvent(_ name: String, payload: [String: Any]) {
        switch name {
        case PaymentMethodsProtocol.FieldEvent.ready:
            onReady?()

        case PaymentMethodsProtocol.FieldEvent.change:
            guard let next = CardFieldState(payload), next != state else { return }
            state = next
            onChange?(next)

        case PaymentMethodsProtocol.FieldEvent.focus:
            onFocus?()

        case PaymentMethodsProtocol.FieldEvent.blur:
            onBlur?()

        case PaymentMethodsProtocol.FieldEvent.layout:
            let height = CGFloat((payload["height"] as? NSNumber)?.doubleValue ?? 0)
            guard height != contentHeight else { return }
            contentHeight = height
            invalidateIntrinsicContentSize()

        default:
            break
        }
    }
}
