import PayPal
import UIKit

class PaypalButtonView: UIView {

    private var payPalButton: PayPalButton?
    private var containerView: UIView?

    @objc dynamic var buttonColor: String = "gold" {
        didSet { updateButton() }
    }

    @objc dynamic var buttonLabel: String = "paypal" {
        didSet { updateButton() }
    }

    @objc dynamic var borderRadius: Double = 0 {
        didSet { updateButton() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    private func setupButton() {
        if let existingButton = payPalButton {
            existingButton.removeFromSuperview()
        }

        let color = mapColor(buttonColor)
        let label = mapLabel(buttonLabel)
        let edges = mapEdges(borderRadius)

        let button = PayPalButton(
            color: color,
            edges: edges,
            size: .collapsed,
            label: label
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        payPalButton = button

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])

        addSubview(container)
        containerView = container

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    private func updateButton() {
        setupButton()
        setNeedsLayout()
    }

    private func mapColor(_ value: String) -> PayPalButton.Color {
        switch value.lowercased() {
        case "blue": return .blue
        case "silver": return .silver
        case "white": return .white
        case "black": return .black
        default: return .gold
        }
    }

    private func mapLabel(_ value: String) -> PayPalButton.Label? {
        switch value.lowercased() {
        case "checkout": return .checkout
        case "buynow": return .buyNow
        case "pay": return .payWith
        default: return nil
        }
    }

    private func mapEdges(_ radius: Double) -> PaymentButtonEdges {
        if radius <= 0 {
            return .hardEdges
        } else {
            return .custom(CGFloat(radius))
        }
    }

    @objc private func buttonTapped() {
        guard let reactView = superview else { return }
        reactView.reactSubviews().first?.perform(#selector(UIView.didMoveToWindow))
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        payPalButton?.layoutSubviews()
    }
}
