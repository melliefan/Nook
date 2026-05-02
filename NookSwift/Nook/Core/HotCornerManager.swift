import AppKit
import CoreGraphics

@MainActor
final class HotCornerManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let triggerSize: CGFloat = 40
    private var isShowing = false
    private var showTimestamp: Date = .distantPast
    private let showGrace: TimeInterval = 0.8

    private var hideTimer: Timer?
    private let hideDelay: TimeInterval = 0.5

    private let store: Store
    private let onTrigger: (NSScreen) -> Void
    private let onExit: () -> Void
    private let onFrameRequest: () -> CGRect

    var isPinned = false

    init(store: Store,
         onTrigger: @escaping (NSScreen) -> Void,
         onExit: @escaping () -> Void,
         onFrameRequest: @escaping () -> CGRect) {
        self.store = store
        self.onTrigger = onTrigger
        self.onExit = onExit
        self.onFrameRequest = onFrameRequest
    }

    func start() {
        startFallbackPolling()
        let mask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue)

        let callback: CGEventTapCallBack = { _, _, event, refcon -> Unmanaged<CGEvent>? in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let mgr = Unmanaged<HotCornerManager>.fromOpaque(refcon).takeUnretainedValue()
            let loc = event.location
            DispatchQueue.main.async { mgr.handleMouse(cgPoint: loc) }
            return Unmanaged.passUnretained(event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: selfPtr
        ) else {
            print("[HotCorner] Cannot create event tap — grant Accessibility permission")
            return
        }

        eventTap = tap
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let src = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
        cancelHideTimer()
    }

    func setShowing(_ showing: Bool) {
        isShowing = showing
        if showing {
            showTimestamp = Date()
            cancelHideTimer()
        } else {
            cancelHideTimer()
        }
    }

    // MARK: - Hide timer

    private func startHideTimer() {
        guard hideTimer == nil else { return }
        hideTimer = Timer.scheduledTimer(withTimeInterval: hideDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isShowing, !self.isPinned else { return }
                self.hideTimer = nil
                self.onExit()
            }
        }
    }

    private func cancelHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    // MARK: - Mouse handling

    private func handleMouse(cgPoint: CGPoint) {
        let corner = store.settings.cornerTrigger

        if !isShowing {
            for screen in NSScreen.screens {
                if isInTriggerZone(cgPoint: cgPoint, corner: corner, screen: screen) {
                    onTrigger(screen)
                    return
                }
            }
        } else {
            if isPinned { cancelHideTimer(); return }
            if Date().timeIntervalSince(showTimestamp) < showGrace { return }

            let nsPoint = cgToNS(cgPoint)
            let panelFrame = onFrameRequest()
            let insideRect = panelFrame.insetBy(dx: -10, dy: -10)

            if insideRect.contains(nsPoint) {
                cancelHideTimer()
            } else {
                startHideTimer()
            }
        }
    }

    private func cgToNS(_ cgPoint: CGPoint) -> NSPoint {
        let mainH = NSScreen.screens.first?.frame.height ?? 1000
        return NSPoint(x: cgPoint.x, y: mainH - cgPoint.y)
    }

    private func isInTriggerZone(cgPoint: CGPoint, corner: NookSettings.CornerTrigger, screen: NSScreen) -> Bool {
        let frame = screen.frame
        let nsPoint = cgToNS(cgPoint)
        let ts = triggerSize
        switch corner {
        case .topLeft:
            return nsPoint.x >= frame.minX && nsPoint.x <= frame.minX + ts &&
                   nsPoint.y >= frame.maxY - ts && nsPoint.y <= frame.maxY
        case .topRight:
            return nsPoint.x >= frame.maxX - ts && nsPoint.x <= frame.maxX &&
                   nsPoint.y >= frame.maxY - ts && nsPoint.y <= frame.maxY
        case .bottomLeft:
            return nsPoint.x >= frame.minX && nsPoint.x <= frame.minX + ts &&
                   nsPoint.y >= frame.minY && nsPoint.y <= frame.minY + ts
        case .bottomRight:
            return nsPoint.x >= frame.maxX - ts && nsPoint.x <= frame.maxX &&
                   nsPoint.y >= frame.minY && nsPoint.y <= frame.minY + ts
        }
    }

    // MARK: - Fallback polling

    private var fallbackTimer: Timer?

    private func startFallbackPolling() {
        guard fallbackTimer == nil else { return }
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let loc = NSEvent.mouseLocation
            let mainH = NSScreen.screens.first?.frame.height ?? 1000
            let cgPt = CGPoint(x: loc.x, y: mainH - loc.y)
            Task { @MainActor in self.handleMouse(cgPoint: cgPt) }
        }
    }
}
