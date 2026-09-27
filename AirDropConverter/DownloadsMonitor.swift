import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers
import UserNotifications

@MainActor
@Observable
final class DownloadsMonitor {
    var isEnabled = true {
        didSet {
            UserDefaults.standard.set(!isEnabled, forKey: "monitorPaused")
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
    var isProcessing = false
    var statusMessage: String?
    private var timer: Timer?
    private var tracker = FileArrivalTracker()
    private var hasBaseline = false
    private let downloadsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")

    init() {
        if let saved = UserDefaults.standard.string(forKey: "outputFormat"),
           let format = OutputFormat(rawValue: saved), OutputFormat.supported.contains(format) {
            outputFormat = format
        }
        deleteOriginal = UserDefaults.standard.bool(forKey: "deleteOriginal")
        isEnabled = !UserDefaults.standard.bool(forKey: "monitorPaused")
        if isEnabled { startWatching() }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scan() throws -> [URL: FileStamp] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: downloadsURL, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .fileResourceIdentifierKey],
            options: [.skipsHiddenFiles])
        var result: [URL: FileStamp] = [:]
        for url in urls where ["heic", "heif"].contains(url.pathExtension.lowercased()) {
            if let stamp = try? FileStamp.read(url) { result[url] = stamp }
        }
        return result
    }

    private func startWatching() {
        stopWatching()
        do { tracker.reset(to: try scan()); hasBaseline = true; statusMessage = nil }
        catch { statusMessage = String(localized: "Cannot read Downloads. Allow access in System Settings and retry.") }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkForNewFiles() }
        }
    }

    private func stopWatching() {
        timer?.invalidate()
        timer = nil
        tracker.reset(to: [:])
        hasBaseline = false
    }

    private func checkForNewFiles() {
        guard isEnabled else { return }
        let current: [URL: FileStamp]
        do { current = try scan(); statusMessage = nil }
        catch {
            statusMessage = String(localized: "Cannot read Downloads. Allow access in System Settings and retry.")
            return
        }
        guard hasBaseline else {
            tracker.reset(to: current)
            hasBaseline = true
            return
        }
        let candidates = tracker.update(current)
        var ready: [URL] = []
        for url in candidates {
            if tracker.pending[url, default: 0] > 60 && !AirDropMetadata.isAirDropFile(at: url) {
                tracker.handled(url)
                continue
            }
            guard !isProcessing, AirDropMetadata.isAirDropFile(at: url),
                  let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  CGImageSourceGetStatus(source) == .statusComplete else { continue }
            ready.append(url)
        }
        guard !ready.isEmpty else { return }
        for url in ready { tracker.handled(url) }
        promptAndConvert(files: ready.sorted { $0.lastPathComponent < $1.lastPathComponent })
    }


    func selectFiles() {
        guard !isProcessing else { return }
        isProcessing = true
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.heic, .heif]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { isProcessing = false; return }
        convert(files: panel.urls)
    }

    private func promptAndConvert(files: [URL]) {
        isProcessing = true
        let alert = NSAlert()
        alert.messageText = String(localized: "Received \(files.count) HEIC files via AirDrop")
        alert.informativeText = files.prefix(10).map(\.lastPathComponent).joined(separator: "\n")
            + "\n\n" + String(localized: "Convert all to \(outputFormat.rawValue)?")
        alert.addButton(withTitle: String(localized: "Convert to \(outputFormat.rawValue)"))
        alert.addButton(withTitle: String(localized: "Skip"))
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn { convert(files: files) }
        else { isProcessing = false }
    }

    private func convert(files: [URL]) {
        isProcessing = true
        let format = outputFormat
        let trashOriginal = deleteOriginal
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                var outputs: [URL] = []
                var errors: [String] = []
                for file in files {
                    autoreleasepool {
                        do {
                            let originalStamp = try FileStamp.read(file)
                            let output = try ImageConverter.convert(source: file, format: format)
                            outputs.append(output)
                            if trashOriginal {
                                do {
                                    guard try FileStamp.read(file) == originalStamp else {
                                        throw NSError(domain: "AirDropConverter", code: 3, userInfo: [
                                            NSLocalizedDescriptionKey: String(localized: "The original changed during conversion and was kept.")
                                        ])
                                    }
                                    try FileManager.default.trashItem(at: file, resultingItemURL: nil)
                                }
                                catch { errors.append(file.lastPathComponent + ": " + error.localizedDescription) }
                            }
                        } catch { errors.append(file.lastPathComponent + ": " + error.localizedDescription) }
                    }
                }
                return (outputs, errors)
            }.value
            convertedCount += result.0.count
            lastConvertedFile = result.0.last?.lastPathComponent ?? lastConvertedFile
            if !result.0.isEmpty {
                let content = UNMutableNotificationContent()
                content.title = String(localized: "Conversion complete")
                content.body = result.0.map(\.lastPathComponent).joined(separator: ", ")
                content.sound = .default
                try? await UNUserNotificationCenter.current().add(
                    UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
            }
            if !result.1.isEmpty { showError(result.1.joined(separator: "\n")) }
            isProcessing = false
        }
    }

    func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Some operations could not be completed")
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
