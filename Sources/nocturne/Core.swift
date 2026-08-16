import AppKit

// The single source of truth for whether we're awake, shared by the menu bar
// and the socket server. All methods must run on the main thread.
final class Core {
    static let shared = Core()

    private let assertion = PowerAssertion()
    private var mode: SleepMode = .full
    private var deadline: Date?   // nil while active => indefinite
    private var active = false
    private var timer: Timer?

    // Called whenever state changes, so the menu bar can re-render.
    var onChange: (() -> Void)?

    func turnOn(seconds: Int?, mode: SleepMode) {
        self.mode = mode
        assertion.hold(mode, reason: "nocturne keep-awake")
        active = true
        timer?.invalidate(); timer = nil

        if let s = seconds, s > 0 {
            deadline = Date().addingTimeInterval(TimeInterval(s))
            timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(s), repeats: false) { [weak self] _ in
                self?.turnOff()
            }
        } else {
            deadline = nil
        }
        onChange?()
    }

    func toggle() {
        if active { turnOff() } else { turnOn(seconds: nil, mode: .full) }
    }

    func turnOff() {
        assertion.release()
        active = false
        deadline = nil
        timer?.invalidate(); timer = nil
        onChange?()
    }

    func status() -> StatusReply {
        guard active else {
            return StatusReply(active: false, mode: nil, remaining: nil, message: "off")
        }
        if let d = deadline {
            let left = max(0, Int(d.timeIntervalSinceNow))
            return StatusReply(active: true, mode: mode, remaining: left,
                               message: "on (\(mode.rawValue)) — \(Duration.human(left)) left")
        }
        return StatusReply(active: true, mode: mode, remaining: nil,
                           message: "on (\(mode.rawValue)) — indefinite")
    }
}
