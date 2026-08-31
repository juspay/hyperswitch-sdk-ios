import HyperswitchVault
import UIKit

/**
 * iOS equivalent of android/vault-demo MainActivity.
 *
 * There is no Activity concept on iOS — the AppDelegate is the equivalent
 * application entry point, so the whole vault demo (collector, secure fields,
 * tokenise button, state logging) is driven from here.
 *
 * The vault sdk_authorization is NOT the payments one: it is minted by a
 * payment-method-session. mockServer.js (client-core) serves a fresh one at
 * GET /create-payment-method-session, fetched before the collector is created.
 */
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private var collect: HyperswitchCollect!
    private let statesView = UILabel()
    private let tokeniseButton = UIButton(type: .system)
    private var fields: [(field: HyperswitchTextField, name: String)] = []

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 12
        container.layoutMargins = UIEdgeInsets(top: 48, left: 16, bottom: 16, right: 16)
        container.isLayoutMarginsRelativeArrangement = true

        addField(HyperswitchCardTextField(), name: "card_number", to: container)
        addField(HyperswitchExpDateTextField(), name: "exp_date", to: container)
        addField(HyperswitchCVCTextField(), name: "cvc", to: container)

        tokeniseButton.setTitle("Tokenise", for: .normal)
        tokeniseButton.addTarget(self, action: #selector(tokeniseTapped), for: .touchUpInside)
        tokeniseButton.isEnabled = false
        container.addArrangedSubview(tokeniseButton)

        statesView.font = .systemFont(ofSize: 12)
        statesView.numberOfLines = 0
        statesView.text = "Fetching vault session…"
        container.addArrangedSubview(statesView)

        let scrollView = UIScrollView()
        scrollView.backgroundColor = .systemBackground
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            container.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        let viewController = UIViewController()
        viewController.view = scrollView

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window

        NSLog("[VAULT-TEST] application:didFinishLaunchingWithOptions done, fields added; fetching vault sdk authorization")

        fetchVaultAuthorization()
        return true
    }

    private func fetchVaultAuthorization() {
        guard let url = URL(string: "\(Self.serverURL)/create-payment-method-session") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    NSLog("[VAULT-TEST] vault session fetch failed: %@", error.localizedDescription)
                    self.statesView.text = "Could not reach mock server at \(Self.serverURL)"
                    return
                }
                guard
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let sdkAuthorization = json["sdkAuthorization"] as? String
                else {
                    self.statesView.text = "Bad vault session response"
                    return
                }
                self.onAuthorizationReady(sdkAuthorization)
            }
        }.resume()
    }

    private func onAuthorizationReady(_ sdkAuthorization: String) {
        let collect = HyperswitchCollect(sdkAuthorization: sdkAuthorization, environment: .sandbox)
        self.collect = collect

        for (field, name) in fields {
            field.configuration = VaultConfiguration(collector: collect, fieldName: name)
        }

        tokeniseButton.isEnabled = true
        statesView.text = "Vault session ready"
        NSLog("[VAULT-TEST] collect initialised with backend sdk authorization")
    }

    private func addField(_ field: HyperswitchTextField, name: String, to container: UIStackView) {
        field.placeholder = name
        field.delegate = self
        field.heightAnchor.constraint(equalToConstant: 56).isActive = true
        fields.append((field, name))
        container.addArrangedSubview(field)
    }

    @objc private func tokeniseTapped() {
        collect?.tokenise()
    }

    private func logStates() {
        let states = collect.getStates()
        NSLog("[VAULT-TEST] getStates() -> %d states", states.count)
        states.forEach { NSLog("[VAULT-TEST] state: %@", "\($0)") }
        statesView.text = states
            .map { "\($0.fieldName ?? "-"): content='\($0.text)' empty=\($0.isEmpty) valid=\($0.isValid)" }
            .joined(separator: "\n\n")
    }

    /// Simulator reaches the host machine's mockServer.js here (Android emulator uses 10.0.2.2).
    private static let serverURL = "http://localhost:5252"
}

extension AppDelegate: VaultTextFieldDelegate {
    func vaultTextFieldDidChange(_ field: HyperswitchTextField?) {
        NSLog("[VAULT-TEST] didChange: %@", "\(field?.state as Any)")
    }
}
