import AppKit
import SwiftUI

final class NookPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    // Prevent flash on key window transition
    override func resignKey() {
        super.resignKey()
    }
    override func becomeKey() {
        super.becomeKey()
    }
}

@MainActor
final class PanelController: ObservableObject {
    private var panel: NookPanel?
    let store: Store
    @Published var isVisible = false
    @Published var isPinned = false
    @Published var currentScreen: NSScreen?
    private var cursorMonitor: Any?
    private var lastSetCursor: NSCursor?
    private var cursorEnforceTimer: Timer?
    private var enforcedCursor: NSCursor?

    // Drag-resize state (managed via NSEvent monitors, not NSView, so single clicks
    // pass through to SwiftUI buttons untouched)
    private var dragMonitorDown: Any?
    private var dragMonitorDragged: Any?
    private var dragMonitorUp: Any?
    private var pressedHandle: NookSettings.CornerTrigger?
    private var pressedAnchor: NookSettings.CornerTrigger?
    private var pressedOriginScreen: NSPoint?
    private var pressedStartFrame: NSRect?
    private var isResizing = false
    private let resizeStartThreshold: CGFloat = 3.0

    init(store: Store) {
        self.store = store
        setupPanel()
        installCursorMonitor()
        installDragMonitors()
    }

    deinit {
        for monitor in [cursorMonitor, dragMonitorDown, dragMonitorDragged, dragMonitorUp] {
            if let m = monitor { NSEvent.removeMonitor(m) }
        }
        cursorEnforceTimer?.invalidate()
    }

    /// Drag-to-resize, fully owned by PanelController via NSEvent monitors. Crucially,
    /// mouseDown is NEVER consumed — single clicks flow through to SwiftUI buttons normally.
    /// Only mouseDragged is consumed (and only after the user has moved past `resizeStartThreshold`),
    /// so accidental jitter on a button press doesn't trigger resize either.
    private func installDragMonitors() {
        dragMonitorDown = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.handleResizeMouseDown(event)
            return event   // never consume — buttons must keep working
        }
        dragMonitorDragged = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDragged) { [weak self] event in
            return self?.handleResizeMouseDragged(event) ?? event
        }
        dragMonitorUp = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            return self?.handleResizeMouseUp(event) ?? event
        }
    }

    private func handleResizeMouseDown(_ event: NSEvent) {
        guard let panel = panel, panel.isVisible else { return }
        let mouse = NSEvent.mouseLocation
        let f = panel.frame
        let lx = mouse.x - f.minX
        let ly = mouse.y - f.minY
        guard lx >= 0, lx <= f.width, ly >= 0, ly <= f.height else { return }

        let zone: CGFloat = 28
        var corner: NookSettings.CornerTrigger?
        if      lx < zone           && ly > f.height - zone { corner = .topLeft }
        else if lx > f.width - zone && ly > f.height - zone { corner = .topRight }
        else if lx < zone           && ly < zone            { corner = .bottomLeft }
        else if lx > f.width - zone && ly < zone            { corner = .bottomRight }

        let anchor = store.settings.cornerTrigger
        guard let handle = corner, handle != anchor else { return }

        pressedHandle = handle
        pressedAnchor = anchor
        pressedOriginScreen = mouse
        pressedStartFrame = f
        isResizing = false
    }

    private func handleResizeMouseDragged(_ event: NSEvent) -> NSEvent? {
        guard let origin = pressedOriginScreen,
              let handle = pressedHandle,
              let anchor = pressedAnchor,
              let startFrame = pressedStartFrame else {
            return event
        }
        let now = NSEvent.mouseLocation
        let dx = now.x - origin.x
        let dyAppKit = now.y - origin.y   // AppKit: positive = up

        if !isResizing {
            // Don't start resizing on mouse jitter — wait until we've moved at least
            // 3pt to be sure user intent was drag, not click.
            let distSq = dx * dx + dyAppKit * dyAppKit
            guard distSq > resizeStartThreshold * resizeStartThreshold else { return event }
            isResizing = true
        }

        let widthChange  = handle.isRight  != anchor.isRight
        let heightChange = handle.isBottom != anchor.isBottom
        let dwSign: CGFloat = handle.isRight ? 1 : -1
        let dhSign: CGFloat = handle.isBottom ? 1 : -1
        let dy = -dyAppKit   // top-down convention
        let dW = widthChange ? dwSign * dx : 0
        let dH = heightChange ? dhSign * dy : 0
        let newWidth = max(280, min(600, startFrame.width + dW))
        let visibleH = (currentScreen ?? NSScreen.main ?? NSScreen()).visibleFrame.height
        let newRatio = max(0.3, min(1.0, (startFrame.height + dH) / visibleH))
        updatePanelSize(width: newWidth, heightRatio: newRatio)
        return nil   // consume — we own this drag now
    }

    private func handleResizeMouseUp(_ event: NSEvent) -> NSEvent? {
        let wasResizing = isResizing
        pressedHandle = nil
        pressedAnchor = nil
        pressedOriginScreen = nil
        pressedStartFrame = nil
        isResizing = false
        return wasResizing ? nil : event
    }

    /// macOS keeps firing cursorUpdate events from underlying tracking areas (~60Hz),
    /// each potentially resetting our cursor. A single set() loses the race. Run a
    /// short-period timer that re-sets the cursor while we're in the corner zone,
    /// stop it the instant we leave. Cheap (just one set() call per tick).
    private func startEnforcing(_ cursor: NSCursor) {
        if enforcedCursor === cursor { return }
        enforcedCursor = cursor
        cursorEnforceTimer?.invalidate()
        let t = Timer(timeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let c = self?.enforcedCursor else { return }
            c.set()
        }
        RunLoop.main.add(t, forMode: .common)
        cursorEnforceTimer = t
        cursor.set()
    }

    private func stopEnforcing() {
        guard cursorEnforceTimer != nil else { return }
        cursorEnforceTimer?.invalidate()
        cursorEnforceTimer = nil
        enforcedCursor = nil
        NSCursor.arrow.set()
    }

    /// nonactivatingPanel + becomesKeyOnlyIfNeeded means the panel rarely becomes key,
    /// so tracking-area cursorUpdate and addCursorRect don't fire reliably. Watch
    /// mouseMoved at the app level and `set()` the cursor manually based on position.
    private func installCursorMonitor() {
        // Local monitor fires BEFORE the event is dispatched to views, so any cursor
        // we set immediately gets overridden by downstream tracking-area cursorUpdate.
        // Dispatch async so our `set()` runs AFTER the event has been handled by the
        // view hierarchy — that way we win the race.
        cursorMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged]
        ) { [weak self] event in
            DispatchQueue.main.async { self?.updateCursorForMousePosition() }
            return event
        }
    }

    private func updateCursorForMousePosition() {
        guard let panel = panel, panel.isVisible else {
            stopEnforcing()
            return
        }
        let mouse = NSEvent.mouseLocation
        let f = panel.frame
        let lx = mouse.x - f.minX
        let ly = mouse.y - f.minY
        guard lx >= 0, lx <= f.width, ly >= 0, ly <= f.height else {
            stopEnforcing()
            return
        }

        let zone: CGFloat = 28
        let isLeft   = lx < zone
        let isRight  = lx > f.width - zone
        let isBottom = ly < zone
        let isTop    = ly > f.height - zone

        var corner: NookSettings.CornerTrigger?
        if      isLeft  && isTop    { corner = .topLeft }
        else if isRight && isTop    { corner = .topRight }
        else if isLeft  && isBottom { corner = .bottomLeft }
        else if isRight && isBottom { corner = .bottomRight }

        let anchor = store.settings.cornerTrigger
        guard let handle = corner, handle != anchor else {
            stopEnforcing()
            return
        }

        let widthChange  = handle.isRight  != anchor.isRight
        let heightChange = handle.isBottom != anchor.isBottom
        let cursor: NSCursor
        if widthChange && heightChange {
            let isNESW = handle.isRight != handle.isBottom
            cursor = isNESW ? .nookDiagonalNESW : .nookDiagonalNWSE
        } else if widthChange {
            cursor = .resizeLeftRight
        } else {
            cursor = .resizeUpDown
        }
        startEnforcing(cursor)
    }

    private func setupPanel() {
        let p = NookPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 600),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        p.isFloatingPanel = true
        p.level = .statusBar
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        p.hidesOnDeactivate = false
        p.animationBehavior = .none
        p.isMovableByWindowBackground = false
        p.becomesKeyOnlyIfNeeded = true
        p.acceptsMouseMovedEvents = true

        let rootView = PanelView(store: store, panelController: self)
        let hosting = NSHostingView(rootView: rootView)
        // No layer-level mask: SwiftUI's clipShape handles the rounded look.
        // Masking here would shrink AppKit hit-testing and steal corner drag events.
        p.contentView = hosting

        self.panel = p
    }

    func show(on screen: NSScreen) {
        guard !isVisible else { return }
        currentScreen = screen
        let frame = computeFrame(for: screen)
        panel?.setFrame(frame, display: true)
        panel?.orderFront(nil)
        panel?.makeKey()

        isVisible = true
        animateIn()
    }

    func hide() {
        guard isVisible, !isPinned else { return }
        isVisible = false
        animateOut()
    }

    func toggle() {
        if isVisible {
            isPinned = false
            hide()
        } else {
            let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
            show(on: screen)
        }
    }

    func togglePin() {
        isPinned.toggle()
    }

    var panelFrame: CGRect {
        panel?.frame ?? .zero
    }

    func computeFrame(for screen: NSScreen) -> NSRect {
        let corner = store.settings.cornerTrigger
        let visibleFrame = screen.visibleFrame
        let w = max(280, min(600, store.settings.panelWidth))
        let ratio = max(0.2, min(1.0, store.settings.panelHeightRatio))
        let h = max(300, visibleFrame.height * ratio)

        let x: CGFloat
        let y: CGFloat

        switch corner {
        case .topLeft:
            x = visibleFrame.minX
            y = visibleFrame.maxY - h
        case .topRight:
            x = visibleFrame.maxX - w
            y = visibleFrame.maxY - h
        case .bottomLeft:
            x = visibleFrame.minX
            y = visibleFrame.minY
        case .bottomRight:
            x = visibleFrame.maxX - w
            y = visibleFrame.minY
        }
        return NSRect(x: x, y: y, width: w, height: h)
    }

    func updatePanelSize(width: CGFloat? = nil, heightRatio: CGFloat? = nil) {
        guard let screen = currentScreen ?? NSScreen.main else { return }
        if let w = width { store.settings.panelWidth = Double(w) }
        if let r = heightRatio { store.settings.panelHeightRatio = Double(r) }
        store.updatePanelSize(
            heightRatio: store.settings.panelHeightRatio,
            width: store.settings.panelWidth
        )
        let frame = computeFrame(for: screen)
        panel?.setFrame(frame, display: true)
    }

    private func animateIn() {
        guard let panel else { return }
        let finalFrame = panel.frame
        let corner = store.settings.cornerTrigger
        var startFrame = finalFrame
        if corner.isRight {
            startFrame.origin.x += finalFrame.width
        } else {
            startFrame.origin.x -= finalFrame.width
        }
        panel.setFrame(startFrame, display: false)
        panel.alphaValue = 0.3

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(finalFrame, display: true)
            panel.animator().alphaValue = 1.0
        }
    }

    private func animateOut() {
        guard let panel else { return }
        let startFrame = panel.frame
        let corner = store.settings.cornerTrigger
        var endFrame = startFrame
        if corner.isRight {
            endFrame.origin.x += startFrame.width
        } else {
            endFrame.origin.x -= startFrame.width
        }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(endFrame, display: true)
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            panel.alphaValue = 1.0
            if let self, let screen = self.currentScreen {
                let frame = self.computeFrame(for: screen)
                panel.setFrame(frame, display: false)
            }
        })
    }
}
