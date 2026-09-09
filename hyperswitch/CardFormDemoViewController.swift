//
//  CardFormDemoViewController.swift
//  Hyperswitch
//
//  Demo screen for the payment-methods headless card form API
//  (`PaymentMethodSession` / `CardForm`).
//

import UIKit

class CardFormDemoViewController: UIViewController {

    private let backendUrl = URL(string: "http://localhost:5252")!

    private var hyperswitch: Hyperswitch?
    private var paymentMethodSession: PaymentMethodSession?
    private var cardForm: CardForm?

    private let topBarView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let cardHolderField = CardHolderInputField(frame: .zero)
    private let cardNumberField = CardNumberInputField(frame: .zero)
    private let cardExpiryField = CardExpiryInputField(frame: .zero)
    private let cardCVCField = CardCVCInputField(frame: .zero)
    private let tokeniseButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        fetchPaymentMethodSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cardForm?.release()
    }

    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func tokeniseTapped() {
        statusLabel.text = "Tokenising…"
        cardForm?.tokenise { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let token, _, _):
                    self?.statusLabel.text = "Tokenise success: \(token)"
                case .failure(let vaultType, let error):
                    self?.statusLabel.text =
                        "Tokenise failed (\(vaultType ?? "-")): \(error.code) — \(error.message ?? "")"
                }
            }
        }
    }

    private func fetchPaymentMethodSession() {
        statusLabel.text = "Creating payment method session…"
        Task {
            do {
                let json = try await NetworkUtility.fetchData(
                    from: "/create-payment-method-session",
                    baseUrl: backendUrl
                )
                guard let sdkAuthorization = json["sdkAuthorization"] as? String,
                    let publishableKey = json["publishableKey"] as? String
                else {
                    throw NSError(
                        domain: "API Error",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Missing required fields"]
                    )
                }
                let profileId = json["profileId"] as? String

                DispatchQueue.main.async {
                    self.initialisePaymentMethodSession(
                        publishableKey: publishableKey,
                        profileId: profileId,
                        sdkAuthorization: sdkAuthorization
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Could not connect to the server"
                }
            }
        }
    }

    private func initialisePaymentMethodSession(
        publishableKey: String,
        profileId: String?,
        sdkAuthorization: String
    ) {
        let configuration = HyperswitchConfiguration(
            publishableKey: publishableKey,
            profileId: profileId,
            environment: .sandbox
        )
        hyperswitch = Hyperswitch(configuration: configuration)
        paymentMethodSession = hyperswitch?.initPaymentMethodSession(sdkAuthorization: sdkAuthorization)

        let primaryBlue = UIColor(red: 0, green: 0.44, blue: 0.98, alpha: 1)

        // Every AppearanceVariables field — session-level theming for the hyperswitch vault.
        let variables = AppearanceVariables(
            colorPrimary: primaryBlue,
            colorText: .label,
            colorDanger: .systemRed,
            colorTextPlaceholder: .systemGray,
            colorBackground: .systemBackground,
            borderColor: .separator,
            borderRadius: 12,
            borderWidth: 1,
            fontFamily: "Helvetica",
            fontScale: 1,
            inputFieldHeight: 52,
            gap: 10,
            placeholderTextSizeAdjust: 0,
            errorTextSizeAdjust: -2,
            errorMessageSpacing: 4,
            cardBrandIcon: .animated
        )
        cardForm = paymentMethodSession?.createCardForm(variables: variables)

        // Every FieldStyles slot + every FieldOptions field, split across the 4 fields so
        // each attribute this SDK supports gets a real, visible use.
        //
        // No `container.padding` on any field: ViewStyleProps only has one padding value (all
        // four sides), and the vault SDK sizes each box to a fixed `height` while centering its
        // floating label inside that budget — a uniform padding eats into the vertical room the
        // label needs once it animates to its focused/compact state, and clips. The SDK's own
        // default horizontal-only inset already looks right, so leave vertical spacing to
        // `height` (see setupLayout's heightAnchor) alone. `labelBehavior: .above` (previously
        // used on cardHolderField) has the same problem one level up — with nothing forwarding
        // "give the native view extra room for the label row above the box" the way FieldStyles'
        // own `height` communicates the box's height, RN's overflow (unclipped here, unlike
        // Android) bled the extra content into the next field. `.floating` sidesteps that: the
        // label lives inside the box's own budget, so every field can share one plain height.
        cardHolderField.setStyles(FieldStyles(
            container: ViewStyleProps(
                backgroundColor: .secondarySystemBackground,
                borderRadius: 12,
                borderWidth: 1,
                borderColor: .separator
            ),
            input: TextStyleProps(color: .label, fontSize: 15),
            placeholder: TextStyleProps(color: .tertiaryLabel, fontSize: 15),
            label: TextStyleProps(color: .secondaryLabel, fontSize: 12),
            error: TextStyleProps(color: .systemRed, fontSize: 12)
        ))
        cardHolderField.setOptions(FieldOptions(
            label: "Cardholder name",
            labelBehavior: .floating,
            errorDisplay: .inline,
            unstyled: false,
            accessibilityLabel: "Cardholder name input",
            accessibilityHint: "Enter the name printed on the card"
        ))

        cardNumberField.setStyles(FieldStyles(
            container: ViewStyleProps(
                backgroundColor: .secondarySystemBackground,
                borderRadius: 12,
                borderWidth: 1,
                borderColor: .separator
            ),
            input: TextStyleProps(color: .label, fontSize: 15),
            placeholder: TextStyleProps(color: .tertiaryLabel, fontSize: 15),
            label: TextStyleProps(color: .secondaryLabel, fontSize: 12),
            error: TextStyleProps(color: .systemRed, fontSize: 12),
            accessory: ViewStyleProps(backgroundColor: .secondarySystemBackground, borderRadius: 4, padding: 2)
        ))
        cardNumberField.setOptions(FieldOptions(
            label: "Card number",
            labelBehavior: .floating,
            errorDisplay: .inline,
            unstyled: false,
            accessibilityLabel: "Card number input",
            accessibilityHint: "Enter your 16 digit card number",
            cardBrandIcon: .animated
        ))

        cardExpiryField.setStyles(FieldStyles(
            container: ViewStyleProps(
                backgroundColor: .secondarySystemBackground,
                borderRadius: 12,
                borderWidth: 1,
                borderColor: .separator
            ),
            input: TextStyleProps(color: .label, fontSize: 15),
            placeholder: TextStyleProps(color: .tertiaryLabel, fontSize: 15),
            label: TextStyleProps(color: .secondaryLabel, fontSize: 11),
            error: TextStyleProps(color: .systemRed, fontSize: 11)
        ))
        cardExpiryField.setOptions(FieldOptions(
            label: "Expiry",
            labelBehavior: .floating,
            errorDisplay: .inline,
            unstyled: false,
            accessibilityLabel: "Expiry date input",
            accessibilityHint: "Enter the card expiry date"
        ))

        cardCVCField.setStyles(FieldStyles(
            container: ViewStyleProps(
                backgroundColor: .secondarySystemBackground,
                borderRadius: 12,
                borderWidth: 1,
                borderColor: .separator
            ),
            input: TextStyleProps(color: .label, fontSize: 15),
            placeholder: TextStyleProps(color: .tertiaryLabel, fontSize: 15),
            label: TextStyleProps(color: .secondaryLabel, fontSize: 11),
            error: TextStyleProps(color: .systemRed, fontSize: 11),
            accessory: ViewStyleProps(backgroundColor: .secondarySystemBackground, borderRadius: 2, padding: 2)
        ))
        cardCVCField.setOptions(FieldOptions(
            label: "CVC",
            labelBehavior: .floating,
            errorDisplay: .inline,
            unstyled: false,
            accessibilityLabel: "CVC input",
            accessibilityHint: "Enter the 3 digit security code",
            cvcIcon: .default
        ))

        cardForm?.bind([cardHolderField, cardNumberField, cardExpiryField, cardCVCField])
        statusLabel.text = "Card form ready"
    }
}

extension CardFormDemoViewController {
    private func setupLayout() {
        view.addSubview(topBarView)
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topBarView.heightAnchor.constraint(equalToConstant: 50).isActive = true

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        topBarView.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 16).isActive = true
        backButton.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 25).isActive = true

        titleLabel.text = "Card Form Demo"
        titleLabel.font = .boldSystemFont(ofSize: 16.5)
        topBarView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor).isActive = true

        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 4
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel

        cardHolderField.setCardHolderPlaceholder("Cardholder name")
        cardNumberField.setCardNumberPlaceholder("Card number")
        cardExpiryField.setExpiryPlaceholder("MM / YY")
        cardCVCField.setCVCPlaceholder("CVC")

        // 52pt to match the session's `AppearanceVariables.inputFieldHeight` below — the native
        // view has to be at least as tall as the JS-rendered box, or RN's content overflows it
        // (see the note on cardHolderField's styles above).
        [cardHolderField, cardNumberField, cardExpiryField, cardCVCField].forEach {
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.separator.cgColor
            $0.layer.cornerRadius = 12
            $0.heightAnchor.constraint(equalToConstant: 52).isActive = true
        }

        let expiryCvcRow = UIStackView(arrangedSubviews: [cardExpiryField, cardCVCField])
        expiryCvcRow.axis = .horizontal
        expiryCvcRow.spacing = 12
        expiryCvcRow.distribution = .fillEqually

        tokeniseButton.setTitle("Tokenise", for: .normal)
        tokeniseButton.backgroundColor = .systemBlue
        tokeniseButton.setTitleColor(.white, for: .normal)
        tokeniseButton.layer.cornerRadius = 10
        tokeniseButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        tokeniseButton.addTarget(self, action: #selector(tokeniseTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            statusLabel, cardHolderField, cardNumberField, expiryCvcRow, tokeniseButton,
        ])
        stack.axis = .vertical
        stack.spacing = 14
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.topAnchor.constraint(equalTo: topBarView.bottomAnchor, constant: 20).isActive = true
        stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
    }
}
