//
//  CardNumberInputField.swift
//  hyperswitch
//
//  Card-number input field widget.
//

import Foundation
import UIKit

/// Card-number input field widget — its internal React view renders with
/// `type = "cardNumberInput"`.
///
/// ```swift
/// let cardNumberInput = CardNumberInputField(configuration: configuration)
/// cardForm.bind(cardNumberInput)
/// ```
public final class CardNumberInputField: BaseRNInputField {

    public override var type: String {
        return "cardNumberInput"
    }

    /// Field-specific helpers.
    public func setCardNumberPlaceholder(_ placeholder: String) {
        setPlaceholder(placeholder)
    }

    public func requestFocusOnBind() {
        setConfigurationProp("autoFocus", true)
    }
}
