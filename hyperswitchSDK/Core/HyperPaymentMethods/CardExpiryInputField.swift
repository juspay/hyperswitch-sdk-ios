//
//  CardExpiryInputField.swift
//  hyperswitch
//
//  Card-expiry input field widget.
//

import Foundation
import UIKit

/// Card-expiry input field widget — its internal React view renders with
/// `type = "cardExpiryInput"`.
public final class CardExpiryInputField: BaseRNInputField {

    public override var type: String {
        return "cardExpiryInput"
    }

    /// Field-specific helpers.
    public func setExpiryPlaceholder(_ placeholder: String) {
        setPlaceholder(placeholder)
    }

    public func setExpiryFormat(_ format: String) {
        setConfigurationProp("expiryFormat", format)
    }
}
