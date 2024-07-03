//
//  HeadlessViewController.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 02/07/24.
//

import SwiftUI
import UIKit

class HeadlessViewController: UIViewController {
    
    var statusLabel = UILabel()
    var headlessbutton = UIButton()
    var getData = UIButton()
    var confirmButton = UIButton()
    var Image = UIImageView()
    var headlessbuttonConfig = UIButton.Configuration.filled()
    var getDataConfig = UIButton.Configuration.filled()
    var confirmButtonConfig = UIButton.Configuration.filled()
    var handler: PaymentSessionHandler?
    @Published var flag = false
    @ObservedObject var hyperModel = HyperViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hyperModel.preparePaymentSheet()
        
        Image.image = UIImage(systemName: "arrow.3.trianglepath")
        Image.contentMode = .scaleAspectFill
        let tap = UITapGestureRecognizer(target: self, action: #selector(reload))
        Image.addGestureRecognizer(tap)
        Image.isUserInteractionEnabled = true
        view.addSubview(Image)
        Image.translatesAutoresizingMaskIntoConstraints = false
        Image.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        Image.topAnchor.constraint(equalTo: view.topAnchor, constant: 40).isActive = true
        Image.widthAnchor.constraint(equalToConstant: 32).isActive = true
        Image.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        headlessbutton.setTitle("init headless", for: .normal)
        headlessbutton.setTitleColor(.white, for: .normal)
        headlessbuttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        headlessbutton.configuration = headlessbuttonConfig
        headlessbutton.layer.cornerRadius = 10
        headlessbutton.addTarget(self, action: #selector(launchHeadless), for: .touchUpInside)
        view.addSubview(headlessbutton)
        headlessbutton.translatesAutoresizingMaskIntoConstraints = false
        headlessbutton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        headlessbutton.centerYAnchor.constraint(equalTo: view.centerYAnchor,constant: -60).isActive = true
        
        getData.isEnabled = false
        getData.setTitle("getCustomerSavedPaymentMethodData", for: .normal)
        getData.setTitleColor(.white, for: .normal)
        getData.addTarget(self, action: #selector(getCustomerSavedPaymentMethodData), for: .touchUpInside)
        getDataConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        getData.configuration = getDataConfig
        getData.layer.cornerRadius = 10
        view.addSubview(getData)
        getData.translatesAutoresizingMaskIntoConstraints = false
        getData.topAnchor.constraint(equalTo: headlessbutton.bottomAnchor, constant: 20).isActive = true
        getData.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        confirmButton.isEnabled = false
        confirmButton.setTitle("confirm headless", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirmWithCustomerDefaultPaymentMethod), for: .touchUpInside)
        confirmButtonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        confirmButton.configuration = confirmButtonConfig
        confirmButton.layer.cornerRadius = 10
        view.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.topAnchor.constraint(equalTo: getData.bottomAnchor, constant: 20).isActive = true
        confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 15
        statusLabel.font = .systemFont(ofSize: 15)
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.topAnchor.constraint(equalTo: confirmButton.bottomAnchor, constant: 30).isActive = true
        statusLabel.heightAnchor.constraint(equalToConstant: 150).isActive = true
        statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        
    }
    
    @objc
    func reload()
    {
        hyperModel.preparePaymentSheet()
        Image.isUserInteractionEnabled = false
        self.statusLabel.text = ""
        UIView.animate(withDuration: 1.4, animations: {
            self.Image.transform = self.Image.transform.rotated(by: .pi*3)
        }) { (_) in
            self.Image.isUserInteractionEnabled = true
        }
    }
    

    
    func initSavedPaymentMethodSessionCallback(handler: PaymentSessionHandler)-> Void {
        self.handler = handler
    }
    
    
    @objc func launchHeadless(_ sender: Any) {
        hyperModel.paymentSession?.getCustomerSavedPaymentMethods(initSavedPaymentMethodSessionCallback)
        getData.isEnabled = true
    }
    
    @objc func getCustomerSavedPaymentMethodData(_ sender: Any) {
        let paymentMethod = self.handler?.getCustomerDefaultSavedPaymentMethodData()
        switch paymentMethod {
        case let card as Card:
            print(["type": "card", "message": card.toHashMap()])
            self.statusLabel.text = "card → \(card.toHashMap())"
            confirmButton.isEnabled = true
        case let wallet as Wallet:
            print(["type": "wallet", "message": wallet.toHashMap()])
            self.statusLabel.text = "wallet → \(wallet.toHashMap())"
            confirmButton.isEnabled = true
        case let error as PMError:
            print(["type": "error", "message": error.toHashMap()])
            self.statusLabel.text = "error → \(error.toHashMap())"
        default:
            print(["type": "error", "message": ["code": "0", "message": "No Payment Method Available"]])
            self.statusLabel.text = "error → No Payment Method Available"
        }
    }
    
    @objc func confirmWithCustomerDefaultPaymentMethod(_ sender: Any) {
        handler?.confirmWithCustomerDefaultPaymentMethod(nil ,resultHandler)
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