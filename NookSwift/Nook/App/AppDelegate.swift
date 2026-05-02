import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: Store!
    private var panelController: PanelController!
    private var hotCornerManager: HotCornerManager!
    private var globalKeyMonitor: Any?
    private var pinCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        switch UserDefaults.standard.string(forKey: "nook_appearance") ?? "system" {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":  NSApp.appearance = NSAppearance(named: .darkAqua)
        default:      NSApp.appearance = nil
        }

        UserDefaults.standard.set("", forKey: "nook_filterTag")

        store = Store()
        panelController = PanelController(store: store)
        panelController.isPinned = true

        hotCornerManager = HotCornerManager(
            store: store,
            onTrigger: { [weak self] screen in
                guard let self else { return }
                self.panelController.show(on: screen)
                self.hotCornerManager.setShowing(true)
            },
            onExit: { [weak self] in
                guard let self else { return }
                self.panelController.hide()
                self.hotCornerManager.setShowing(false)
            },
            onFrameRequest: { [weak self] in
                self?.panelController.panelFrame ?? .zero
            }
        )
        hotCornerManager.start()

        pinCancellable = panelController.$isPinned.sink { [weak self] pinned in
            self?.hotCornerManager.isPinned = pinned
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 17 {
                Task { @MainActor in
                    guard let self else { return }
                    self.panelController.toggle()
                    self.hotCornerManager.setShowing(self.panelController.isVisible)
                }
            }
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            showPanelFromCurrentScreen()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotCornerManager?.stop()
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Task { @MainActor in
            showPanelFromCurrentScreen()
        }
        return false
    }

    @MainActor
    private func showPanelFromCurrentScreen() {
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        panelController.show(on: screen)
        hotCornerManager.setShowing(panelController.isVisible)
    }
}
