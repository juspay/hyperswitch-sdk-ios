//
//  HyperUIViewController.swift
//  hyperswitch
//
//  Created by Shivam Nan on 24/09/24.
//

import Foundation
import UIKit

internal class HyperUIViewController: UIViewController{
    internal override var shouldAutorotate: Bool {
        return false
    }
    internal override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    internal override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }
    internal override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    internal override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    internal override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    internal override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}
