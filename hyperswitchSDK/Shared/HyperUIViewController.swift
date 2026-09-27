//
//  HyperUIViewController.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 07/10/24.
//

import Foundation
import UIKit

package class HyperUIViewController: UIViewController {
    package var paymentSheet: PaymentSheet?

    package override var shouldAutorotate: Bool {
        return false
    }
    package override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    package override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    package override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    package override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    package override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    package override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}
