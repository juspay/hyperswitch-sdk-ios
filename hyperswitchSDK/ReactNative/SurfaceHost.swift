//
//  SurfaceHost.swift
//  HyperswitchReactNative
//
//  Created by Harshit Srivastava on 26/09/26.
//

import Foundation
package import React
import UIKit

/// A React host that can create a root whose JS calls resolve to a native [owner]. The
/// payments, payment methods and payment method management hosts are separate realms with
/// this in common.
package protocol SurfaceHost: AnyObject {
    func viewForModule(_ moduleName: String, initialProperties: [String: Any]?, owner: AnyObject) -> UIView
}

extension UIView {
    /// The surface object behind a root view from `viewForModule`, if it is one.
    package var hostedSurface: (any RCTSurfaceProtocol)? {
        (self as? RCTSurfaceHostingProxyRootView)?.surface
    }

    package var surfaceRootTag: NSNumber? {
        hostedSurface.map { NSNumber(value: $0.rootTag) }
    }
}

/// Every React surface is reconciled by its root tag. The presenter already maps a tag to
/// its surface object, so the native owner of a surface is stored on that object and
/// nothing is registered anywhere else. Owners are held weakly. Main thread.
package enum SurfaceOwners {

    private final class WeakBox: NSObject {
        weak var owner: AnyObject?
        init(_ owner: AnyObject?) { self.owner = owner }
    }

    private static var key: UInt8 = 0

    package static func attach(_ owner: AnyObject?, to surface: AnyObject) {
        objc_setAssociatedObject(surface, &key, WeakBox(owner), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    package static func owner(of surface: AnyObject) -> AnyObject? {
        (objc_getAssociatedObject(surface, &key) as? WeakBox)?.owner
    }
}

/// A viewless surface (prefetch, saved payment methods) on the shared host: one React
/// root that never joins a window, plus the owner its replies route to. Main thread.
package final class HeadlessSurface: NSObject, RCTSurfaceDelegate {

    /// Allocated when the surface is created, so valid before it has started.
    package let rootTag: Int

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
    package init(host: SurfaceHost, moduleName: String, initialProperties: [String: Any], owner: AnyObject) {
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
    package func awaitStarted() async {
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
    package func updateProps(_ props: [String: Any]) {
        surface?.properties = props
    }

    package func stop() {
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

    package func surface(_ surface: RCTSurface, didChange stage: RCTSurfaceStage) {
        forwardTo?.surface?(surface, didChange: stage)
        if RCTSurfaceStageIsRunning(stage) {
            DispatchQueue.main.async { self.surfaceDidStart() }
        }
    }

    package func surface(_ surface: RCTSurface, didChangeIntrinsicSize intrinsicSize: CGSize) {
        forwardTo?.surface?(surface, didChangeIntrinsicSize: intrinsicSize)
    }
}
