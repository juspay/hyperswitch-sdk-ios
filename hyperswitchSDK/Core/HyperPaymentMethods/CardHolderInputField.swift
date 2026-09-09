//
//  CardHolderInputField.swift
//  hyperswitch
//
//  Card-holder-name input field widget.
//

import Foundation
import UIKit

/// Card-holder-name input field widget — its internal React view renders with
/// `type = "cardHolderInput"`.
public final class CardHolderInputField: BaseRNInputField {

    public override var type: String {
        return "cardHolderInput"
    }

    /// Field-specific helpers.
    public func setCardHolderPlaceholder(_ placeholder: String) {
        setPlaceholder(placeholder)
    }

    public func setCapitalization(_ enabled: Bool) {
        setConfigurationProp("capitalization", enabled)
    }
}
