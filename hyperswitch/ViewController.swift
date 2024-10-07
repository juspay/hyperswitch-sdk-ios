//
//  ViewController.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 14/07/23.
//

import UIKit
import SwiftUI
import Combine

class ViewController: UIViewController {
    
    @ObservedObject var hyperViewModel = HyperViewModel()
    private var reloadButton = UIButton()
    private var reloadButtonConfiguration = UIButton.Configuration.plain()
    private var paymentSheetButton = UIButton()
    private var paymentSheetButtonConfiguration = UIButton.Configuration.plain()
    private var paymentMethodManagementButton = UIButton()
    private var paymentMethodManagementButtonConfig = UIButton.Configuration.plain()
    private var statusLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.2)
        super.viewDidLoad()
        hyperViewModel.preparePaymentSheet()
        hyperViewModel.preparePaymentManagementSheet()
        asyncBind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewFrame()
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
        appearance.font.base = UIFont(name: "montserrat", size: UIFont.systemFontSize)
        appearance.font.sizeScaleFactor = 1.0
        appearance.shadow = .disabled
        appearance.colors.background = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.00)
        appearance.colors.primary = UIColor(red: 0.55, green: 0.74, blue: 0.00, alpha: 1.00)
        appearance.primaryButton.cornerRadius = 32
        configuration.appearance = appearance
        
        hyperViewModel.paymentSession?.presentPaymentSheet(viewController: self, configuration: configuration, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .completed:
                    self.statusLabel.text = "Payment complete"
                case .failed(let error):
                    self.statusLabel.text = "Payment failed: \(error)"
                case .canceled:
                    self.statusLabel.text = "Payment canceled."
                }
            }
        })
    }
    
    @objc
    func openPaymentMethodManagement(_ sender: Any) {
        var configuration = PMMConfiguration()
        var appearance = PMMAppearance()
        appearance.font.base = UIFont(name: "montserrat", size: UIFont.systemFontSize)
        appearance.font.sizeScaleFactor = 1.0
        appearance.shadow = .disabled
        appearance.colors.primary = UIColor(red: 0.55, green: 0.74, blue: 0.00, alpha: 1.00)
        appearance.theme = .light
        configuration.appearance = appearance
        
        hyperViewModel.paymentSession?.presentPaymentManagementSheet(viewController: self, configuration: configuration, completion: { result in
            DispatchQueue.main.async {
                switch result {
                case .failed(let error):
                    self.statusLabel.text =  "Payment Method Management failed: \(error)"
                case .closed:
                    self.statusLabel.text = "Payment Method Management closed."
                }
            }
        })
    }
    
    @objc
    func reload(_ sender: Any) {
        hyperViewModel.preparePaymentSheet()
        self.reloadButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 1.6, animations: {
            self.reloadButton.backgroundColor = .white
        }) { (_) in
            self.reloadButton.backgroundColor = .systemBlue
            self.reloadButton.isUserInteractionEnabled = true
        }
    }
}

extension ViewController {
    
    func viewFrame()
    {
        reloadButton.setTitle("Reload Client Secret", for: .normal)
        reloadButton.setTitleColor(.white, for: .normal)
        reloadButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        reloadButton.configuration = reloadButtonConfiguration
        reloadButton.layer.cornerRadius = 10
        reloadButton.backgroundColor = .systemBlue
        reloadButton.addTarget(self, action: #selector(reload(_:)), for: .touchUpInside)
        view.addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60).isActive = true
        reloadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60).isActive = true
        reloadButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 80).isActive = true
        
        paymentSheetButton.setTitle("Launch Payment Sheet", for: .normal)
        paymentSheetButton.setTitleColor(.white, for: .normal)
        paymentSheetButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        paymentSheetButton.configuration = paymentSheetButtonConfiguration
        paymentSheetButton.layer.cornerRadius = 10
        paymentSheetButton.backgroundColor = .systemBlue
        paymentSheetButton.addTarget(self, action: #selector(openPaymentSheet(_:)), for: .touchUpInside)
        view.addSubview(paymentSheetButton)
        paymentSheetButton.translatesAutoresizingMaskIntoConstraints = false
        paymentSheetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60).isActive = true
        paymentSheetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60).isActive = true
        paymentSheetButton.topAnchor.constraint(equalTo: reloadButton.bottomAnchor, constant: 80).isActive = true
        
        paymentMethodManagementButton.setTitle("Payment Method Management", for: .normal)
        paymentMethodManagementButton.setTitleColor(.white, for: .normal)
        paymentMethodManagementButtonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 10)
        paymentMethodManagementButton.configuration = paymentMethodManagementButtonConfig
        paymentMethodManagementButton.backgroundColor = .systemBlue
        paymentMethodManagementButton.layer.cornerRadius = 10
        paymentMethodManagementButton.addTarget(self, action: #selector(openPaymentMethodManagement(_:)), for: .touchUpInside)
        view.addSubview(paymentMethodManagementButton)
        paymentMethodManagementButton.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodManagementButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60).isActive = true
        paymentMethodManagementButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60).isActive = true
        paymentMethodManagementButton.topAnchor.constraint(equalTo: paymentSheetButton.bottomAnchor, constant: 80).isActive = true
        
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 7
        statusLabel.font = .systemFont(ofSize: 18)
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        statusLabel.topAnchor.constraint(equalTo: paymentMethodManagementButton.bottomAnchor, constant: 50).isActive = true
    }
}
