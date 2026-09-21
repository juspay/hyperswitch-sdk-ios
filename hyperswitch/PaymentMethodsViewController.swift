//
//  PaymentMethodsViewController.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

import UIKit

final class PaymentMethodsViewController: UIViewController {

    private let backendUrl = URL(string: "http://localhost:5252")!

    private var cardForm: CardForm?

    private let stack = UIStackView()
    private let statusLabel = UILabel()
    private var tokenizeButton = UIButton(configuration: .filled())

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.text = "Creating a payment method session…"

        tokenizeButton.configuration?.title = "Tokenize"
        tokenizeButton.isEnabled = false
        tokenizeButton.addTarget(self, action: #selector(tokenize), for: .touchUpInside)

        Task { await start() }
    }

    private func start() async {
        do {
            let json = try await NetworkUtility.postData(
                to: "/create-payment-method-session",
                body: [:],
                baseUrl: backendUrl
            )
            guard let publishableKey = json["publishableKey"] as? String,
                  let sdkAuthorization = json["sdkAuthorization"] as? String
            else {
                statusLabel.text = "The server did not return a session: \(json)"
                return
            }

            let hyperswitch = Hyperswitch(configuration: HyperswitchConfiguration(publishableKey: publishableKey))
            let session = hyperswitch.initPaymentMethodSession(
                configuration: PaymentMethodSessionConfiguration(sdkAuthorization: sdkAuthorization)
            )
            show(session.createCardForm())
        } catch {
            stack.addArrangedSubview(statusLabel)
            statusLabel.text = "Could not reach the demo server: \(error.localizedDescription)"
        }
    }

    private func show(_ form: CardForm) {
        cardForm = form

        let number = form.cardNumberField(CardFieldOptions(placeholder: "Card number"))
        let expiry = form.cardExpiryField()
        let cvc = form.cardCvcField()

        let row = UIStackView(arrangedSubviews: [expiry, cvc])
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually

        /// The labels are this screen's own views, between the SDK's fields.
        [
            heading("Card details"),
            number,
            caption("Your card is stored securely."),
            row,
            tokenizeButton,
            statusLabel,
        ].forEach(stack.addArrangedSubview)

        form.onReady = { [weak self] in self?.statusLabel.text = "Form ready." }
        form.onError = { [weak self] error in self?.statusLabel.text = "Form error: \(error.message)" }
        form.onChange = { [weak self] state in
            self?.tokenizeButton.isEnabled = state.isComplete && state.isValid
        }
    }

    @objc private func tokenize() {
        guard let form = cardForm else { return }
        tokenizeButton.isEnabled = false
        statusLabel.text = "Tokenizing…"
        Task {
            switch await form.tokenize() {
            case .success(let card):
                statusLabel.text = "Token: \(card.paymentMethodToken ?? card.tokens.description)"
            case .failure(let error):
                statusLabel.text = "Failed (\(error.code)): \(error.message)"
                tokenizeButton.isEnabled = true
            }
        }
    }

    private func heading(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }
}
