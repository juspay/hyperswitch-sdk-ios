//
//  ViewController.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 14/07/23.
//

import UIKit
import SwiftUI

class ViewController: UIViewController {
    
    @ObservedObject var hyperViewModel = HyperViewModel()
    var reloadButton = UIButton()
    var reloadButtonConfiguration = UIButton.Configuration.plain()
    var paymentSheetButton = UIButton()
    var paymentSheetButtonConfiguration = UIButton.Configuration.plain()
    var statusLabel = UILabel()
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.2)
        super.viewDidLoad()
        hyperViewModel.preparePaymentSheet()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewFrame()
    }
    
    @objc 
    func openPaymentSheet(_ sender: Any) {
        hyperViewModel.paymentSheet?.present(from: self, completion: { result in
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
        paymentSheetButton.topAnchor.constraint(equalTo: reloadButton.bottomAnchor, constant: 200).isActive = true
        
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 7
        statusLabel.font = .systemFont(ofSize: 18)
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        statusLabel.topAnchor.constraint(equalTo: paymentSheetButton.bottomAnchor, constant: 50).isActive = true
    }
}
