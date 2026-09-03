//
//  CardForm.swift
//  hyperswitch
//
//  Groups the RN-backed payment-method input widgets.
//

import Foundation
import UIKit

/// A card-form instance created via `PaymentMethodSession.createCardForm()`.
///
/// On creation it starts an **empty RN view** on the owning session's dedicated
/// React host — the JS-side form controller — and groups the input widgets bound
/// to it via `bind(_:)`.
///
/// Mirrors the `PaymentWidget` flow of the main payment SDK: `bind(_:)` starts an
/// internal React view inside each bound `BaseRNInputField`.
public class CardForm {

    private let session: PaymentMethodSession

    /// The empty RN view backing this card form on the session's own host.
    /// It is created but never added to any view hierarchy — it only hosts the
    /// JS-side card-form controller for the bound input widgets.
    private var emptyRootView: UIView?

    private var boundFields: [BaseRNInputField] = []

    internal init(session: PaymentMethodSession) {
        self.session = session
        self.emptyRootView = session.reactManager.widgetViewForModule(
            "hyperSwitch",
            initialProperties: ["props": session.launchProps(type: "cardForm", configuration: nil)]
        )
    }

    /// Binds a single input widget to this card form — starts its internal React view.
    public func bind(_ field: BaseRNInputField) {
        bind([field])
    }

    /// Binds the given input widgets to this card form.
    /// Each widget gets its own React view inside itself, rendered on the
    /// owning session's dedicated React host.
    public func bind(_ fields: [BaseRNInputField]) {
        for field in fields where !boundFields.contains(where: { $0 === field }) {
            field.attach(to: session)
            field.startInternalView()
            boundFields.append(field)
        }
    }

    /// Unbinds a previously bound input widget and stops its internal React view.
    public func unbind(_ field: BaseRNInputField) {
        if let index = boundFields.firstIndex(where: { $0 === field }) {
            boundFields.remove(at: index)
            field.stopInternalView()
        }
    }

    /// All widgets currently bound to this card form.
    public var fields: [BaseRNInputField] {
        return boundFields
    }

    /// Stops every bound field's React view and discards the card form's empty view.
    public func release() {
        boundFields.forEach { $0.stopInternalView() }
        boundFields.removeAll()
        emptyRootView = nil
    }
}
