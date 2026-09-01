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
            /*
             * The collector carries the sdkAuthorization/environment that the
             * React surface reads via initialProps on mount. Re-assigning a
             * configuration with a different collector therefore has to
             * re-fire the mount, or the surface keeps the previous session's
             * credentials.
             */
            if mounted, oldValue?.collector !== configuration?.collector {
                remountSurface()
            }
        }
    }

    /*
     * A default intrinsic size so a bare `HyperswitchCardTextField()` /
     * storyboard-placed instance is never 0x0. Merchants that wrap the field
     * in their own constraints will override this — nil/UIView.noIntrinsicMetric
     * would let Auto Layout collapse the hosted React surface anyway.
     */
    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    public weak var delegate: VaultTextFieldDelegate?

    /// Mirrors VGS `textField.state`.
    public private(set) var state: VaultFieldState? {
        didSet { relayStateChange(oldState: oldValue) }
    }

    internal private(set) var rnRootTag: NSNumber?
    private var surface: UIView?
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

    internal var currentState: VaultFieldState? {
        state ?? rnRootTag.flatMap { VaultStateStore.shared.state(for: $0) }
    }

    // MARK: - Surface mounting

    /**
     * Initial-prop shape:
     *
     *     { type, config: { ...internal..., configuration: { appearance?, options? } } }
     *
     * Top level of `config` holds library-owned keys only (`fieldName`,
     * `isRequired`). No raw card data — no `value`, no `readOnly` — ever
     * enters the dictionary. The sensitive value lives only inside the RN
     * surface.
     *
     * Every merchant-set customization lives under `configuration.appearance`
     * and `configuration.options` — the same split the React Native vault's
     * public API uses.
     */
    private func initialProperties() -> [String: Any] {
        var config: [String: Any] = [
            "fieldName": mountedFieldName,
            "isRequired": configuration?.isRequired ?? true,
        ]

        // ── session (library-owned, set via configuration.collector) ──
        if let collector = configuration?.collector {
            config["sessionConfig"] = [
                "sdkAuthorization": collector.sdkAuthorization,
                "environment": collector.environment.jsName,
            ]
        }

        var configurationDict = [String: Any]()
        if let appearance = configuration?.appearance {
            configurationDict["appearance"] = appearance.dict
        }
        // The `placeholder` setter feeds into options; explicit `configuration.options` wins.
        var options = configuration?.options ?? VaultFieldOptions()
        if options.placeholder == nil, let appliedPlaceholder = appliedPlaceholder {
            options.placeholder = appliedPlaceholder
        }
        if !options.dict.isEmpty {
            configurationDict["options"] = options.dict
        }
        if !configurationDict.isEmpty {
            config["configuration"] = configurationDict
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
        if oldState?.isEmpty != state.isEmpty || oldState?.isValid != state.isValid {
            delegate?.vaultTextFieldDidChange(self)
        }
    }
}
