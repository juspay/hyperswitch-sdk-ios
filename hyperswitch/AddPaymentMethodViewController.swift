//
//  AddPaymentMethodViewController.swift
//  hyperswitch
//
//  Created by Shivam Nan on 18/10/24.
//

import Foundation
import UIKit

class AddPaymentMethodViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the background color to differentiate the new screen
        view.backgroundColor = .white
        
        // Add a title label
        let titleLabel = UILabel()
        titleLabel.text = "Add Payment Method"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        
        // Create a back button
        let backButton = UIButton(type: .system)
        // Use UIButtonConfiguration to set up the button with an image
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.backward") // Using SF Symbols
        config.imagePlacement = .leading // Set image to appear on the left
        backButton.configuration = config
        
        // Set the tint color for the icon
        backButton.tintColor = UIColor(red: 5/255, green: 112/255, blue: 222/255, alpha: 1.0)
        
        // Add target action for back button
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        
        // Add the label to the view
        view.addSubview(titleLabel)
        view.addSubview(backButton)
        
        // Set up Auto Layout constraints for the title label
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Back button constraints
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            
            // Title label constraints
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        
        let formPlaceholderLabel1 = UILabel()
        formPlaceholderLabel1.text = "Payment Sheet goes here!"
        let formPlaceholderLabel2 = UILabel()
        formPlaceholderLabel2.text = PaymentSession.paymentIntentClientSecret
        formPlaceholderLabel1.textAlignment = .center
        formPlaceholderLabel1.textColor = .lightGray
        formPlaceholderLabel2.textAlignment = .center
        formPlaceholderLabel2.textColor = .lightGray
        view.addSubview(formPlaceholderLabel1)
        view.addSubview(formPlaceholderLabel2)
        
        // Set Auto Layout constraints for the form placeholder
        formPlaceholderLabel1.translatesAutoresizingMaskIntoConstraints = false
        formPlaceholderLabel2.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            formPlaceholderLabel1.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            formPlaceholderLabel1.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            formPlaceholderLabel2.topAnchor.constraint(equalTo: formPlaceholderLabel1.bottomAnchor, constant: 10),
            formPlaceholderLabel2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func backButtonTapped() {
        // Navigate back when the back button is tapped
        self.dismiss(animated: true, completion: nil)
    }
}
