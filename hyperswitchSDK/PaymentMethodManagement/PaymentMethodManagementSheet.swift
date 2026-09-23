//
//  PaymentMethodManagementSheet.swift
//  Hyperswitch
//
//  The modal PMM surface: one React root on the PMM host, dismissed by the bundle's
//  own exit call.
//

import Foundation
import UIKit

internal final class PaymentMethodManagementSheet: PaymentMethodManagementEventTarget {

    private let host: PaymentMethodManagementHost
    private let props: [String: Any]
    internal var paymentEventListener: PaymentEventListener?
    private let completion: (PaymentResult) -> Void

    private var rootView: UIView?
    private weak var presentedViewController: UIViewController?

    // SurfaceOwners holds its owner weakly, and no one else retains the sheet:
    // without this the sheet would deallocate right after present() returns and
    // every exit call would resolve to a nil owner — swallowed silently.
    private var retainedSelf: PaymentMethodManagementSheet?

    internal init(
        host: PaymentMethodManagementHost,
        props: [String: Any],
        paymentEventListener: PaymentEventListener?,
        completion: @escaping (PaymentResult) -> Void
    ) {
        self.host = host
        self.props = props
        self.paymentEventListener = paymentEventListener
        self.completion = completion
    }

    internal func present(from viewController: UIViewController) {
        let rootView = host.viewForModule(
            PMMProtocol.component,
            initialProperties: ["props": props],
            owner: self
        )
        rootView.backgroundColor = UIColor.clear
        self.rootView = rootView
        retainedSelf = self

        let sheetViewController = HyperUIViewController()
        sheetViewController.modalPresentationStyle = .overFullScreen
        sheetViewController.view = rootView
        self.presentedViewController = sheetViewController
        viewController.present(sheetViewController, animated: false)
    }

    // MARK: PaymentMethodManagementEventTarget

    internal func pmmExit(_ result: PaymentResult, reset: Bool) {
        completion(result)
        presentedViewController?.dismiss(animated: false) { [weak self] in
            self?.rootView = nil
            self?.retainedSelf = nil
        }
    }

    /// Non-terminal results belong to embedded widgets; a sheet exits or it does not.
    internal func pmmNonTerminalResult(_ result: PaymentResult) {}

    internal func pmmPaymentEvent(type: String, payload: [String: Any]) {
        guard let listener = paymentEventListener else { return }
        let event = PaymentEvent(type: type, payload: payload)
        listener.onPaymentEvent(event)
    }
}
