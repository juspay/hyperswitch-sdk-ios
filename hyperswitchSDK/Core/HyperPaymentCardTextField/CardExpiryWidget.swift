//
//  CardExpiryWidget.swift
//  Hyperswitch
//
//  Created by Hyperswitch on 29/03/25.
//

import Foundation

/// A widget for collecting card expiry date in "MM / YY" format.
///
/// This widget provides a standalone input field for card expiry date with:
/// - Auto-formatting (e.g., "1225" → "12 / 25")
/// - Real-time validation (month 01-12, year not in past)
/// - Error handling with localized messages
///
/// ## Usage
/// ```swift
/// let expiryWidget = CardExpiryWidget(frame: CGRect(x: 0, y: 0, width: 200, height: 52))
/// expiryWidget.onExpiryValid = { isValid, expiryData in
///     print("Expiry valid: \(isValid)")
///     if let data = expiryData {
///         print("Month: \(data.expiryMonth), Year: \(data.expiryYear)")
///     }
/// }
/// ```
public class CardExpiryWidget: UIControl {
    
    /// Callback invoked when expiry validation state changes
    public var onExpiryValid: ((Bool, CardExpiryData?) -> Void)?
    
    /// The current expiry value in "MM / YY" format
    public var expiryValue: String {
        return rnViewManager?.expiryValue ?? ""
    }
    
    /// Whether the current expiry is valid
    public var isValid: Bool {
        return rnViewManager?.isExpiryValid ?? false
    }
    
    private var rnViewManager: RNViewManager?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        commonInit()
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: self.frame.width, height: 52.0)
    }
    
    private func commonInit() {
        let cardView = RNViewManager.sharedInstance.viewForModule(
            "hyperSwitch",
            initialProperties: ["props": ["type": "cardExpiry"]]
        )
        cardView.backgroundColor = UIColor.clear
        addSubview(cardView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        cardView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        cardView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        cardView.heightAnchor.constraint(equalToConstant: 52.0).isActive = true
        
        // Setup callback for expiry validation
        setupExpiryCallback()
    }
    
    private func setupExpiryCallback() {
        // Register for messages from React Native
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExpiryValidation(_:)),
            name: NSNotification.Name("CardExpiryValidation"),
            object: nil
        )
    }
    
    @objc private func handleExpiryValidation(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        let isValid = userInfo["isValid"] as? Bool ?? false
        let expiryMonth = userInfo["expiryMonth"] as? String
        let expiryYear = userInfo["expiryYear"] as? String
        let cardExpiry = userInfo["cardExpiry"] as? String
        
        let expiryData: CardExpiryData?
        if isValid, let month = expiryMonth, let year = expiryYear {
            expiryData = CardExpiryData(
                cardExpiry: cardExpiry ?? "",
                expiryMonth: month,
                expiryYear: year
            )
        } else {
            expiryData = nil
        }
        
        DispatchQueue.main.async {
            self.onExpiryValid?(isValid, expiryData)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

/// Data structure containing parsed expiry information
public struct CardExpiryData {
    /// The raw expiry string in "MM / YY" format
    public let cardExpiry: String
    
    /// The expiry month (01-12)
    public let expiryMonth: String
    
    /// The expiry year (4 digits, e.g., "2025")
    public let expiryYear: String
    
    /// Convenience property to get combined MM/YY without spaces
    public var formattedExpiry: String {
        return "\(expiryMonth)/\(String(expiryYear.suffix(2)))"
    }
}
