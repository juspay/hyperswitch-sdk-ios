//
//  BaseRNInputField.swift
//  hyperswitch
//
//  Base class for every React-Native-backed payment-method input widget.
//

import Foundation
import UIKit

/// Base class for every React-Native-backed payment-method input widget
/// (`BaseRNInputClass`).
///
/// Concrete fields (`CardNumberInputField`, `CardExpiryInputField`,
/// `CardCVCInputField`, `CardHolderInputField`) inherit from this class, override
/// `type` and may add field-specific functions on top.
///
/// A widget only renders its internal React view once it has been bound to a
/// `CardForm` via `cardForm.bind(...)`, the same way a `PaymentWidget` renders on
/// the main SDK.
open class BaseRNInputField: UIView {

    /// Widget type sent to the RN root component — overridden by each concrete field
    /// (e.g. `"cardNumberInput"`).
    open var type: String {
        return ""
    }

    /// The field configuration (appearance + any other props related to the field).
    public var configuration = InputConfiguration()

    internal weak var session: PaymentMethodSession?
    private var rootView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public convenience init(configuration: InputConfiguration) {
        self.init(frame: .zero)
        self.configuration = configuration
    }

    /// Adds/updates a single configuration prop (used by field-specific helpers).
    internal func setConfigurationProp(_ key: String, _ value: Any) {
        var props = configuration.props ?? [:]
        props[key] = value
        configuration.props = props
    }

    /// Placeholder text prop shared by all input fields.
    public func setPlaceholder(_ placeholder: String) {
        setConfigurationProp("placeholder", placeholder)
    }

    /// Launch options handed to the internal React view:
    /// ```
    /// launchOptions = {
    ///     type          = "<field type>",
    ///     configuration = {...},
    ///     session       = { sdk_auth = "...", vault_type = "...", vault_data = "..." }
    /// }
    /// ```
    internal var launchOptions: [String: Any] {
        return session?.launchProps(type: type, configuration: configuration.toDictionary()) ?? [:]
    }

    internal func attach(to session: PaymentMethodSession) {
        self.session = session
    }

    /// Creates the React view inside this widget (like `PaymentWidget`'s internal
    /// root view) and starts rendering the field on the owning session's dedicated
    /// React host. No-op until the widget is bound to a card form.
    public func startInternalView() {
        guard let session = session, rootView == nil else { return }
        let view = session.reactManager.widgetViewForModule(
            "hyperSwitch",
            initialProperties: ["props": launchOptions]
        )
        view.backgroundColor = .clear
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        rootView = view
    }

    /// Stops the internal React view and removes it from this widget.
    public func stopInternalView() {
        rootView?.removeFromSuperview()
        rootView = nil
    }
}
