//
//  WidgetViewController.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Combine
import SwiftUI
import UIKit

class WidgetViewController: UIViewController {

    @ObservedObject var hyperViewModel = HyperViewModel()
    private var reloadButton = UIButton()
    private var reloadButtonConfiguration = UIButton.Configuration.plain()
    private var statusLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()
    private var paymentWidget: PaymentWidget?
    private var cvcWidget: CVCWidget?
    private var confirmButton = UIButton()
    private var confirmButtonConfiguration = UIButton.Configuration.plain()
    private var handler: PaymentSessionHandler?
    private var paymentToken: String?
    private var paymentMethodId: String?

    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.2)
        super.viewDidLoad()
        hyperViewModel.fetchNetceteraSDKApiKey()
        hyperViewModel.preparePaymentSheet()
        asyncBind()
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
                    self?.attachPaymentWidget()
                case .failure(let message):
                    self?.statusLabel.text = message
                }
            }
            .store(in: &cancellables)
    }

    func initSavedPaymentMethodSessionCallback(handler: PaymentSessionHandler) {
        self.handler = handler
        let paymentMethod = handler.getCustomerDefaultSavedPaymentMethodData()
        switch paymentMethod {
        case .success(let paymentMethod):
            if paymentMethod.requiresCvv == true {
                paymentToken = paymentMethod.paymentToken
                paymentMethodId = paymentMethod.paymentMethodId
                confirmButton.isEnabled = true
            }
        case .failure(let error):
            print(["type": "error", "message": error])
            self.statusLabel.text = "error → \(error)"
        }

    }

    func resultHandler(_ paymentResult: PaymentResult) {
        switch paymentResult {
        case .completed(let data):
            print(["type": "completed", "message": data])
            self.statusLabel.text = "completed → \(data)"
        case .canceled(let data):
            print(["type": "canceled", "message": data])
            self.statusLabel.text = "canceled → \(data)"
        case .failed(let error):
            print(["type": "failed", "message": "\(error)"])
            self.statusLabel.text = "failed → \(error)"
        }
    }

    func attachPaymentWidget() {
        hyperViewModel.paymentSession?.getCustomerSavedPaymentMethods(initSavedPaymentMethodSessionCallback)

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
        if let netceteraApiKey = hyperViewModel.netceteraApiKey {
            configuration.netceteraSDKApiKey = netceteraApiKey
        }

        if let paymentSession = hyperViewModel.paymentSession {
            self.paymentWidget = PaymentWidget(paymentSession: paymentSession, configuration: configuration) { x in
                print(x)
            }
            self.cvcWidget = CVCWidget(paymentSession: paymentSession, configuration: configuration)
            if let cvcWidget = cvcWidget {
                view.addSubview(cvcWidget)
                cvcWidget.translatesAutoresizingMaskIntoConstraints = false
                cvcWidget.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                cvcWidget.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20).isActive = true
                cvcWidget.heightAnchor.constraint(equalToConstant: 40).isActive = true
                cvcWidget.widthAnchor.constraint(equalToConstant: 100).isActive = true

                confirmButton.setTitle("confirm", for: .normal)
                confirmButton.setTitleColor(.white, for: .normal)
                confirmButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                confirmButton.configuration = confirmButtonConfiguration
                confirmButton.layer.cornerRadius = 10
                confirmButton.backgroundColor = .systemBlue
                confirmButton.isEnabled = false
                view.addSubview(confirmButton)
                confirmButton.translatesAutoresizingMaskIntoConstraints = false
                confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60).isActive = true
                confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60).isActive = true
                confirmButton.topAnchor.constraint(equalTo: cvcWidget.bottomAnchor, constant: 20).isActive = true
                confirmButton.addTarget(self, action: #selector(confirm(_:)), for: .touchUpInside)

                if let paymentWidget = paymentWidget {
                    view.addSubview(paymentWidget)
                    paymentWidget.translatesAutoresizingMaskIntoConstraints = false
                    paymentWidget.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
                    paymentWidget.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
                    paymentWidget.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 20).isActive = true
                    paymentWidget.heightAnchor.constraint(equalToConstant: 400).isActive = true
                }
            }
        }
    }

    @objc
    func reload(_ sender: Any) {
        hyperViewModel.preparePaymentSheet()
        self.reloadButton.isUserInteractionEnabled = false
        UIView.animate(
            withDuration: 1.6,
            animations: {
                self.reloadButton.backgroundColor = .white
            }
        ) { (_) in
            self.reloadButton.backgroundColor = .systemBlue
            self.reloadButton.isUserInteractionEnabled = true
        }
    }
    @objc
    func confirm(_ sender: Any) {
        if let cvcWidget = cvcWidget,
            let paymentToken = paymentToken,
            let paymentMethodId = paymentMethodId
        {
            self.handler?.confirmWithCustomerLastUsedPaymentMethod(cvcWidget, resultHandler: resultHandler)
        }
    }
}

extension WidgetViewController {

    func viewFrame() {
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

        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 7
        statusLabel.font = .systemFont(ofSize: 18)
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        statusLabel.topAnchor.constraint(equalTo: reloadButton.bottomAnchor, constant: 20).isActive = true
    }
}
