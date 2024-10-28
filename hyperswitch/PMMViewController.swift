import Foundation
import WebKit
import Combine
import SwiftUI

class PaymentMethodManagementViewController: UIViewController {
    @ObservedObject var hyperViewModel = HyperViewModel()
    private var paymentSession: PaymentSession?
    private var cancellables = Set<AnyCancellable>()
    
    private func setupPaymentWidget(topElement: UIView, onAddPaymentMethod: @escaping () -> Void) {
        guard hyperViewModel.paymentSession != nil else { return }
        
        let paymentWidget = PaymentMethodManagementWidget(
            ephemeralKey: PaymentSession.ephemeralKey ?? "",
            frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height-160),
            onAddPaymentMethod: onAddPaymentMethod,
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .failed(let error):
                        print("Payment Method Management failed: \(error)")
                    case .closed:
                        print("Payment Method Management closed.")
                    }
                }
            }
        )
        
        view.addSubview(paymentWidget)
        paymentWidget.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paymentWidget.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paymentWidget.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paymentWidget.topAnchor.constraint(equalTo: topElement.bottomAnchor, constant: 20),
            paymentWidget.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func asyncBindPaymentManagementWidget(topElement: UIView, onAddPaymentMethod: @escaping () -> Void) {
        hyperViewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .loading:
                    print("Loading payment method management session...")
                case .success:
                    self?.setupPaymentWidget(topElement: topElement, onAddPaymentMethod: onAddPaymentMethod)
                case .failure(let error):
                    print("Failed to prepare payment method management session: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Hyperswitch"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        
        let backButton = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.backward")
        config.imagePlacement = .leading
        backButton.configuration = config
        backButton.tintColor = UIColor(red: 5/255, green: 112/255, blue: 222/255, alpha: 1.0)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        
        let onAddPaymentMethod: () -> Void = {
            DispatchQueue.main.async {
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
                        print(result)
                    }
                })
            }
        }
        
        hyperViewModel.preparePaymentMethodManagement()
        asyncBindPaymentManagementWidget(topElement: titleLabel, onAddPaymentMethod: onAddPaymentMethod)
    }
    
    @objc func backButtonTapped() {
        PaymentMethodManagementWidget.exitWidget()
        self.dismiss(animated: true, completion: nil)
    }
}
