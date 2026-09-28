//
//  AirDropConverterApp.swift
//  AirDropConverter
//
//  Created by Yuki Takatsu on 2026/04/01.
//

import SwiftUI
import ServiceManagement

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppMover.moveToApplicationsIfNeeded()
    }
}

@main
struct AirDropConverterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var monitor = DownloadsMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor)
        } label: {
            Image("MenuBarSymbol")
                .renderingMode(.template)
                .opacity(monitor.isEnabled ? 1 : 0.45)
                .accessibilityLabel(monitor.isEnabled ? Text("Active") : Text("Paused"))
        }
    }
}

struct MenuBarView: View {
    @Bindable var monitor: DownloadsMonitor
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle(isOn: $monitor.isEnabled) {
            if monitor.isEnabled {
                Text("Active")
            } else {
                Text("Paused")
            }
        }

        if let message = monitor.statusMessage {
            Text(message)
        }
        if monitor.isProcessing {
            Text("Converting…")
        }
        Button("Convert HEIC Files…") { monitor.selectFiles() }
            .disabled(monitor.isProcessing)
        Button("Open Downloads") {
            NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads"))
        }

        Divider()

        Picker("Manual Output Format", selection: $monitor.outputFormat) {
            ForEach(OutputFormat.supported, id: \.self) { format in
                Text(format.rawValue).tag(format)
            }
        }

        Toggle("Delete HEIC after conversion", isOn: $monitor.deleteOriginal)

        Toggle("Launch at Login", isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { _, newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                    monitor.showError(error.localizedDescription)
                }
            }
            .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }

        Divider()

        if let last = monitor.lastConvertedFile {
            Text("Last: \(last)")
                .font(.caption)
        }

        if monitor.convertedCount > 0 {
            Text("Converted: \(monitor.convertedCount) files")
                .font(.caption)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
