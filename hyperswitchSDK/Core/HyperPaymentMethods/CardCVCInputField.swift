//
//  CardCVCInputField.swift
//  hyperswitch
//
//  Card-CVC input field widget.
//

import Foundation
import UIKit

/// Card-CVC input field widget — its internal React view renders with
/// `type = "cardCVCInput"`.
public final class CardCVCInputField: BaseRNInputField {

    public override var type: String {
        return "cardCVCInput"
    }

    /// Field-specific helpers.
    public func setCVCPlaceholder(_ placeholder: String) {
        setPlaceholder(placeholder)
    }

    public func setMaxLength(_ maxLength: Int) {
        setConfigurationProp("maxLength", maxLength)
    }
}
