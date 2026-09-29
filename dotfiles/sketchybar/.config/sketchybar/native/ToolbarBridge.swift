import AppKit
import CoreAudio
import EventKit

let cache = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches/AeroToolbar", isDirectory: true)
try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])

func json(_ value: Any) -> Data {
    (try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])) ?? Data("{}".utf8)
}
func output(_ value: Any) { print(String(data: json(value), encoding: .utf8)!) }
func address(_ selector: AudioObjectPropertySelector, _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
}
func number(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> UInt32 {
    var a = address(selector), value: UInt32 = 0, size = UInt32(MemoryLayout<UInt32>.size)
    _ = AudioObjectGetPropertyData(id, &a, 0, nil, &size, &value)
    return value
}
func deviceName(_ id: AudioObjectID) -> String {
    var a = address(kAudioObjectPropertyName), name: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    _ = AudioObjectGetPropertyData(id, &a, 0, nil, &size, &name)
    return name?.takeRetainedValue() as String? ?? "Audio output"
}
func outputs() -> [[String: Any]] {
    var a = address(kAudioHardwarePropertyDevices), size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size) == noErr else { return [] }
    var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size, &ids) == noErr else { return [] }
    let selected = number(AudioObjectID(kAudioObjectSystemObject), kAudioHardwarePropertyDefaultOutputDevice)
    return ids.compactMap { id in
        var streams = address(kAudioDevicePropertyStreams, kAudioDevicePropertyScopeOutput), bytes: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &streams, 0, nil, &bytes) == noErr, bytes > 0,
              number(id, kAudioDevicePropertyDeviceIsAlive) != 0 else { return nil }
        let types: [UInt32: String] = [kAudioDeviceTransportTypeBuiltIn: "Built-in",
            kAudioDeviceTransportTypeUSB: "USB", kAudioDeviceTransportTypeHDMI: "HDMI",
            kAudioDeviceTransportTypeDisplayPort: "DisplayPort", kAudioDeviceTransportTypeBluetooth: "Bluetooth",
            kAudioDeviceTransportTypeBluetoothLE: "Bluetooth", kAudioDeviceTransportTypeVirtual: "Virtual",
            kAudioDeviceTransportTypeAggregate: "Aggregate", kAudioDeviceTransportTypeAirPlay: "AirPlay"]
        let transport = types[number(id, kAudioDevicePropertyTransportType)] ?? "Output"
        return ["id": id, "name": deviceName(id), "connection": transport, "selected": id == selected]
    }.sorted { ($0["name"] as! String).localizedCaseInsensitiveCompare($1["name"] as! String) == .orderedAscending }
}
func setOutput(_ id: UInt32) {
    guard outputs().contains(where: { ($0["id"] as? UInt32) == id }) else { output(["ok": false]); exit(1) }
    var a = address(kAudioHardwarePropertyDefaultOutputDevice), value = id
    let status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, UInt32(MemoryLayout<UInt32>.size), &value)
    output(["ok": status == noErr]); if status != noErr { exit(1) }
}
func screens() -> [[String: Any]] {
    NSScreen.screens.enumerated().map { index, screen in
        let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
        return ["index": index + 1, "id": id, "width": screen.frame.width, "height": screen.frame.height,
                "builtin": CGDisplayIsBuiltin(id) != 0, "main": id == CGMainDisplayID(),
                "notch": screen.auxiliaryTopLeftArea != nil]
    }
}

let store = EKEventStore()
func meetingURL(_ event: EKEvent) -> String? {
    let text = [event.url?.absoluteString, event.location, event.notes].compactMap { $0 }.joined(separator: "\n")
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
    for result in detector.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
        guard let url = result.url, url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { continue }
        let domains = ["meet.google.com", "zoom.us", "teams.microsoft.com", "teams.live.com", "teams.cloud.microsoft", "webex.com", "whereby.com", "meet.jit.si", "huddles.slack.com"]
        if domains.contains(where: { host == $0 || host.hasSuffix("." + $0) }) { return url.absoluteString }
    }
    return nil
}
func calendarSnapshot() -> [String: Any] {
    let status = EKEventStore.authorizationStatus(for: .event)
    guard status == .fullAccess else {
        return ["status": status == .notDetermined ? "permission_needed" : "permission_denied", "updated": Date().timeIntervalSince1970, "events": []]
    }
    let calendars = store.calendars(for: .event)
    let now = Date()
    if calendars.isEmpty { return ["status": "no_calendars", "updated": now.timeIntervalSince1970, "events": []] }
    let predicate = store.predicateForEvents(withStart: now.addingTimeInterval(-300), end: now.addingTimeInterval(86400), calendars: calendars)
    let events: [[String: Any]] = store.events(matching: predicate).filter { event in
        !event.isAllDay && event.status != .canceled && event.endDate > now &&
        !(event.attendees ?? []).contains(where: { $0.isCurrentUser && $0.participantStatus == .declined })
    }.sorted { $0.startDate < $1.startDate }.prefix(40).map { event in
        var result: [String: Any] = ["start": event.startDate.timeIntervalSince1970,
                                    "end": event.endDate.timeIntervalSince1970,
                                    "title": event.title ?? "Meeting"]
        if let url = meetingURL(event) { result["url"] = url }
        return result
    }
    return ["status": calendars.isEmpty ? "no_calendars" : "ready", "updated": now.timeIntervalSince1970,
            "calendarCount": calendars.count,
            "hasGoogle": calendars.contains { $0.source.title.lowercased().contains("google") || $0.source.title.lowercased().contains("gmail") }, "events": events]
}
func refresh() {
    let path = cache.appendingPathComponent("calendar.json")
    try? json(calendarSnapshot()).write(to: path, options: .atomic)
    try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path.path)
}

switch CommandLine.arguments.dropFirst().first ?? "watch" {
case "audio-list": output(outputs())
case "audio-set":
    guard CommandLine.arguments.count == 3, let id = UInt32(CommandLine.arguments[2]) else { exit(1) }
    setOutput(id)
case "screens": output(screens())
case "calendar-status":
    let snapshot = calendarSnapshot()
    output(snapshot.filter { $0.key != "events" })
case "authorize":
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    store.requestFullAccessToEvents { granted, error in
        DispatchQueue.main.async { refresh(); app.terminate(nil) }
    }
    app.run()
case "watch":
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    refresh()
    _ = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in refresh() }
    NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { _ in refresh() }
    app.run()
default: exit(2)
}
