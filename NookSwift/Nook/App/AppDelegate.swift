import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    var store: Store!
    var panelController: PanelController!
    var hotCornerManager: HotCornerManager!
    @MainActor lazy var remindersSync = RemindersSync()
    private var pinCancellable: AnyCancellable?
    private var tasksCancellable: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)

        switch UserDefaults.standard.string(forKey: "nook_appearance") ?? "light" {
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

        // Reminders sync — observe store.$tasks, debounce 500ms, full sync.
        // RemindersSync internally checks isEnabled & isAuthorized; harmless if off.
        remindersSync.refreshAuthorizationStatus()
        tasksCancellable = store.$tasks
            .dropFirst()   // ignore the initial published value at app launch
            .sink { [weak self] _ in
                guard let self else { return }
                self.remindersSync.scheduleSync(allTasks: self.store.tasks)
            }

        // No keyboard shortcut — hot corner is the sole trigger.

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            showPanelFromCurrentScreen()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotCornerManager?.stop()
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
