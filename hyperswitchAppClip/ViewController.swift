//
//  ViewController.swift
//  hyperswitchAppClip
//
//  Created by Harshit Srivastava on 30/08/24.
//

import SwiftUI
import WebKit
import Combine

class ViewController: UIViewController {
    
    private let payButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pay with Hyperswitch", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    private var statusLabel = UILabel()
    
    private var cancellables = Set<AnyCancellable>()
    
    @ObservedObject var hyperViewModel = HyperViewModel()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        hyperViewModel.preparePaymentSheet()
        
        view.backgroundColor = .white
        view.addSubview(payButton)
        
        payButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            payButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            payButton.widthAnchor.constraint(equalToConstant: 250),
            payButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        payButton.addTarget(self, action: #selector(openPaymentSheet), for: .touchUpInside)
        
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 7
        statusLabel.font = .systemFont(ofSize: 18)
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        statusLabel.topAnchor.constraint(equalTo: payButton.bottomAnchor, constant: 50).isActive = true
        
        asyncBind()
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
                case .failure(let message):
                    self?.statusLabel.text = message
                }
            }
            .store(in: &cancellables)
    }
    
    @objc
    func openPaymentSheet(_ sender: Any) {
        
        var configuration = PaymentSheet.Configuration()
        configuration.primaryButtonLabel = "Purchase ($2.00)"
        configuration.savedPaymentSheetHeaderLabel = "Payment methods"
        configuration.paymentSheetHeaderLabel = "Select payment method"
        configuration.displaySavedPaymentMethods = true
        
        var appearance = PaymentSheet.Appearance()
        appearance.font.lite.base = "Montserrat-Regular"
        appearance.font.lite.sizeScaleFactor = 1.0
        appearance.shadow = .disabled
        appearance.colors.background = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.00)
        appearance.colors.primary = UIColor(red: 0.55, green: 0.74, blue: 0.00, alpha: 1.00)
        appearance.primaryButton.cornerRadius = 32
        configuration.appearance = appearance
        
        hyperViewModel.paymentSession?.presentPaymentSheetLite(viewController: self, configuration: configuration, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .completed:
                    self.statusLabel.text = "Payment complete"
                case .failed(let error):
                    self.statusLabel.text =  "Payment failed: \(error)"
                case .canceled:
                    self.statusLabel.text = "Payment canceled."
                }
            }
        })
    }
}
