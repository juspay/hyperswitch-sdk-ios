import UIKit

///  4-4-4-4 formatted, Luhn-checked input.
public class HyperswitchCardTextField: HyperswitchTextField {
    override public var fieldType: String { "cardNumberInput" }
    override public var defaultFieldName: String { "card_number" }
}
