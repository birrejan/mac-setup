// Reports which capture devices are live, for the sketchybar `capture` item.
//
// Prints "mic", "camera", "mic camera", or nothing at all. Both checks ask the
// same question -- kAudioDevicePropertyDeviceIsRunningSomewhere, which CoreAudio
// and CoreMediaIO both answer -- so this is the same signal that drives the
// orange/green dot in the macOS menu bar, not a guess based on running processes.
//
// Built on demand by plugins/capture.sh; the binary is not checked in.

import CoreAudio
import CoreMediaIO
import Foundation

func micIsLive() -> Bool {
    var devicesAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject), &devicesAddress, 0, nil, &size
    ) == noErr, size > 0 else { return false }

    var devices = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject), &devicesAddress, 0, nil, &size, &devices
    ) == noErr else { return false }

    for device in devices {
        // Skip output-only devices: playing music must not light this up.
        var inputStreams = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreams,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var streamsSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(device, &inputStreams, 0, nil, &streamsSize) == noErr,
              streamsSize > 0 else { continue }

        var running: UInt32 = 0
        var runningSize = UInt32(MemoryLayout<UInt32>.size)
        var runningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        if AudioObjectGetPropertyData(
            device, &runningAddress, 0, nil, &runningSize, &running
        ) == noErr, running != 0 {
            return true
        }
    }

    return false
}

func cameraIsLive() -> Bool {
    var devicesAddress = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    )

    var size: UInt32 = 0
    guard CMIOObjectGetPropertyDataSize(
        CMIOObjectID(kCMIOObjectSystemObject), &devicesAddress, 0, nil, &size
    ) == noErr, size > 0 else { return false }

    var devices = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
    var used: UInt32 = 0
    guard CMIOObjectGetPropertyData(
        CMIOObjectID(kCMIOObjectSystemObject), &devicesAddress, 0, nil, size, &used, &devices
    ) == noErr else { return false }

    for device in devices {
        var running: UInt32 = 0
        var runningUsed: UInt32 = 0
        var runningAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        if CMIOObjectGetPropertyData(
            device, &runningAddress, 0, nil, UInt32(MemoryLayout<UInt32>.size), &runningUsed, &running
        ) == noErr, running != 0 {
            return true
        }
    }

    return false
}

var live: [String] = []
if micIsLive() { live.append("mic") }
if cameraIsLive() { live.append("camera") }
print(live.joined(separator: " "))
