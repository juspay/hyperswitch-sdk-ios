import UIKit

/// VGS `VGSExpDateTextField` equivalent — MM/YY masked input.
public class HyperswitchExpDateTextField: HyperswitchTextField {
    override public var fieldType: String { "expDateInput" }
    override public var defaultFieldName: String { "exp_date" }
}
