//
//  HeadlessViewController.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 02/07/24.
//

import SwiftUI
import UIKit
import Combine

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
                }
            }
            .store(in: &cancellables)
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
    
    
    func initSavedPaymentMethodSessionCallback(handler: PaymentSessionHandler)-> Void {
        self.handler = handler
    }
    
    
    @objc func launchHeadless(_ sender: Any) {
        hyperViewModel.paymentSession?.getCustomerSavedPaymentMethods(initSavedPaymentMethodSessionCallback)
        getDefault.isEnabled = true
        getLast.isEnabled = true
        getData.isEnabled = true

    }
    
    @objc func getCustomerDefaultSavedPaymentMethodData(_ sender: Any) {
        let paymentMethod = self.handler?.getCustomerDefaultSavedPaymentMethodData()
        switch paymentMethod {
        case let paymentMethodType as PaymentMethodType:
            print(["type": paymentMethodType.paymentMethod, "message": paymentMethodType.toHashMap()])
            self.statusLabel.text = "\(paymentMethodType.paymentMethod) → \(paymentMethodType.toHashMap())"
            confirmDefault.isEnabled = true
        case let error as PMError:
            print(["type": "error", "message": error.toHashMap()])
            self.statusLabel.text = "error → \(error.toHashMap())"
        default:
            print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
            self.statusLabel.text = "error → No Payment Method Available"
        }
    }
    
    @objc func getCustomerLastUsedPaymentMethodData(_ sender: Any) {
        let paymentMethod = self.handler?.getCustomerLastUsedPaymentMethodData()
        switch paymentMethod {
        case let paymentMethodType as PaymentMethodType:
            print(["type": paymentMethodType.paymentMethod, "message": paymentMethodType.toHashMap()])
            self.statusLabel.text = "\(paymentMethodType.paymentMethod) → \(paymentMethodType.toHashMap())"
            confirmLast.isEnabled = true
        case let error as PMError:
            print(["type": "error", "message": error.toHashMap()])
            self.statusLabel.text = "error → \(error.toHashMap())"
        default:
            print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
            self.statusLabel.text = "error → No Payment Method Available"
        }
    }
    
    @objc func getCustomerSavedPaymentMethodData(_ sender: Any) {
        let paymentMethod = self.handler?.getCustomerSavedPaymentMethodData()
        
        guard let pm = paymentMethod else{
            print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
            self.statusLabel.text = "error → No Payment Method Available"
            return
        }
        for paymentMethods in pm{
            switch paymentMethods {
            case let paymentMethodType as PaymentMethodType:
                print(["type": paymentMethodType.paymentMethod, "message": paymentMethodType.toHashMap()])
                self.statusLabel.text = "\(paymentMethodType.paymentMethod) → \(paymentMethodType.toHashMap())"
                confirm.isEnabled = true
            case let error as PMError:
                print(["type": "error", "message": error.toHashMap()])
                self.statusLabel.text = "error → \(error.toHashMap())"
            default:
                print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
                self.statusLabel.text = "error → No Payment Method Available"
            }
        }
    }
    
    @objc func confirmWithCustomerDefaultPaymentMethod(_ sender: Any) {
        handler?.confirmWithCustomerDefaultPaymentMethod(resultHandler: resultHandler)
    }
    
    @objc func confirmWithCustomerLastUsedPaymentMethod(_ sender: Any) {
        handler?.confirmWithCustomerLastUsedPaymentMethod(resultHandler: resultHandler)
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
    func viewFrame(){   
        stackView.axis  = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalCentering
        stackView.spacing = 20.0
        stackView.addArrangedSubview(reloadButton)
        stackView.addArrangedSubview(headlessbutton)
        stackView.addArrangedSubview(getDefault)
        stackView.addArrangedSubview(getLast)
        stackView.addArrangedSubview(getData)
        stackView.addArrangedSubview(confirmDefault)
        stackView.addArrangedSubview(confirmLast)
        stackView.addArrangedSubview(confirm)
        stackView.addArrangedSubview(statusLabel)
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 80).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
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
        statusLabel.numberOfLines = 15
        statusLabel.font = .systemFont(ofSize: 15)
    }
}
