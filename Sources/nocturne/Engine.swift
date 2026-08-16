import Foundation
import IOKit.pwr_mgt

// How aggressively to stay awake.
enum SleepMode: String, Codable {
    case full     // keep the display on and the system awake
    case system   // keep the system awake, but let the display sleep

    var assertionType: String {
        switch self {
        case .full:   return kIOPMAssertionTypePreventUserIdleDisplaySleep
        case .system: return kIOPMAssertionTypePreventUserIdleSystemSleep
        }
    }
}

// A single IOKit power assertion, held for as long as the daemon wants us awake.
final class PowerAssertion {
    private var id: IOPMAssertionID = 0
    private(set) var held = false

    func hold(_ mode: SleepMode, reason: String) {
        release()
        var newID: IOPMAssertionID = 0
        let r = IOPMAssertionCreateWithName(
            mode.assertionType as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &newID)
        if r == kIOReturnSuccess { id = newID; held = true }
    }

    func release() {
        guard held else { return }
        IOPMAssertionRelease(id)
        held = false
        id = 0
    }
}
