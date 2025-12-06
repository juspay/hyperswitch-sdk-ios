//
//  ClickToPayViewController.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 31/10/25.
//

import UIKit
import SwiftUI
import Combine

class ClickToPayViewController: UIViewController {

    @ObservedObject var clickToPayViewModel = ClickToPayViewModel()
    private var clickToPaySession: ClickToPaySession?
    private var recognizedCards: [RecognizedCard] = []

    private var reloadButton = UIButton()
    private var initC2PButton = UIButton()
    private var checkCustomerButton = UIButton()
    private var getUserTypeButton = UIButton()
    private var getCardsButton = UIButton()
    private var validateOTPButton = UIButton()
    private var signOutButton = UIButton()
    private var checkoutButton = UIButton()
    private var closeSessionButton = UIButton()
    private var statusLabel = UILabel()
    private var cardsStatusLabel = UILabel()

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.2)
        super.viewDidLoad()
        clickToPayViewModel.prepareAuthenticationSession()
        asyncBind()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewFrame()
    }

    private func asyncBind() {
        clickToPayViewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .loading:
                    self?.statusLabel.text = "Loading..."
                case .success:
                    self?.statusLabel.text = "Connected to Server"
                case .failure(let message):
                    self?.statusLabel.text = message
                }
            }
            .store(in: &cancellables)
    }

    @objc
    func reload(_ sender: Any) {
        clickToPayViewModel.prepareAuthenticationSession()
        self.reloadButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 1.6, animations: {
            self.reloadButton.backgroundColor = .white
        }) { (_) in
            self.reloadButton.backgroundColor = .systemBlue
            self.reloadButton.isUserInteractionEnabled = true
        }
    }

    // MARK: - Click to Pay Functions

    @objc
    private func initClickToPaySession(  _ sender: Any) {
        guard let session = clickToPayViewModel.authenticationSession else {
            updateStatus("Authentication session not initialized")
            return
        }
        Task {
            do {
                updateStatus("Initializing Click to Pay...")
                let clickToPaySession = try await session.initClickToPaySession(request3DSAuthentication: false, viewController: self)
                DispatchQueue.main.async {
                    self.clickToPaySession = clickToPaySession
                    self.updateStatus("Click to Pay Initialized")
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("Init C2P failed: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc
    func checkCustomer(_ sender: Any) {
        let alert = UIAlertController(title: "Enter Email", message: "Enter customer email to check presence", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "email@example.com"
            textField.keyboardType = .emailAddress
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "Check", style: .default) { [weak self, weak alert] _ in
            if let email = alert?.textFields?.first?.text, !email.isEmpty {
                self?.checkCustomerPresence(email: email)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func checkCustomerPresence(email: String) {
        guard let session = clickToPaySession else {
            updateStatus("Click to Pay session not initialized")
            return
        }

        Task {
            do {
                updateStatus("Checking customer presence...")
                let request = CustomerPresenceRequest(email: email)
                let response = try await session.isCustomerPresent(request: request)
                DispatchQueue.main.async {
                    self.updateStatus("Customer Check Complete")
                    self.updateCardsStatus("Customer \(response.customerPresent  ? "exists" : "doesn't exist")")
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("Check failed: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc
    private func getUserType(_ sender: Any) {
        guard let session = clickToPaySession else {
            updateStatus("Click to Pay session not initialized")
            return
        }

        Task {
            do {
                updateStatus("Getting user type...")
                let response = try await session.getUserType()
                DispatchQueue.main.async {
                    self.updateStatus("User Type Retrieved")
                    self.updateCardsStatus(response.statusCode.rawValue)
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("Get user type failed: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc
    private func getRecognizedCards(_ sender: Any) {
        guard let session = clickToPaySession else {
            updateStatus("Click to Pay session not initialized")
            return
        }

        Task {
            do {
                updateStatus("Getting recognized cards...")
                let cards = try await session.getRecognizedCards()
                DispatchQueue.main.async {
                    self.recognizedCards = cards
                    self.updateStatus("Cards Retrieved")
                    self.updateCardsStatus("Found \(cards.count) card(s)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("Get cards failed: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc
    func validateOTP(_ sender: Any) {
        let alert = UIAlertController(title: "Enter OTP", message: "Enter the OTP sent to your device", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "123456"
            textField.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Validate", style: .default) { [weak self, weak alert] _ in
            if let otp = alert?.textFields?.first?.text, !otp.isEmpty {
                self?.validateCustomerAuthentication(otp: otp)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func validateCustomerAuthentication(otp: String) {
        guard let session = clickToPaySession else {
            updateStatus("Click to Pay session not initialized")
            return
        }
        Task {
            do {
                updateStatus("Validating OTP...")
                let cards = try await session.validateCustomerAuthentication(otpValue: otp)
                DispatchQueue.main.async {
                    self.recognizedCards = cards
                    self.updateStatus("OTP Validated")
                    self.updateCardsStatus("Found \(cards.count) card(s)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("OTP validation failed: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc
    private func signOut(_ sender: Any) {
        guard let session = clickToPaySession else {
            updateStatus("Click to Pay session not initialized")
            return
        }

        Task {
            do {
                updateStatus("Signing Out...")
                let signOutResponse = try await session.signOut()
                DispatchQueue.main.async {
                    self.updateStatus("Signed Out")
                    self.updateCardsStatus("recognized: \(signOutResponse.recognized)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateStatus("Failed to sign Out: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc
    func checkout(_ sender: Any) {
        guard !recognizedCards.isEmpty else {
            let alert = UIAlertController(title: "No Cards", message: "Please get recognized cards first", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let alert = UIAlertController(title: "Select Card", message: "Choose a card for checkout", preferredStyle: .actionSheet)
        for card in recognizedCards {
            if let pan = card.panLastFour, let brand = card.paymentCardDescriptor  {
                let cardLabel = "**** \(pan) - \(brand)"
                alert.addAction(UIAlertAction(title: cardLabel, style: .default) { [weak self] _ in
                    self?.checkoutWithCard(srcDigitalCardId: card.srcDigitalCardId, rememberMe: true)
                })
            }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func checkoutWithCard(srcDigitalCardId: String, rememberMe: Bool = false) {
        guard let session = clickToPaySession else {
            updateStatus("Click to Pay session not initialized")
            return
        }
        Task {
            do {
                updateStatus("Processing checkout...")
                let request = CheckoutRequest(srcDigitalCardId: srcDigitalCardId, rememberMe: rememberMe)
                let response = try await session.checkoutWithCard(request: request)
                DispatchQueue.main.async {
                    switch response.status {

                    case .success:

                        self.updateStatus("Checkout Complete")
                        self.updateCardsStatus("Status: success")
                    case .pending:
                        self.updateStatus("Checkout Complete")
                        self.updateCardsStatus("Status: pending")
                    case .failed:
                        self.updateStatus("Checkout Complete")
                        self.updateCardsStatus("Status: failure")
                    default:
                        print()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print(error)
                    self.updateStatus("Checkout failed: \(error.localizedDescription)")
                }
            }
        }
    }
    @objc
    func closeSession(_ sender: Any) {
        guard let session = clickToPaySession else {
            updateStatus("Click to Pay session not initialized")
            return
        }
        session.close()
        self.updateStatus("Session Closed")
        self.updateCardsStatus("")
    }

    // MARK: - UI Helper Methods

    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }

    private func updateCardsStatus(_ message: String) {
        DispatchQueue.main.async {
            self.cardsStatusLabel.text = message
        }
    }
}

// MARK: - UI Setup

extension ClickToPayViewController {

    func viewFrame() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Reload Button
        setupButton(reloadButton, title: "Reload Client Secret", target: #selector(reload(_:)), on: contentView, topAnchor: contentView.topAnchor, constant: 20)

        // Init C2P Button
        setupButton(initC2PButton, title: "Init Click to Pay", target: #selector(initClickToPaySession(_:)), on: contentView, topAnchor: reloadButton.bottomAnchor, constant: 15)

        // Check Customer Button
        setupButton(checkCustomerButton, title: "Check Customer Presence", target: #selector(checkCustomer(_:)), on: contentView, topAnchor: initC2PButton.bottomAnchor, constant: 15)

        // Get User Type Button
        setupButton(getUserTypeButton, title: "Get User Type", target: #selector(getUserType(_:)), on: contentView, topAnchor: checkCustomerButton.bottomAnchor, constant: 15)

        // Get Cards Button
        setupButton(getCardsButton, title: "Get Recognized Cards", target: #selector(getRecognizedCards(_:)), on: contentView, topAnchor: getUserTypeButton.bottomAnchor, constant: 15)

        // Validate OTP Button
        setupButton(validateOTPButton, title: "Validate OTP", target: #selector(validateOTP(_:)), on: contentView, topAnchor: getCardsButton.bottomAnchor, constant: 15)

        setupButton(signOutButton, title: "Sign Out", target: #selector(signOut(_:)), on: contentView, topAnchor: validateOTPButton.bottomAnchor, constant: 15)

        // Checkout Button
        setupButton(checkoutButton, title: "Checkout with Card", target: #selector(checkout(_:)), on: contentView, topAnchor: signOutButton.bottomAnchor, constant: 15)

        setupButton(closeSessionButton, title: "Close Session", target: #selector(closeSession(_:)), on: contentView, topAnchor: checkoutButton.bottomAnchor, constant: 15)

        // Status Label
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusLabel.topAnchor.constraint(equalTo: closeSessionButton.bottomAnchor, constant: 30)
        ])

        // Cards Status Label
        cardsStatusLabel.textAlignment = .center
        cardsStatusLabel.numberOfLines = 0
        cardsStatusLabel.font = .systemFont(ofSize: 14)
        cardsStatusLabel.textColor = .darkGray
        contentView.addSubview(cardsStatusLabel)
        cardsStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardsStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardsStatusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardsStatusLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 15),
            cardsStatusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }

    private func setupButton(_ button: UIButton, title: String, target: Selector, on view: UIView, topAnchor: NSLayoutYAxisAnchor, constant: CGFloat) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.backgroundColor = .systemBlue
        button.addTarget(self, action: target, for: .touchUpInside)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            button.topAnchor.constraint(equalTo: topAnchor, constant: constant),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
