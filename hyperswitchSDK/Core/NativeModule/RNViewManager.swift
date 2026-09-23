//
//  RNViewManager.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

import Foundation
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate

internal protocol ReactHostManager: AnyObject {
    var hyperModule: HyperModuleImpl { get }
    var headlessModule: HyperHeadlessImpl { get }
    var responseHandler: RNResponseHandler? { get set }
    var rootView: UIView? { get }
}

/// A React host that can create a root whose JS calls resolve to a native [owner]. The
/// payments host and the payment methods host are separate realms with this in common.
internal protocol SurfaceHost: AnyObject {
    func viewForModule(_ moduleName: String, initialProperties: [String: Any]?, owner: AnyObject) -> UIView
}

/// Owner of a prefetch surface: receives the JS reply to an updateIntent round trip.
internal protocol UpdateIntentReplyTarget: AnyObject {
    func onUpdateIntentReply(type: String, result: String)
}

extension UIView {
    /// The surface object behind a root view from `viewForModule`, if it is one.
    internal var hostedSurface: (any RCTSurfaceProtocol)? {
        (self as? RCTSurfaceHostingProxyRootView)?.surface
    }

    internal var surfaceRootTag: NSNumber? {
        hostedSurface.map { NSNumber(value: $0.rootTag) }
    }
}

/// Every React surface is reconciled by its root tag. The presenter already maps a tag to
/// its surface object, so the native owner of a surface is stored on that object and
/// nothing is registered anywhere else. Owners are held weakly. Main thread.
internal enum SurfaceOwners {

    private final class WeakBox: NSObject {
        weak var owner: AnyObject?
        init(_ owner: AnyObject?) { self.owner = owner }
    }

    private static var key: UInt8 = 0

    internal static func attach(_ owner: AnyObject?, to surface: AnyObject) {
        objc_setAssociatedObject(surface, &key, WeakBox(owner), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    internal static func owner(of surface: AnyObject) -> AnyObject? {
        (objc_getAssociatedObject(surface, &key) as? WeakBox)?.owner
    }
}

/// A viewless surface (prefetch, saved payment methods) on the shared host: one React
/// root that never joins a window, plus the owner its replies route to. Main thread.
internal final class HeadlessSurface: NSObject, RCTSurfaceDelegate {

    /// Allocated when the surface is created, so valid before it has started.
    internal let rootTag: Int

    private let surface: (any RCTSurfaceProtocol)?
    /// The root view keeps the surface alive; releasing it would stop the surface.
    private let hostingView: UIView
    /// The hosting view was the surface's delegate; stage changes are forwarded to it.
    private weak var forwardTo: RCTSurfaceDelegate?
    /// Running, stopped, or never going to start: whatever awaits the start may proceed.
    private var started = false
    /// `stop()` came before React Native started the surface. RN starts it regardless once
    /// the bundle has run, so it is stopped the moment it does instead of running orphaned.
    private var stopRequested = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    /// Creates the root on [host]. React Native starts it once the bundle has run; the
    /// props are those it starts with, so pushes before then are not lost. A bundle that
    /// fails to load is a packaging defect: React Native ends the process (`RCTFatal`), as
    /// it does on Android, so no surface has to guard against it.
    internal init(host: SurfaceHost, moduleName: String, initialProperties: [String: Any], owner: AnyObject) {
        let view = host.viewForModule(moduleName, initialProperties: initialProperties, owner: owner)
        self.hostingView = view
        self.surface = view.hostedSurface
        self.rootTag = view.hostedSurface?.rootTag ?? -1
        super.init()
        if let surface = surface {
            forwardTo = surface.delegate
            surface.delegate = self
            started = RCTSurfaceStageIsRunning(surface.stage)
        } else {
            started = true
        }
    }

    /// Resolves once React is running this surface, which implies the bundle has run and
    /// the surface's requests are on their way. Resolves at once if the surface was stopped.
    internal func awaitStarted() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                if self.started {
                    continuation.resume()
                } else {
                    self.waiters.append(continuation)
                }
            }
        }
    }

    /// Re-renders the running root with new props; React updates in place.
    internal func updateProps(_ props: [String: Any]) {
        surface?.properties = props
    }

    internal func stop() {
        if let surface = surface {
            SurfaceOwners.attach(nil, to: surface)
            if RCTSurfaceStageIsRunning(surface.stage) {
                surface.stop()
            } else {
                stopRequested = true
            }
        }
        markStarted()
    }

    private func markStarted() {
        guard !started else { return }
        started = true
        let waiters = self.waiters
        self.waiters = []
        waiters.forEach { $0.resume() }
    }

    private func surfaceDidStart() {
        if stopRequested {
            stopRequested = false
            surface?.stop()
        }
        markStarted()
    }

    // MARK: RCTSurfaceDelegate (called off the main thread by React Native)

    func surface(_ surface: RCTSurface, didChange stage: RCTSurfaceStage) {
        forwardTo?.surface?(surface, didChange: stage)
        if RCTSurfaceStageIsRunning(stage) {
            DispatchQueue.main.async { self.surfaceDidStart() }
        }
    }

    func surface(_ surface: RCTSurface, didChangeIntrinsicSize intrinsicSize: CGSize) {
        forwardTo?.surface?(surface, didChangeIntrinsicSize: intrinsicSize)
    }
}

internal class RNFactoryDelegate: RCTDefaultReactNativeFactoryDelegate {

    internal weak var manager: ReactHostManager?

    @objc(getModuleInstanceFromClass:)
    internal func getModuleInstanceFromClass(_ moduleClass: AnyClass) -> AnyObject? {
        guard let manager = manager else { return nil }
        if let shimType = moduleClass as? (NSObject & HyperModuleShim).Type {
            let shim = shimType.init()
            manager.hyperModule.attach(to: shim)
            return shim
        }
        if let shimType = moduleClass as? (NSObject & HyperHeadlessShim).Type {
            let shim = shimType.init()
            manager.headlessModule.attach(to: shim)
            return shim
        }
        return nil
    }
}

internal class RNViewManagerDelegate: RNFactoryDelegate {

    override func sourceURL(for bridge: RCTBridge) -> URL? {
        return bundleURL()
    }

    override func bundleURL() -> URL? {
        switch Helper.getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        case "LocalBundle":
            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
        default:
            #if canImport(HyperOTA)
            return OTAServices.shared.getBundleURL()
            #else
            return Bundle(for: RNViewManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
            #endif
        }
    }
}

/// The one React host: one JS realm renders every surface of every session and widget.
/// Every surface is one React root on it, told apart by root tag.
internal final class RNViewManager: NSObject, ReactHostManager, SurfaceHost {

    /// Created on first use and kept for the life of the process.
    internal static let shared = RNViewManager()

    internal let hyperModule = HyperModuleImpl()
    internal let headlessModule = HyperHeadlessImpl()
    internal var responseHandler: RNResponseHandler?
    internal private(set) var rootView: UIView?

    private let delegate: RNViewManagerDelegate

    /// Evaluates the bundle's runtime chunk before the entry and tells the JS side where
    /// on-demand chunks live (see HyperReactNativeFactory.h).
    internal lazy var factory: RCTReactNativeFactory = {
        HyperReactNativeFactory(delegate: self.delegate, resourceDirectory: Self.resourceDirectory)
    }()

    /// Where the SDK's bundles and chunk files are packaged.
    private static let resourceDirectory = Bundle(for: RNViewManager.self).resourcePath

    /// Why this host cannot start: JavaScript it needs is missing from the app. Checked
    /// before React Native sees the bundle, whose fatal error for a missing one ends the
    /// app; the SDK reports SDK_INIT_FAILED instead. Main thread.
    internal lazy var initFailure: NSError? = {
        // The factory first: creating it sets React Native's feature flags, and resolving
        // the bundle URL reads them (RCTBundleURLProvider). Read before they are set, the
        // flags abort the app ("Feature flags were accessed before being overridden").
        _ = factory
        guard let missing = HyperReactNativeFactory.missingFiles(
            bundleURL: delegate.bundleURL(),
            resourceDirectory: Self.resourceDirectory
        ) else { return nil }
        return NSError.hyperswitch(
            "SDK_INIT_FAILED",
            "Hyperswitch SDK failed to initialise (payments): missing JavaScript: \(missing)"
        )
    }()


    private override init() {
        self.delegate = RNViewManagerDelegate()
        super.init()
        self.delegate.dependencyProvider = RCTAppDependencyProvider()
        self.delegate.manager = self
        self.hyperModule.host = self
    }

    /// Boots the host, and with it the bundle, ahead of the first surface so
    /// `initPaymentSession` does not wait for JS evaluation. Idempotent.
    internal func warmUp() {
        DispatchQueue.main.async {
            guard self.initFailure == nil else { return }
            self.factory.rootViewFactory.initializeReactHost(
                launchOptions: nil,
                bundleConfiguration: RCTBundleConfiguration.default(),
                devMenuConfiguration: RCTDevMenuConfiguration.default()
            )
        }
    }

    /// Creates one React root on the shared host. [owner] is the native object every JS call
    /// carrying this surface's root tag resolves to; it is attached at creation so no surface
    /// can exist without one.
    internal func viewForModule(_ moduleName: String, initialProperties: [String: Any]?, owner: AnyObject) -> UIView {
        // No React root when the host cannot start: an empty view, and callers that
        // report results check initFailure first.
        guard initFailure == nil else { return UIView() }
        let rootView = factory.rootViewFactory.view(
            withModuleName: moduleName,
            initialProperties: initialProperties
        )
        if let surface = rootView.hostedSurface {
            SurfaceOwners.attach(owner, to: surface)
        }
        return rootView
    }

    /// Single-root flows without a session (card field, payment method management,
    /// express checkout): the root created here is the one `exitSheet` dismisses.
    internal func presentedViewForModule(_ moduleName: String, initialProperties: [String: Any]?, owner: AnyObject) -> UIView {
        let rootView = viewForModule(moduleName, initialProperties: initialProperties, owner: owner)
        self.rootView = rootView
        return rootView
    }
}
