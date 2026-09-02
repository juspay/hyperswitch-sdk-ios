import UIKit

/// VGS `VGSCVCTextField` equivalent — 3-4 digit CVC input (masked).
public class HyperswitchCVCTextField: HyperswitchTextField {
    override public var defaultFieldName: String { "cvc" }
}
