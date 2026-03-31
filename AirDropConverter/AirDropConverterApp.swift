//
//  AirDropConverterApp.swift
//  AirDropConverter
//
//  Created by Yuki Takatsu on 2026/04/01.
//

import SwiftUI
import ServiceManagement

@main
struct AirDropConverterApp: App {
    @State private var monitor = DownloadsMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor)
        } label: {
            Image(systemName: monitor.isEnabled ? "arrow.down.circle.fill" : "arrow.down.circle")
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

        Divider()

        Picker("Output Format", selection: $monitor.outputFormat) {
            ForEach(OutputFormat.allCases, id: \.self) { format in
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
                }
            }

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
