//
//  HeadlessViewController.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 02/07/24.
//

import Combine
import SwiftUI
import UIKit

class HeadlessViewController: UIViewController {

    @ObservedObject var hyperViewModel = HyperViewModel()

    private let statusLabel = UILabel()
    private let stackView = UIStackView()
    private let scrollView = UIScrollView()

    private let headlessbutton = UIButton()
    private let getDefault = UIButton()
    private let getLast = UIButton()
    private let getData = UIButton()
    private let confirmDefault = UIButton()
    private let confirmLast = UIButton()
    private let confirm = UIButton()
    private let reloadButton = UIButton()

    private var headlessbuttonConfig = UIButton.Configuration.filled()
    private var getDefaultConfig = UIButton.Configuration.filled()
    private var getLastConfig = UIButton.Configuration.filled()
    private var getDataConfig = UIButton.Configuration.filled()
    private var confirmDefaultConfig = UIButton.Configuration.filled()
    private var confirmLastConfig = UIButton.Configuration.filled()
    private var confirmConfig = UIButton.Configuration.filled()
    private var reloadButtonConfiguration = UIButton.Configuration.plain()

    private let cvcToggle = UISwitch()
    private let cvcRow = UIStackView()
    private let confirmDefaultCVC = UIButton()
    private let confirmLastCVC = UIButton()
    private lazy var cvcWidget = CVCWidget()

    private var handler: PaymentSessionHandler?
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.2)
        viewFrame()
        hyperViewModel.preparePaymentSheet()
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
                case .info(let message):
                    self?.statusLabel.text = message
                }
            }
            .store(in: &cancellables)
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

    func initSavedPaymentMethodSessionCallback(handler: PaymentSessionHandler) {
        self.handler = handler
    }

    @objc func launchHeadless(_ sender: Any) {
        hyperViewModel.paymentSession?.getCustomerSavedPaymentMethods(initSavedPaymentMethodSessionCallback)
        getDefault.isEnabled = true
        getLast.isEnabled = true
        getData.isEnabled = true

    }

    @objc func getCustomerDefaultSavedPaymentMethodData(_ sender: Any) {

        guard let handler = self.handler else {
            self.statusLabel.text = "error → Handler unavailable"
            return
        }

        let paymentMethod = handler.getCustomerDefaultSavedPaymentMethodData()
        switch paymentMethod {
        case .success(let paymentMethod):
            print(["type": paymentMethod.paymentMethod, "message": paymentMethod])
            self.statusLabel.text = "\(paymentMethod.paymentMethod) → \(paymentMethod)"
            confirmDefault.isEnabled = true
            confirmDefaultCVC.isEnabled = true
        case .failure(let error):
            print(["type": "error", "message": error])
            self.statusLabel.text = "error → \(error)"
        }
    }

    @objc func getCustomerLastUsedPaymentMethodData(_ sender: Any) {

        guard let handler = self.handler else {
            self.statusLabel.text = "error → Handler unavailable"
            return
        }

        let paymentMethod = handler.getCustomerLastUsedPaymentMethodData()
        switch paymentMethod {
        case .success(let paymentMethod):
            print(["type": paymentMethod.paymentMethod, "message": paymentMethod])
            self.statusLabel.text = "\(paymentMethod.paymentMethod) → \(paymentMethod)"
            confirmLast.isEnabled = true
            confirmLastCVC.isEnabled = true
        case .failure(let error):
            print(["type": "error", "message": error])
            self.statusLabel.text = "error → \(error)"
        }
    }

    @objc func getCustomerSavedPaymentMethodData(_ sender: Any) {

        guard let handler = self.handler else {
            self.statusLabel.text = "error → Handler unavailable"
            return
        }

        let paymentMethod = handler.getCustomerSavedPaymentMethodData()
        switch paymentMethod {
        case .success(let paymentMethods):
            for paymentMethod in paymentMethods {
                print(["type": paymentMethod.paymentMethod, "message": paymentMethod])
                self.statusLabel.text = "\(paymentMethod.paymentMethod) → \(paymentMethod)"
                confirm.isEnabled = true
            }
        case .failure(let error):
            print(["type": "error", "message": error])
            self.statusLabel.text = "error → \(error)"
        }
    }

    @objc func confirmWithCustomerDefaultPaymentMethod(_ sender: Any) {
        handler?.confirmWithCustomerDefaultPaymentMethod(resultHandler: resultHandler)
    }

    @objc func confirmWithCustomerLastUsedPaymentMethod(_ sender: Any) {
        handler?.confirmWithCustomerLastUsedPaymentMethod(resultHandler: resultHandler)
    }

    @objc func confirmWithCustomerDefaultPaymentMethodCVC(_ sender: Any) {
        handler?.confirmWithCustomerDefaultPaymentMethod(cvcWidget: cvcWidget, resultHandler: resultHandler)
    }

    @objc func confirmWithCustomerLastUsedPaymentMethodCVC(_ sender: Any) {
        handler?.confirmWithCustomerLastUsedPaymentMethod(cvcWidget: cvcWidget, resultHandler: resultHandler)
    }

    @objc func toggleCVCWidget(_ sender: UISwitch) {
        [cvcWidget, confirmDefaultCVC, confirmLastCVC].forEach { $0.isHidden = !sender.isOn }
    }

    @objc func confirmWithCustomerPaymentToken(_ sender: Any) {
        //        handler?.confirmWithCustomerPaymentToken(<#T##String#>, <#T##String?#>, <#T##(PaymentResult) -> Void#>)
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
}

extension HeadlessViewController {
    func viewFrame() {
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 16.0
        stackView.addArrangedSubview(reloadButton)
        stackView.addArrangedSubview(headlessbutton)
        stackView.addArrangedSubview(getDefault)
        stackView.addArrangedSubview(getLast)
        stackView.addArrangedSubview(getData)
        stackView.addArrangedSubview(confirmDefault)
        stackView.addArrangedSubview(confirmLast)
        stackView.addArrangedSubview(cvcRow)
        stackView.addArrangedSubview(cvcWidget)
        stackView.addArrangedSubview(confirmDefaultCVC)
        stackView.addArrangedSubview(confirmLastCVC)
        stackView.addArrangedSubview(confirm)
        stackView.addArrangedSubview(statusLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 60),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -60),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -120),
        ])

        reloadButton.setTitle("Reload Client Secret", for: .normal)
        reloadButton.setTitleColor(.white, for: .normal)
        reloadButtonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        reloadButton.configuration = reloadButtonConfiguration
        reloadButton.layer.cornerRadius = 10
        reloadButton.backgroundColor = .systemBlue
        reloadButton.addTarget(self, action: #selector(reload(_:)), for: .touchUpInside)

        headlessbutton.setTitle("Initialize Headless", for: .normal)
        headlessbutton.setTitleColor(.white, for: .normal)
        headlessbuttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        headlessbutton.configuration = headlessbuttonConfig
        headlessbutton.layer.cornerRadius = 10
        headlessbutton.addTarget(self, action: #selector(launchHeadless), for: .touchUpInside)

        getDefault.isEnabled = false
        getDefault.setTitle("Get Default Data", for: .normal)
        getDefault.setTitleColor(.white, for: .normal)
        getDefault.addTarget(self, action: #selector(getCustomerDefaultSavedPaymentMethodData), for: .touchUpInside)
        getDefaultConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        getDefault.configuration = getDefaultConfig
        getDefault.layer.cornerRadius = 10

        getLast.isEnabled = false
        getLast.setTitle("Get Last Used Data", for: .normal)
        getLast.setTitleColor(.white, for: .normal)
        getLast.addTarget(self, action: #selector(getCustomerLastUsedPaymentMethodData), for: .touchUpInside)
        getLastConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        getLast.configuration = getLastConfig
        getLast.layer.cornerRadius = 10

        getData.isEnabled = false
        getData.setTitle("Get Data", for: .normal)
        getData.setTitleColor(.white, for: .normal)
        getData.addTarget(self, action: #selector(getCustomerSavedPaymentMethodData), for: .touchUpInside)
        getDataConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        getData.configuration = getDataConfig
        getData.layer.cornerRadius = 10

        let cvcLabel = UILabel()
        cvcLabel.text = "Use CVC widget"
        cvcLabel.font = .systemFont(ofSize: 15)
        cvcRow.axis = .horizontal
        cvcRow.addArrangedSubview(cvcLabel)
        cvcRow.addArrangedSubview(cvcToggle)
        cvcToggle.addTarget(self, action: #selector(toggleCVCWidget(_:)), for: .valueChanged)

        cvcWidget.isHidden = true
        cvcWidget.heightAnchor.constraint(equalToConstant: 44).isActive = true

        confirmDefaultCVC.isHidden = true
        confirmDefaultCVC.isEnabled = false
        confirmDefaultCVC.setTitle("Confirm Default + CVC Widget", for: .normal)
        confirmDefaultCVC.addTarget(self, action: #selector(confirmWithCustomerDefaultPaymentMethodCVC), for: .touchUpInside)
        confirmDefaultCVC.configuration = confirmDefaultConfig

        confirmLastCVC.isHidden = true
        confirmLastCVC.isEnabled = false
        confirmLastCVC.setTitle("Confirm Last Used + CVC Widget", for: .normal)
        confirmLastCVC.addTarget(self, action: #selector(confirmWithCustomerLastUsedPaymentMethodCVC), for: .touchUpInside)
        confirmLastCVC.configuration = confirmLastConfig

        confirmDefault.isEnabled = false
        confirmDefault.setTitle("Confirm With Default", for: .normal)
        confirmDefault.setTitleColor(.white, for: .normal)
        confirmDefault.addTarget(self, action: #selector(confirmWithCustomerDefaultPaymentMethod), for: .touchUpInside)
        confirmDefaultConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        confirmDefault.configuration = confirmDefaultConfig
        confirmDefault.layer.cornerRadius = 10

        confirmLast.isEnabled = false
        confirmLast.setTitle("Confirm With Last Used", for: .normal)
        confirmLast.setTitleColor(.white, for: .normal)
        confirmLast.addTarget(self, action: #selector(confirmWithCustomerLastUsedPaymentMethod), for: .touchUpInside)
        confirmLastConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        confirmLast.configuration = confirmLastConfig
        confirmLast.layer.cornerRadius = 10

        confirm.isEnabled = false
        confirm.setTitle("Confirm With Payment Token", for: .normal)
        confirm.setTitleColor(.white, for: .normal)
        confirm.addTarget(self, action: #selector(confirmWithCustomerPaymentToken), for: .touchUpInside)
        confirmConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        confirm.configuration = confirmConfig
        confirm.layer.cornerRadius = 10

        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 15)
    }
}
