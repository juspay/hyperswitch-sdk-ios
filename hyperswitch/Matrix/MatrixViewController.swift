import UIKit

final class MatrixViewController: UIViewController, MatrixUI {

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let serverField = UITextField()
    private let runAllButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let continueButton = UIButton(type: .system)
    private let gateLabel = UILabel()
    private var statusLabels: [String: UILabel] = [:]
    private let containers = [UIView(), UIView(), UIView()]
    private let cvcHost = UIView()
    private let logView = UITextView()
    private var logLines = ""

    private var backend: MatrixBackend!
    private var ctx: Ctx!
    private var runner: ScenarioRunner!
    private var hyperswitch: Hyperswitch?
    private var gateContinuation: CheckedContinuation<Bool, Never>?
    private var gateToken = 0
    private var runTask: Task<Void, Never>?

    var presenter: UIViewController { self }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildLayout()
        configureHarness()
    }

    private func configureHarness() {
        let url = URL(string: serverField.text ?? "") ?? URL(string: "http://localhost:5252")!
        backend = MatrixBackend(serverUrl: url)
        var configuration = PaymentSheet.Configuration()
        configuration.displaySavedPaymentMethods = true
        ctx = Ctx(backend: backend, ui: self, configuration: configuration) { [weak self] intent in
            guard let self else { fatalError("controller gone") }
            if let existing = self.hyperswitch { return existing }
            let created = Hyperswitch(configuration: HyperswitchConfiguration(
                publishableKey: intent.publishableKey,
                profileId: intent.profileId.isEmpty ? nil : intent.profileId,
                customEndpoints: .overrideEndpoints(OverrideEndpointConfiguration(
                    customBackendEndpoint: url.absoluteString + "/proxy"
                )),
                environment: .sandbox
            ))
            self.hyperswitch = created
            return created
        }
        runner = ScenarioRunner(ctx: ctx)
        log("server: \(url.absoluteString) (proxy at \(url.absoluteString)/proxy)")
    }

    // MARK: layout

    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -24),
        ])

        serverField.text = "http://localhost:5252"
        serverField.borderStyle = .roundedRect
        serverField.autocapitalizationType = .none
        serverField.addTarget(self, action: #selector(serverChanged), for: .editingDidEnd)
        stack.addArrangedSubview(serverField)

        let buttons = UIStackView(arrangedSubviews: [runAllButton, resetButton, copyButton])
        buttons.distribution = .fillEqually
        runAllButton.setTitle("Run all", for: .normal)
        resetButton.setTitle("Reset", for: .normal)
        copyButton.setTitle("Copy log", for: .normal)
        runAllButton.addTarget(self, action: #selector(runAll), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetAll), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyLog), for: .touchUpInside)
        stack.addArrangedSubview(buttons)

        gateLabel.numberOfLines = 0
        gateLabel.isHidden = true
        stack.addArrangedSubview(gateLabel)
        continueButton.setTitle("Continue", for: .normal)
        continueButton.isHidden = true
        continueButton.addTarget(self, action: #selector(continuePressed), for: .touchUpInside)
        stack.addArrangedSubview(continueButton)

        for scenario in Scenarios.all {
            let row = UIStackView()
            row.spacing = 8
            let title = UILabel()
            title.text = "\(scenario.id)  \(scenario.title)"
            title.font = .systemFont(ofSize: 13)
            title.numberOfLines = 2
            let status = UILabel()
            status.text = "idle"
            status.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            status.widthAnchor.constraint(equalToConstant: 64).isActive = true
            let run = UIButton(type: .system)
            run.setTitle("Run", for: .normal)
            run.addAction(UIAction { [weak self] _ in self?.run([scenario]) }, for: .touchUpInside)
            statusLabels[scenario.id] = status
            row.addArrangedSubview(title); row.addArrangedSubview(status); row.addArrangedSubview(run)
            stack.addArrangedSubview(row)
        }

        for container in containers {
            container.heightAnchor.constraint(equalToConstant: 320).isActive = true
            container.backgroundColor = .secondarySystemBackground
            stack.addArrangedSubview(container)
        }
        cvcHost.heightAnchor.constraint(equalToConstant: 64).isActive = true
        cvcHost.backgroundColor = .secondarySystemBackground
        stack.addArrangedSubview(cvcHost)

        logView.isEditable = false
        logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logView.backgroundColor = .black
        logView.textColor = .lightGray
        logView.heightAnchor.constraint(equalToConstant: 280).isActive = true
        stack.addArrangedSubview(logView)
    }

    // MARK: actions

    @objc private func serverChanged() { configureHarness() }

    @objc private func runAll() { run(Scenarios.all) }

    private func run(_ scenarios: [Scenario]) {
        if let task = runTask, !task.isCancelled { log("a run is already in progress"); return }
        runTask = Task { @MainActor in
            for scenario in scenarios { _ = await runner.run(scenario) }
            log("run finished")
            runTask = nil
        }
    }

    @objc private func resetAll() {
        runTask?.cancel(); runTask = nil
        gateContinuation?.resume(returning: false); gateContinuation = nil
        Task { @MainActor in
            await ctx.reset()
            statusLabels.values.forEach { $0.text = "idle" }
            logLines = ""; logView.text = ""
            log("reset done")
        }
    }

    @objc private func copyLog() {
        UIPasteboard.general.string = logLines
        log("log copied")
    }

    @objc private func continuePressed() {
        gateContinuation?.resume(returning: true)
        gateContinuation = nil
    }

    // MARK: MatrixUI

    func log(_ line: String) {
        logLines += line + "\n"
        logView.text = logLines
        let end = NSRange(location: max(logLines.count - 1, 0), length: 1)
        logView.scrollRangeToVisible(end)
    }

    func gate(_ message: String) async -> Bool {
        gateLabel.text = message; gateLabel.isHidden = false; continueButton.isHidden = false
        gateToken += 1
        let token = gateToken
        let pressed: Bool = await withCheckedContinuation { continuation in
            gateContinuation = continuation
            DispatchQueue.main.asyncAfter(deadline: .now() + 120) { [weak self] in
                guard let self, self.gateToken == token, let pending = self.gateContinuation else { return }
                self.gateContinuation = nil
                pending.resume(returning: false)
            }
        }
        gateLabel.isHidden = true; continueButton.isHidden = true
        return pressed
    }

    func paymentContainer(_ index: Int) -> UIView { containers[min(max(index, 1), 3) - 1] }

    func cvcContainer() -> UIView { cvcHost }

    func setStatus(_ id: String, _ status: String) { statusLabels[id]?.text = status }
}
