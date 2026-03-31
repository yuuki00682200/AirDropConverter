//
//  AppMover.swift
//  AirDropConverter
//
//  Created by Yuki Takatsu on 2026/04/01.
//

import AppKit

enum AppMover {
    static func moveToApplicationsIfNeeded() {
        let bundlePath = Bundle.main.bundlePath

        if bundlePath.hasPrefix("/Applications") { return }

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
            if fm.fileExists(atPath: destPath) {
                try fm.removeItem(atPath: destPath)
            }
            try fm.moveItem(atPath: bundlePath, toPath: destPath)

            // Relaunch from /Applications
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = [destPath]
            try process.run()

            NSApp.terminate(nil)
        } catch {
            let errorAlert = NSAlert()
            errorAlert.alertStyle = .warning
            errorAlert.messageText = String(localized: "Could not move to Applications")
            errorAlert.informativeText = String(localized: "Please move AirDropConverter.app to the Applications folder manually.")
            errorAlert.runModal()
        }
    }
}
