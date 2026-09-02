//
//  PocSharedStateViewController.swift
//  hyperswitch
//
//  POC ONLY — DELETE AFTER DEMO.
//

import UIKit

/// POC ONLY — DELETE AFTER DEMO.
///
/// Mounts TWO PaymentWidget views backed by TWO separate PaymentSessions.
/// Each widget gets its own RCTRootView (own JS props/rootTag), but both live on
/// RNViewManager.sharedInstance's single RCTBridge — i.e. ONE JS VM. The JS-side
/// PocSharedState module-level Dict is written from one root and read from the
/// other, proving module scope is per-VM — the reason PrefetchCache must be
/// keyed by sdkAuthorization and can never be implicitly "session scoped".
class PocSharedStateViewController: UIViewController {

    private let backendUrl = URL(string: "http://localhost:5252")!

    private var hyperswitch: Hyperswitch?
    private var sessionA: PaymentSession?
    private var sessionB: PaymentSession?
    private var widgetA: PaymentWidget?
    private var widgetB: PaymentWidget?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let statusLabel = UILabel()
    private let widgetAContainer = UIView()
    private let widgetBContainer = UIView()
    private let headlessButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        headlessButton.isEnabled = false
        headlessButton.addTarget(self, action: #selector(triggerHeadless(_:)), for: .touchUpInside)
        fetchPaymentIntent()
    }

    // MARK: - Backend

    private func fetchPaymentIntent() {
        setStatus("Fetching payment intent…")
        Task {
            do {
                let json = try await NetworkUtility.fetchData(from: "/create-payment-intent", baseUrl: backendUrl)
                guard let sdkAuthorization = json["sdkAuthorization"] as? String,
                    let publishableKey = json["publishableKey"] as? String,
                    let profileId = json["profileId"] as? String
                else {
                    throw NSError(
                        domain: "API Error", code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Missing required fields"]
                    )
                }
                DispatchQueue.main.async {
                    self.initialiseWidgets(
                        publishableKey: publishableKey,
                        profileId: profileId,
                        sdkAuthorization: sdkAuthorization
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    self.setStatus("Mock server unreachable — run `yarn server`")
                }
            }
        }
    }

    private func initialiseWidgets(publishableKey: String, profileId: String, sdkAuthorization: String) {
        let hyperswitchInstance = Hyperswitch(
            configuration: HyperswitchConfiguration(publishableKey: publishableKey, profileId: profileId)
        )
        self.hyperswitch = hyperswitchInstance

        // Two independent PaymentSessions -> two separate React roots on one bridge/VM.
        let sessionConfig = PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)
        let sessionA = hyperswitchInstance.initPaymentSession(configuration: sessionConfig)
        let sessionB = hyperswitchInstance.initPaymentSession(configuration: sessionConfig)
        self.sessionA = sessionA
        self.sessionB = sessionB

        let configuration = PaymentSheet.Configuration()

        let widgetA = PaymentWidget(
            paymentSession: sessionA,
            configuration: configuration,
            completion: resultHandler(prefix: "A")
        )
        let widgetB = PaymentWidget(
            paymentSession: sessionB,
            configuration: configuration,
            completion: resultHandler(prefix: "B")
        )
        self.widgetA = widgetA
        self.widgetB = widgetB
        embed(widgetA, in: widgetAContainer)
        embed(widgetB, in: widgetBContainer)
        setStatus("Widgets ready. Tap WRITE in widget B, then READ SHARED in widget A.")
        headlessButton.isEnabled = true
    }

    // MARK: - Actions

    @objc
    private func triggerHeadless(_ sender: Any) {
        // Runs the HyperHeadless flow on RNHeadlessManager's OWN bridge — a SEPARATE
        // JS VM from the widget VM on iOS (unlike Android's headless task, which
        // shares the widgets' React context). The JS [SHAREDPoC] HEADLESS VM CHECK
        // log therefore prints a different vmUid and an empty store here, proving
        // the per-VM boundary from the opposite side.
        setStatus("Launching headless…")
        sessionA?.getCustomerSavedPaymentMethods { [weak self] handler in
            print("[PocSharedState] headless handler returned: \(handler)")
            self?.setStatus("Headless ran — check console for [SHAREDPoC] HEADLESS VM CHECK")
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 32, right: 20)
        contentView.addSubview(stackView)

        for subview in [scrollView, contentView, stackView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            widgetAContainer.heightAnchor.constraint(equalToConstant: 300),
            widgetBContainer.heightAnchor.constraint(equalToConstant: 300),
        ])

        let titleLabel = label("PoC — JS module state is shared across roots", font: .boldSystemFont(ofSize: 18))
        let subtitleLabel = label(
            "Two PaymentWidgets = two RCTRootViews on ONE RCTBridge (one JS VM). Tap WRITE in widget B, then READ SHARED in widget A: A displays B's value because module state is per-VM, not per-root.",
            color: .secondaryLabel
        )
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 4
        statusLabel.textAlignment = .center

        widgetAContainer.backgroundColor = UIColor(white: 0.5, alpha: 0.08)
        widgetAContainer.layer.cornerRadius = 8
        widgetAContainer.clipsToBounds = true
        widgetBContainer.backgroundColor = UIColor(white: 0.5, alpha: 0.08)
        widgetBContainer.layer.cornerRadius = 8
        widgetBContainer.clipsToBounds = true

        headlessButton.setTitle("Trigger Headless (VM check)", for: .normal)
        headlessButton.setTitleColor(.white, for: .normal)
        headlessButton.titleLabel?.font = .systemFont(ofSize: 16)
        headlessButton.backgroundColor = .systemBlue
        headlessButton.layer.cornerRadius = 10
        headlessButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        let hintLabel = label("Xcode console: filter for [SHAREDPoC]", font: .systemFont(ofSize: 12), color: .secondaryLabel)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(label("Widget A", font: .boldSystemFont(ofSize: 14)))
        stackView.addArrangedSubview(widgetAContainer)
        stackView.addArrangedSubview(label("Widget B", font: .boldSystemFont(ofSize: 14)))
        stackView.addArrangedSubview(widgetBContainer)
        stackView.addArrangedSubview(headlessButton)
        stackView.addArrangedSubview(hintLabel)
    }

    private func embed(_ widget: PaymentWidget, in container: UIView) {
        container.addSubview(widget)
        widget.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widget.topAnchor.constraint(equalTo: container.topAnchor),
            widget.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            widget.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            widget.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
    }

    private func label(
        _ text: String,
        font: UIFont = .systemFont(ofSize: 13),
        color: UIColor = .label
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = 0
        return label
    }

    private func setStatus(_ message: String) {
        statusLabel.text = message
    }

    private func resultHandler(prefix: String) -> (PaymentResult) -> Void {
        return { [weak self] result in
            switch result {
            case .completed(let data):
                self?.setStatus("\(prefix): completed → \(data)")
            case .canceled(let data):
                self?.setStatus("\(prefix): canceled → \(data)")
            case .failed(let error):
                self?.setStatus("\(prefix): failed → \(error)")
            }
        }
    }
}
