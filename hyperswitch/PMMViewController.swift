import Foundation
import WebKit
import Combine
import SwiftUI

class PaymentMethodManagementViewController: UIViewController {
    @ObservedObject var hyperViewModel = HyperViewModel()
    private var paymentSession: PaymentSession?
    private var cancellables = Set<AnyCancellable>()
    private let topBarView = UIView()
    private let textLabel = UILabel()
    private let backButton = UIButton(type: .custom)
    
    private func setupPaymentWidget(onAddPaymentMethod: @escaping () -> Void) {
        guard hyperViewModel.paymentSession != nil else { return }
        
        lazy var paymentWidget = PaymentMethodManagementWidget(
            onAddPaymentMethod: onAddPaymentMethod,
            completion: { result in
                switch result {
                case .failed(let error):
                    print("Payment Method Management failed: \(error)")
                case .closed:
                    print("Payment Method Management closed.")
                }
            }
        )
        
        view.addSubview(paymentWidget)
        paymentWidget.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paymentWidget.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paymentWidget.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paymentWidget.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            paymentWidget.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func asyncBindPaymentManagementWidget(onAddPaymentMethod: @escaping () -> Void) {
        hyperViewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .loading:
                    print("Loading payment method management session...")
                case .success:
                    self?.setupPaymentWidget(onAddPaymentMethod: onAddPaymentMethod)
                case .failure(let error):
                    print("Failed to prepare payment method management session: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
        viewFrame()
        hyperViewModel.preparePaymentMethodManagement()
        asyncBindPaymentManagementWidget(onAddPaymentMethod: onAddPaymentMethod)
    }
    
    @objc func onAddPaymentMethod() -> Void {
        var configuration = PaymentSheet.Configuration()
        configuration.primaryButtonLabel = "Purchase ($0.00)"
        configuration.paymentSheetHeaderLabel = "Add payment method"
        configuration.displaySavedPaymentMethods = false
        
        var appearance = PaymentSheet.Appearance()
        appearance.colors.background = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.00)
        appearance.primaryButton.cornerRadius = 32
        configuration.appearance = appearance
        
        self.hyperViewModel.paymentSession?.presentPaymentSheet(viewController: self, configuration: configuration, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .completed:
                    self.hyperViewModel.preparePaymentMethodManagement()
                default: break
                }
            }
        })
    }
    @objc func backButtonTapped() {
        PaymentMethodManagementWidget.exitWidget()
        self.dismiss(animated: true, completion: nil)
    }
}

extension PaymentMethodManagementViewController {
    func viewFrame() {
        view.addSubview(topBarView)
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topBarView.heightAnchor.constraint(equalToConstant: 65).isActive = true
        
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        topBarView.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.topAnchor.constraint(equalTo: topBarView.topAnchor, constant: 20).isActive = true
        backButton.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 10).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        textLabel.text = "Hyperswitch"
        textLabel.font = .boldSystemFont(ofSize: 16.5)
        topBarView.addSubview(textLabel)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.topAnchor.constraint(equalTo: topBarView.topAnchor, constant: 23.5).isActive = true
        textLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4).isActive = true
        textLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
    }
}
