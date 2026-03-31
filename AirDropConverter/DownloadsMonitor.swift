//
//  DownloadsMonitor.swift
//  AirDropConverter
//
//  Created by Yuki Takatsu on 2026/04/01.
//

import Foundation
import AppKit
import UserNotifications

@Observable
final class DownloadsMonitor {
    var isEnabled = true {
        didSet {
            if isEnabled { startWatching() } else { stopWatching() }
        }
    }
    var outputFormat: OutputFormat = .png {
        didSet { UserDefaults.standard.set(outputFormat.rawValue, forKey: "outputFormat") }
    }
    var deleteOriginal = false {
        didSet { UserDefaults.standard.set(deleteOriginal, forKey: "deleteOriginal") }
    }
    var lastConvertedFile: String?
    var convertedCount = 0

    private var dispatchSource: (any DispatchSourceFileSystemObject)?
    private var knownFiles: Set<String> = []
    private var isProcessing = false
    private let downloadsURL: URL

    init() {
        downloadsURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads")

        if let saved = UserDefaults.standard.string(forKey: "outputFormat"),
           let format = OutputFormat(rawValue: saved) {
            outputFormat = format
        }
        deleteOriginal = UserDefaults.standard.bool(forKey: "deleteOriginal")

        knownFiles = scanDirectory()
        startWatching()
        requestNotificationPermission()
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(fileNames: [String]) {
        let content = UNMutableNotificationContent()
        content.sound = .default

        if fileNames.count == 1 {
            content.title = String(localized: "Conversion complete")
            content.body = String(localized: "Converted to \(fileNames[0])")
        } else {
            content.title = String(localized: "\(fileNames.count) files converted")
            content.body = fileNames.joined(separator: ", ")
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Directory Scanning

    private func scanDirectory() -> Set<String> {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: downloadsURL,
            includingPropertiesForKeys: nil
        ) else { return [] }
        return Set(contents.map(\.lastPathComponent))
    }

    // MARK: - File System Monitoring

    private func startWatching() {
        stopWatching()

        let fd = open(downloadsURL.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.checkForNewFiles()
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        dispatchSource = source
    }

    private func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    // MARK: - New File Detection

    private func checkForNewFiles() {
        guard isEnabled, !isProcessing else { return }

        let currentFiles = scanDirectory()
        let newFiles = currentFiles.subtracting(knownFiles)
        knownFiles = currentFiles

        let heicFiles = newFiles.filter { $0.lowercased().hasSuffix(".heic") }
        guard !heicFiles.isEmpty else { return }

        let airDropFiles = heicFiles.filter { name in
            isAirDropFile(at: downloadsURL.appendingPathComponent(name))
        }
        guard !airDropFiles.isEmpty else { return }

        promptAndConvert(files: airDropFiles.sorted())
    }

    // MARK: - AirDrop Detection

    private func isAirDropFile(at url: URL) -> Bool {
        let attrName = "com.apple.quarantine"
        let length = getxattr(url.path, attrName, nil, 0, 0, 0)
        guard length > 0 else { return false }

        var buffer = [UInt8](repeating: 0, count: length)
        let read = getxattr(url.path, attrName, &buffer, length, 0, 0)
        guard read > 0 else { return false }

        guard let value = String(bytes: buffer, encoding: .utf8) else { return false }
        let fields = value.split(separator: ";")
        return fields.count >= 3 && fields[2] == "sharingd"
    }

    // MARK: - Conversion Prompt

    private func promptAndConvert(files: [String]) {
        isProcessing = true
        defer { isProcessing = false }

        let format = outputFormat

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSImage(
            systemSymbolName: "photo.badge.arrow.down",
            accessibilityDescription: "HEIC conversion"
        )

        if files.count == 1 {
            alert.messageText = String(localized: "Received HEIC file via AirDrop")
            alert.informativeText = files[0] + "\n\n"
                + String(localized: "Convert to \(format.rawValue)?")
        } else {
            alert.messageText = String(localized: "Received \(files.count) HEIC files via AirDrop")
            alert.informativeText = files.joined(separator: "\n") + "\n\n"
                + String(localized: "Convert all to \(format.rawValue)?")
        }

        alert.addButton(withTitle: String(localized: "Convert to \(format.rawValue)"))
        alert.addButton(withTitle: String(localized: "Skip"))

        NSApp.activate(ignoringOtherApps: true)

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        var convertedNames: [String] = []

        for fileName in files {
            let sourceURL = downloadsURL.appendingPathComponent(fileName)
            let baseName = (fileName as NSString).deletingPathExtension
            let destURL = uniqueURL(
                for: downloadsURL.appendingPathComponent("\(baseName).\(format.fileExtension)")
            )

            if ImageConverter.convert(source: sourceURL, destination: destURL, format: format) {
                let destName = destURL.lastPathComponent
                lastConvertedFile = destName
                convertedCount += 1
                convertedNames.append(destName)
                knownFiles.insert(destName)

                if deleteOriginal {
                    try? FileManager.default.removeItem(at: sourceURL)
                }
            }
        }

        if !convertedNames.isEmpty {
            sendNotification(fileNames: convertedNames)
        }
    }

    // MARK: - Helpers

    private func uniqueURL(for url: URL) -> URL {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return url }

        let dir = url.deletingLastPathComponent()
        let baseName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension

        var counter = 2
        while true {
            let candidate = dir.appendingPathComponent("\(baseName) \(counter).\(ext)")
            if !fm.fileExists(atPath: candidate.path) { return candidate }
            counter += 1
        }
    }
}
