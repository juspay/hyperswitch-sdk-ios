import Combine
import SwiftUI
import UIKit

class PaymentMethodManagementViewController: UIViewController {

    @ObservedObject var hyperViewModel = HyperViewModel()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var reloadButton = UIButton()
    private var reloadButtonConfiguration = UIButton.Configuration.plain()

    private var presentSheetButton = UIButton()
    private var presentSheetButtonConfiguration = UIButton.Configuration.plain()

    private var confirmWidgetButton = UIButton()
    private var confirmWidgetButtonConfiguration = UIButton.Configuration.plain()

    private var statusLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()
    private var pmmWidget: PaymentMethodManagementWidget?
    private var widgetConstraints: [NSLayoutConstraint] = []
    private let backChevron = UIButton(type: .system)

    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.2)
        super.viewDidLoad()
        setupScrollView()
        asyncBind()
        viewFrame()
        hyperViewModel.preparePaymentMethodManagement()

        backChevron.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backChevron.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backChevron)
        backChevron.translatesAutoresizingMaskIntoConstraints = false
        backChevron.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8).isActive = true
        backChevron.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12).isActive = true
        backChevron.widthAnchor.constraint(equalToConstant: 28).isActive = true
        backChevron.heightAnchor.constraint(equalToConstant: 28).isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        backChevron.isHidden = (presentingViewController == nil)
    }

    @objc
    private func backTapped() {
        dismiss(animated: true, completion: nil)
    }

    private func asyncBind() {
        hyperViewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .loading:
                    self?.statusLabel.text = "Loading..."
                case .success:
                    self?.statusLabel.text = "Connected to Server"
                    self?.attachPaymentMethodManagementWidget()
                case .failure(let message):
                    self?.statusLabel.text = message
                }
            }
            .store(in: &cancellables)
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

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
        ])
    }

    private func updateStatus(_ paymentResult: PaymentResult) {
        switch paymentResult {
        case .completed(let data):
            statusLabel.text = "completed → \(data)"
        case .canceled(let data):
            statusLabel.text = "canceled → \(data)"
        case .failed(let error):
            statusLabel.text = "failed → \(error)"
        }
    }

    @objc
    private func presentSheet(_ sender: Any) {
        var configuration = PaymentSheet.Configuration()
        configuration.paymentSheetHeaderLabel = "Payment methods"
        configureAppearance(&configuration)

        hyperViewModel.paymentSession?.presentPaymentMethodManagement(
            viewController: self,
            configuration: configuration
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.updateStatus(result)
            }
        }
    }

    @objc
    private func confirmWidget(_ sender: Any) {
        guard let pmmWidget = pmmWidget else { return }
        statusLabel.text = "confirming..."
        pmmWidget.confirm { [weak self] result in
            DispatchQueue.main.async {
                self?.updateStatus(result)
            }
        }
    }

    @objc
    private func reloadSession(_ sender: Any) {
        statusLabel.text = "Fetching fresh PM session..."
        hyperViewModel.preparePaymentMethodManagement()
    }

    private func configureAppearance(_ configuration: inout PaymentSheet.Configuration) {
        var appearance = PaymentSheet.Appearance()
        appearance.colors.background = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.00)
        appearance.primaryButton.shapes.borderRadius = 32
        configuration.appearance = appearance
    }

    func attachPaymentMethodManagementWidget() {
        NSLayoutConstraint.deactivate(widgetConstraints)
        widgetConstraints.removeAll()
        pmmWidget?.removeFromSuperview()

        guard let paymentSession = hyperViewModel.paymentSession else { return }

        var configuration = PaymentSheet.Configuration()
        configuration.savedPaymentSheetHeaderLabel = "Saved payment methods"
        configuration.displaySavedPaymentMethods = true
        configureAppearance(&configuration)

        let widget = PaymentMethodManagementWidget(paymentSession: paymentSession, configuration: configuration)
        self.pmmWidget = widget

        contentView.addSubview(widget)
        widget.translatesAutoresizingMaskIntoConstraints = false
        widgetConstraints = [
            widget.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            widget.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            widget.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            widget.heightAnchor.constraint(equalToConstant: 420),

            confirmWidgetButton.topAnchor.constraint(equalTo: widget.bottomAnchor, constant: 20),
        ]
        NSLayoutConstraint.activate(widgetConstraints)
        widget.setNeedsLayout()
    }
}

extension PaymentMethodManagementViewController {

    func viewFrame() {
        reloadButton.setTitle("Reload PM Session", for: .normal)
        reloadButton.setTitleColor(.white, for: .normal)
        reloadButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        reloadButton.configuration = reloadButtonConfiguration
        reloadButton.layer.cornerRadius = 10
        reloadButton.backgroundColor = .systemBlue
        reloadButton.addTarget(self, action: #selector(reloadSession(_:)), for: .touchUpInside)
        contentView.addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        reloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
        reloadButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20).isActive = true

        presentSheetButton.setTitle("Launch PMM Sheet", for: .normal)
        presentSheetButton.setTitleColor(.white, for: .normal)
        presentSheetButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        presentSheetButton.configuration = presentSheetButtonConfiguration
        presentSheetButton.layer.cornerRadius = 10
        presentSheetButton.backgroundColor = .systemBlue
        presentSheetButton.addTarget(self, action: #selector(presentSheet(_:)), for: .touchUpInside)
        contentView.addSubview(presentSheetButton)
        presentSheetButton.translatesAutoresizingMaskIntoConstraints = false
        presentSheetButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        presentSheetButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
        presentSheetButton.topAnchor.constraint(equalTo: reloadButton.bottomAnchor, constant: 20).isActive = true

        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 7
        statusLabel.font = .systemFont(ofSize: 18)
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        statusLabel.topAnchor.constraint(equalTo: presentSheetButton.bottomAnchor, constant: 20).isActive = true

        confirmWidgetButton.setTitle("Save Card (confirm)", for: .normal)
        confirmWidgetButton.setTitleColor(.white, for: .normal)
        confirmWidgetButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        confirmWidgetButton.configuration = confirmWidgetButtonConfiguration
        confirmWidgetButton.layer.cornerRadius = 10
        confirmWidgetButton.backgroundColor = .systemBlue
        confirmWidgetButton.addTarget(self, action: #selector(confirmWidget(_:)), for: .touchUpInside)
        contentView.addSubview(confirmWidgetButton)
        confirmWidgetButton.translatesAutoresizingMaskIntoConstraints = false
        confirmWidgetButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        confirmWidgetButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
        confirmWidgetButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20).isActive = true
    }
}
