import UIKit

/// Mirrors VGS `VGSTextFieldDelegate`.
public protocol VaultTextFieldDelegate: AnyObject {
    func vaultTextFieldDidBeginEditing(_ field: HyperswitchTextField?)
    func vaultTextFieldDidEndEditing(_ field: HyperswitchTextField?)
    func vaultTextFieldDidChange(_ field: HyperswitchTextField?)
}

public extension VaultTextFieldDelegate {
    func vaultTextFieldDidBeginEditing(_ field: HyperswitchTextField?) {}
    func vaultTextFieldDidEndEditing(_ field: HyperswitchTextField?) {}
    func vaultTextFieldDidChange(_ field: HyperswitchTextField?) {}
}

/**
 * HyperswitchTextField
 *
 * VGS `VGSTextField` equivalent. Unlike VGS (which keeps the sensitive input
 * in a native UITextField), the Hyperswitch Vault SDK renders the input as a
 * React Native surface of the shared runtime — this UIView hosts that surface.
 */
public class HyperswitchTextField: UIView {

    /// Initial-prop `type` of the `hs-vault` RN component.
    open var fieldType: String { "infoInput" }

    /// Default name the value is submitted under if no configuration set.
    open var defaultFieldName: String { "info" }

    public var placeholder: String? {
        didSet { appliedPlaceholder = placeholder ?? appliedPlaceholder }
    }

    /// Mirrors VGS `textField.configuration`.
    public var configuration: VaultConfiguration? {
        didSet {
            if let collector = configuration?.collector {
                collector.observeTextField(self)
            }
        }
    }

    public weak var delegate: VaultTextFieldDelegate?

    /// Mirrors VGS `textField.state`.
    public private(set) var state: VaultFieldState? {
        didSet { relayStateChange(oldState: oldValue) }
    }

    internal private(set) var rnRootTag: NSNumber?
    private var surface: UIView?
    private var alias: String?
    private var appliedPlaceholder: String?
    private var mounted = false
    private var localFieldName: String?
    private var mountedFieldName: String {
        configuration?.fieldName ?? localFieldName ?? defaultFieldName
    }

    /// VGS-style convenience setter reading straight from the configuration.
    public var fieldName: String? {
        set {
            if let config = configuration {
                config.fieldName = newValue ?? ""
            } else {
                localFieldName = newValue
            }
        }
        get { configuration?.fieldName ?? localFieldName }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { mountSurfaceIfNeeded() }
    }

    internal func setAlias(_ token: String) {
        alias = token
        remountSurface()
    }

    internal var currentState: VaultFieldState? {
        state ?? rnRootTag.flatMap { VaultStateStore.shared.state(for: $0) }
    }

    // MARK: - Surface mounting

    private func initialProperties() -> [String: Any] {
        var config: [String: Any] = [
            "fieldName": mountedFieldName,
            "isRequired": configuration?.isRequired ?? true,
        ]
        if let appliedPlaceholder = appliedPlaceholder {
            config["placeholder"] = appliedPlaceholder
        }
        if let appearance = configuration?.appearance {
            config["appearance"] = appearance.dict
        }
        if let alias = alias {
            config["value"] = alias
            config["readOnly"] = true
        }
        return ["type": fieldType, "config": config]
    }

    private func mountSurfaceIfNeeded() {
        guard !mounted else { return }
        mounted = true
        let view = VaultReactNativeController.shared.rootView(initialProperties: initialProperties())
        surface = view
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        resolveRootTag(of: view)
    }

    private func remountSurface() {
        guard mounted else { return }
        if let tag = rnRootTag { VaultStateStore.shared.remove(rootTag: tag) }
        surface?.removeFromSuperview()
        surface = nil
        rnRootTag = nil
        mounted = false
        mountSurfaceIfNeeded()
    }

    private func resolveRootTag(of view: UIView, attemptsLeft: Int = 60) {
        if let tag = view.surfaceRootTag {
            rnRootTag = tag
            subscribe(tag)
            return
        }
        guard attemptsLeft > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak view] in
            guard let self = self, let view = view else { return }
            self.resolveRootTag(of: view, attemptsLeft: attemptsLeft - 1)
        }
    }

    private func subscribe(_ tag: NSNumber) {
        VaultStateStore.shared.subscribe(rootTag: tag) { [weak self] newState in
            DispatchQueue.main.async { self?.state = newState }
        }
        /*
         * The JS vault package pushes redacted states keyed by field type
         * (one shared runtime may serve several field surfaces). fieldName
         * from the configuration is merged in — the JS side never sees it.
         */
        VaultStateStore.shared.subscribe(fieldType: defaultFieldName) { [weak self] newState in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if newState.fieldName == nil, let name = self.fieldName, !name.isEmpty {
                    self.state = newState.withFieldName(name)
                } else {
                    self.state = newState
                }
            }
        }
    }

    private func relayStateChange(oldState: VaultFieldState?) {
        guard let state else { return }
        if oldState?.isFocused != state.isFocused {
            if state.isFocused {
                delegate?.vaultTextFieldDidBeginEditing(self)
            } else {
                delegate?.vaultTextFieldDidEndEditing(self)
            }
        }
        if oldState?.text != state.text {
            delegate?.vaultTextFieldDidChange(self)
        }
    }
}
