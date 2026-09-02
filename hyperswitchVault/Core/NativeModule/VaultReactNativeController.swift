//
//  VaultReactNativeController.swift
//  HyperswitchVault
//
//  Single shared React Native runtime used by every vault field surface.
//

import Foundation
import React
import React_RCTAppDelegate
#if canImport(ReactAppDependencyProvider)
import ReactAppDependencyProvider
#endif

internal class VaultReactDelegate: RCTDefaultReactNativeFactoryDelegate {

    internal weak var manager: VaultReactNativeController?

    /// The factory calls this whenever the runtime instantiates a TurboModule
    /// class; we hand it our own instance, pre-attached to the Impl singleton
    /// (twin of the main SDK's RNFactoryDelegate.getModuleInstanceFromClass:),
    /// giving native → JS emission a stable handle for the whole runtime life.
    @objc(getModuleInstanceFromClass:)
    internal func getModuleInstanceFromClass(_ moduleClass: AnyClass) -> AnyObject? {
        guard let manager = manager else { return nil }
        if let shimType = moduleClass as? (NSObject & HyperVaultModuleShim).Type {
            let shim = shimType.init()
            manager.hyperVaultModule.attach(to: shim)
            return shim
        }
        return nil
    }

    /// The vault JS bundle is compiled for the Fabric renderer and expects the
    /// bridgeless runtime (`nativeFabricUIManager` must exist). Always-on: the
    /// vault SDK runs on the host workspace's RN distribution (0.86 pods),
    /// the same way the main HyperswitchSDK does; `fabricEnabled` /
    /// `bridgelessEnabled` / `turboModuleEnabled` all forward to this.
    override func newArchEnabled() -> Bool {
        return true
    }

    /// The superclass raises on an unimplemented sourceURL — keep this as
    /// the single path.
    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    /// Debug loads the vault JS from Metro (`yarn start`) with main module
    /// "index" (index.js registers "hs-vault") — same flow as Android's
    /// debug builds. Release ships the prebuilt bundle resource packaged in
    /// the HyperswitchVault pod (see hyperswitch-vault-sdk-ios.podspec).
    override func bundleURL() -> URL? {
#if DEBUG
        return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
        return Bundle(for: VaultReactNativeController.self)
            .url(forResource: "hyperswitch-vault", withExtension: "bundle")
#endif
    }
}

internal final class VaultReactNativeController {

    static let shared = VaultReactNativeController()

    internal let moduleName = "hs-vault"

    /// The singleton Swift backing for the codegen HyperVaultModule TurboModule.
    /// Native → JS emission (onVaultTokenise) goes through its attached shim.
    internal let hyperVaultModule = HyperVaultModuleImpl()

    private let delegate: VaultReactDelegate

    internal lazy var factory: RCTReactNativeFactory = {
        RCTReactNativeFactory(delegate: delegate)
    }()

    private init() {
        delegate = VaultReactDelegate()
        delegate.manager = self
        /*
         * The vault is a standalone library consumed by arbitrary hosts —
         * the host workspace's generated RCTAppDependencyProvider enumerates
         * EVERY codegen component declared in that workspace (including
         * main-SDK pieces like ApplePayView), and its registry dictionary
         * crashes when a listed class was never linked into this binary.
         * VaultDependencyProvider registers only classes this host actually
         * provides.
         */
        #if canImport(ReactAppDependencyProvider)
        delegate.dependencyProvider = VaultDependencyProvider()
        #endif
    }

    /// Creates the surface (root view) of one vault field.
    internal func rootView(initialProperties: [String: Any]?) -> UIView {
        return factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
    }

    /// Broadcasts a typed tokenise request to the JS vault surfaces on this
    /// runtime; a mounted JS surface claims the event, runs the vault confirm,
    /// and answers through HyperVaultModule.returnTokenizedValue with the
    /// vaultSubmitResult JSON.
    ///
    /// Routed through the codegen HyperVaultModule's typed `onVaultTokenise`
    /// EventEmitter — the vault twin of the main SDK's
    /// HyperModule.triggerWidgetAction channel. The payload type lives in
    /// VaultTokeniseRequest (JS: src/specs/NativeHyperVaultModule.ts,
    /// Kotlin: VaultTokeniseRequest.kt).
    internal func emitTokenise(_ request: VaultTokeniseRequest) {
        hyperVaultModule.emitVaultTokenise(request)
    }
}

internal extension UIView {
    /// Root tag of the React surface hosted by this view, if any.
    var surfaceRootTag: NSNumber? {
        guard let rootView = self as? RCTSurfaceHostingProxyRootView else { return nil }
        return NSNumber(value: rootView.surface.rootTag)
    }
}
