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

    private var updateIntentButton = UIButton()
    private var updateIntentButtonConfiguration = UIButton.Configuration.plain()

    private var getCustomerSPMButton = UIButton()
    private var getCustomerSPMButtonConfiguration = UIButton.Configuration.plain()

    private var confirmPaymentWidgetButton = UIButton()
    private var confirmPaymentWidgetButtonConfiguration = UIButton.Configuration.plain()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private var statusLabel = UILabel()
    private var cancellables = Set<AnyCancellable>()
    private var paymentWidget: PaymentWidget?
    private var cvcWidget: CVCWidget?
    private var confirmButton = UIButton()
    private var confirmButtonConfiguration = UIButton.Configuration.plain()

    private var elementConfirmButton = UIButton()
    private var elementConfirmButtonConfiguration = UIButton.Configuration.plain()
    private var handler: PaymentSessionHandler?
    private var paymentToken: String?
    private var paymentMethodId: String?

    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.2)
        super.viewDidLoad()
        hyperViewModel.fetchNetceteraSDKApiKey()
        hyperViewModel.preparePaymentSheet()
        setupScrollView()
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

    func initSavedPaymentMethodSessionCallback(handler: PaymentSessionHandler) {
        self.handler = handler
        let paymentMethod = handler.getCustomerLastUsedPaymentMethodData()
        switch paymentMethod {
        case .success(let paymentMethod):
            if paymentMethod.requiresCvv == true {
                paymentToken = paymentMethod.paymentToken
                paymentMethodId = paymentMethod.paymentMethodId
                confirmButton.isEnabled = true
                self.statusLabel.text = "\(paymentMethod)"
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
            self.paymentWidget = PaymentWidget(paymentSession: paymentSession, configuration: configuration) { paymentResult in
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
            self.paymentWidget?.shouldProceedWithPayment { paymentRequestData, callback in
                switch paymentRequestData.paymentMethodType {
                case .applePay:
                    print("applePay")
                // callback(false)
                case .payPal:
                    print("payPal")
                // callback(false)
                }
            }
            if let hyperswitch = hyperViewModel.hyperswitch {
                self.cvcWidget = CVCWidget(
                    hyperswitch: hyperswitch,
                    configuration: configuration,
                    subscribe: { builder in
                        builder.on(.cvcStatus) { event in
                            if case .cvcStatus(let info) = event.data {
                                print(info)
                            }
                        }
                    }
                )
            }
            if let cvcWidget = cvcWidget {
                contentView.addSubview(cvcWidget)
                cvcWidget.translatesAutoresizingMaskIntoConstraints = false
                cvcWidget.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
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
                contentView.addSubview(confirmButton)
                confirmButton.translatesAutoresizingMaskIntoConstraints = false
                confirmButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
                confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
                confirmButton.topAnchor.constraint(equalTo: cvcWidget.bottomAnchor, constant: 20).isActive = true
                confirmButton.addTarget(self, action: #selector(confirm(_:)), for: .touchUpInside)

                if let paymentWidget = paymentWidget {
                    contentView.addSubview(paymentWidget)
                    paymentWidget.translatesAutoresizingMaskIntoConstraints = false
                    paymentWidget.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
                    paymentWidget.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
                    paymentWidget.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 20).isActive = true
                    paymentWidget.heightAnchor.constraint(equalToConstant: 400).isActive = true

                    elementConfirmButton.setTitle("confirm", for: .normal)
                    elementConfirmButton.setTitleColor(.white, for: .normal)
                    elementConfirmButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(
                        top: 10,
                        leading: 10,
                        bottom: 10,
                        trailing: 10
                    )
                    elementConfirmButton.configuration = elementConfirmButtonConfiguration
                    elementConfirmButton.layer.cornerRadius = 10
                    elementConfirmButton.backgroundColor = .systemBlue
                    //                    elementConfirmButton.isEnabled = false
                    contentView.addSubview(elementConfirmButton)
                    elementConfirmButton.translatesAutoresizingMaskIntoConstraints = false
                    elementConfirmButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
                    elementConfirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
                    elementConfirmButton.topAnchor.constraint(equalTo: paymentWidget.bottomAnchor, constant: 20).isActive = true
                    elementConfirmButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
                    elementConfirmButton.addTarget(self, action: #selector(confirmElement(_:)), for: .touchUpInside)
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
    func updateIntent(_ sender: Any) {
        hyperViewModel.updatePaymentIntent()
        self.updateIntentButton.isUserInteractionEnabled = false
        UIView.animate(
            withDuration: 1.6,
            animations: {
                self.updateIntentButton.backgroundColor = .white
            }
        ) { (_) in
            self.updateIntentButton.backgroundColor = .systemBlue
            self.updateIntentButton.isUserInteractionEnabled = true
        }
    }

    @objc
    func getCustomerSPM(_ sender: Any) {
        hyperViewModel.paymentSession?.getCustomerSavedPaymentMethods(initSavedPaymentMethodSessionCallback)
    }
    @objc
    func confirm(_ sender: Any) {
        if let cvcWidget = cvcWidget
        {
            self.handler?.confirmWithCustomerLastUsedPaymentMethod(cvcWidget, resultHandler: resultHandler)
        }
    }

    @objc
    func confirmElement(_ sender: Any) {
        if let paymentWidget = paymentWidget {
            paymentWidget.confirm()
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
        contentView.addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        reloadButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        reloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
        reloadButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80).isActive = true

        updateIntentButton.setTitle("Update Intent", for: .normal)
        updateIntentButton.setTitleColor(.white, for: .normal)
        updateIntentButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        updateIntentButton.configuration = updateIntentButtonConfiguration
        updateIntentButton.layer.cornerRadius = 10
        updateIntentButton.backgroundColor = .systemBlue
        updateIntentButton.addTarget(self, action: #selector(updateIntent(_:)), for: .touchUpInside)
        contentView.addSubview(updateIntentButton)
        updateIntentButton.translatesAutoresizingMaskIntoConstraints = false
        updateIntentButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        updateIntentButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
        updateIntentButton.topAnchor.constraint(equalTo: reloadButton.bottomAnchor, constant: 20).isActive = true

        getCustomerSPMButton.setTitle("Get Customer SPM", for: .normal)
        getCustomerSPMButton.setTitleColor(.white, for: .normal)
        getCustomerSPMButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        getCustomerSPMButton.configuration = getCustomerSPMButtonConfiguration
        getCustomerSPMButton.layer.cornerRadius = 10
        getCustomerSPMButton.backgroundColor = .systemBlue
        getCustomerSPMButton.addTarget(self, action: #selector(getCustomerSPM(_:)), for: .touchUpInside)
        contentView.addSubview(getCustomerSPMButton)
        getCustomerSPMButton.translatesAutoresizingMaskIntoConstraints = false
        getCustomerSPMButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        getCustomerSPMButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60).isActive = true
        getCustomerSPMButton.topAnchor.constraint(equalTo: updateIntentButton.bottomAnchor, constant: 20).isActive = true

        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 7
        statusLabel.font = .systemFont(ofSize: 18)
        contentView.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        statusLabel.topAnchor.constraint(equalTo: getCustomerSPMButton.bottomAnchor, constant: 20).isActive = true
    }
}
