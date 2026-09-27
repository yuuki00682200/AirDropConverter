//
//  AppMover.swift
//  AirDropConverter
//
//  Created by Yuki Takatsu on 2026/04/01.
//

import AppKit

@MainActor
enum AppMover {
    static func moveToApplicationsIfNeeded() {
        #if !DEBUG
        let bundlePath = Bundle.main.bundlePath

        if bundlePath.hasPrefix("/Applications/") ||
            bundlePath.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path + "/") { return }

        let appName = Bundle.main.bundleURL.lastPathComponent
        let destPath = "/Applications/\(appName)"

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSImage(named: NSImage.applicationIconName)
        alert.messageText = String(localized: "Move to Applications?")
        alert.informativeText = String(localized: "AirDropConverter works best from the Applications folder. Move it now?")
        alert.addButton(withTitle: String(localized: "Move to Applications"))
        alert.addButton(withTitle: String(localized: "Later"))

        NSApp.activate(ignoringOtherApps: true)

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        do {
            let fm = FileManager.default
            guard !fm.fileExists(atPath: destPath) else {
                throw NSError(domain: "AirDropConverter", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: String(localized: "An app already exists in Applications. Replace it manually.")
                ])
            }
            try fm.copyItem(atPath: bundlePath, toPath: destPath)

            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: destPath),
                                              configuration: configuration) { _, error in
                Task { @MainActor in
                    if let error {
                        let alert = NSAlert()
                        alert.messageText = String(localized: "Could not move to Applications")
                        alert.informativeText = error.localizedDescription
                        alert.runModal()
                    } else {
                        NSApp.terminate(nil)
                    }
                }
            }
        } catch {
            let errorAlert = NSAlert()
            errorAlert.alertStyle = .warning
            errorAlert.messageText = String(localized: "Could not move to Applications")
            errorAlert.informativeText = error.localizedDescription + "\n\n" + String(localized: "Please move AirDropConverter.app to the Applications folder manually.")
            errorAlert.runModal()
        }
        #endif
    }
}
