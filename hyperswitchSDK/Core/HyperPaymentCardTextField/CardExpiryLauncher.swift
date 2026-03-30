//
//  CardExpiryLauncher.swift
//  Hyperswitch
//
//  Created by Hyperswitch on 29/03/25.
//

import Foundation
import UIKit

/// A launcher for presenting the CardExpiryWidget modally.
///
/// Use this class to programmatically present the card expiry widget
/// and handle the result via the provided callback.
///
/// ## Usage
/// ```swift
/// let launcher = CardExpiryLauncher.create(
///     viewController: self,
///     configuration: configuration,
///     resultCallback: { result in
///         switch result {
///         case .completed(let data):
///             print("Expiry: \(data.expiryMonth)/\(data.expiryYear)")
///         case .canceled:
///             print("User canceled")
///         case .failed(let error):
///             print("Error: \(error)")
///         }
///     }
/// )
/// launcher.present()
/// ```
public class CardExpiryLauncher {
    
    /// The result of the card expiry collection
    public enum Result {
        /// User successfully entered a valid expiry date
        case completed(CardExpiryData)
        /// User canceled the operation
        case canceled
        /// An error occurred
        case failed(Error)
    }
    
    /// Callback type for handling the result
    public typealias ResultCallback = (Result) -> Void
    
    private weak var presentingViewController: UIViewController?
    private let resultCallback: ResultCallback
    private var widgetViewController: CardExpiryWidgetViewController?
    
    private init(
        presentingViewController: UIViewController,
        resultCallback: @escaping ResultCallback
    ) {
        self.presentingViewController = presentingViewController
        self.resultCallback = resultCallback
    }
    
    /// Creates a new CardExpiryLauncher instance
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - resultCallback: Callback to handle the result
    /// - Returns: A configured CardExpiryLauncher instance
    public static func create(
        viewController: UIViewController,
        resultCallback: @escaping ResultCallback
    ) -> CardExpiryLauncher {
        return CardExpiryLauncher(
            presentingViewController: viewController,
            resultCallback: resultCallback
        )
    }
    
    /// Presents the card expiry widget
    public func present() {
        guard let presentingVC = presentingViewController else {
            resultCallback(.failed(LauncherError.presentingViewControllerDeallocated))
            return
        }
        
        let widgetVC = CardExpiryWidgetViewController(resultCallback: resultCallback)
        self.widgetViewController = widgetVC
        
        widgetVC.modalPresentationStyle = .formSheet
        if #available(iOS 16.0, *) {
            if let sheet = widgetVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
        }
        presentingVC.present(widgetVC, animated: true)
    }
    
    /// Dismisses the card expiry widget if presented
    public func dismiss() {
        widgetViewController?.dismiss(animated: true)
    }
}

/// Errors that can occur during launcher operations
public enum LauncherError: Error {
    case presentingViewControllerDeallocated
    case widgetNotReady
    case invalidExpiryData
}

// MARK: - Internal View Controller

/// Internal view controller for hosting the CardExpiryWidget
class CardExpiryWidgetViewController: UIViewController {
    
    private let resultCallback: CardExpiryLauncher.ResultCallback
    private var expiryWidget: CardExpiryWidget?
    private var confirmButton: UIButton?
    
    init(resultCallback: @escaping CardExpiryLauncher.ResultCallback) {
        self.resultCallback = resultCallback
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
    }
    
    private func setupNotifications() {
        // Listen for validation updates from React Native
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleValidationUpdate(_:)),
            name: .cardExpiryValidationUpdate,
            object: nil
        )
    }
    
    @objc private func handleValidationUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let isValid = userInfo["isValid"] as? Bool,
              let month = userInfo["expiryMonth"] as? String,
              let year = userInfo["expiryYear"] as? String else {
            return
        }
        
        if isValid {
            expiryData = CardExpiryData(expiryMonth: month, expiryYear: year)
            confirmButton?.isEnabled = true
            confirmButton?.alpha = 1.0
        } else {
            expiryData = nil
            confirmButton?.isEnabled = false
            confirmButton?.alpha = 0.5
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Enter Card Expiry"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Expiry Widget
        let widget = CardExpiryWidget()
        self.expiryWidget = widget
        view.addSubview(widget)
        
        widget.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widget.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            widget.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            widget.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            widget.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        // Confirm Button
        let button = UIButton(type: .system)
        button.setTitle("Confirm", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.isEnabled = false
        button.alpha = 0.5
        button.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        self.confirmButton = button
        view.addSubview(button)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: widget.bottomAnchor, constant: 30),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Cancel Button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 10),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private var expiryData: CardExpiryData?
    
    @objc private func confirmTapped() {
        guard let data = expiryData else {
            resultCallback(.failed(LauncherError.invalidExpiryData))
            return
        }
        resultCallback(.completed(data))
        dismiss(animated: true)
    }
    
    @objc private func cancelTapped() {
        resultCallback(.canceled)
        dismiss(animated: true)
    }
}

// MARK: - PaymentSession Extension

extension PaymentSession {
    
    /// Presents the card expiry widget
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - completion: Callback with the result
    public func presentCardExpiryWidget(
        viewController: UIViewController,
        completion: @escaping (CardExpiryLauncher.Result) -> Void
    ) {
        let launcher = CardExpiryLauncher.create(
            viewController: viewController,
            resultCallback: completion
        )
        launcher.present()
    }
}
