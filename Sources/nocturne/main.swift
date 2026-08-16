import AppKit

// Entry point. One binary, two roles:
//   nocturne daemon                -> long-lived menu-bar app that owns the assertion
//   nocturne on|off|toggle|status  -> thin CLI client that messages the daemon

let helpText = """
nocturne \(nocturneVersion) — keep macOS awake, menu bar + CLI. No App Store, no account.

Usage:
  nocturne on [DURATION] [-i]   stay awake (2h / 90m / 45s / raw seconds; omit = indefinite)
                                -i / --no-display: keep the system awake but let the display sleep
  nocturne on --until HH:MM     stay awake until a clock time (e.g. --until 18:00)
  nocturne off                  stop, restore normal sleep
  nocturne toggle               flip on/off
  nocturne status               show whether it's on and time left
  nocturne version              print the version
  nocturne daemon               run the menu-bar daemon (managed by `brew services`)
"""

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write(Data((msg + "\n").utf8))
    exit(1)
}

// Seconds from now until the next occurrence of "HH:MM" (rolls to tomorrow if past).
func secondsUntil(_ clock: String) -> Int? {
    let parts = clock.split(separator: ":")
    guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]),
          (0..<24).contains(h), (0..<60).contains(m) else { return nil }
    let cal = Calendar.current
    let now = Date()
    var comps = cal.dateComponents([.year, .month, .day], from: now)
    comps.hour = h; comps.minute = m; comps.second = 0
    guard var target = cal.date(from: comps) else { return nil }
    if target <= now { target = cal.date(byAdding: .day, value: 1, to: target)! }
    return Int(target.timeIntervalSince(now))
}

// Spawn the daemon detached and wait (up to ~2s) for its socket to come up.
func ensureDaemon() {
    if Client.daemonIsRunning() { return }
    let p = Process()
    p.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
    p.arguments = ["daemon"]
    try? p.run()
    for _ in 0..<40 {
        usleep(50_000)
        if Client.daemonIsRunning() { return }
    }
}

func runDaemon() -> Never {
    if Client.daemonIsRunning() {
        print("nocturne: daemon already running")
        exit(0)
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory) // menu-bar only, no Dock icon
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
    exit(0)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let menu = MenuBar()
    let server = Server()
    private var signalSources: [DispatchSourceSignal] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu.install()
        server.start()
        // Release the assertion cleanly on `brew services stop` / Ctrl-C.
        for sig in [SIGTERM, SIGINT] {
            signal(sig, SIG_IGN)
            let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            src.setEventHandler { Core.shared.turnOff(); NSApp.terminate(nil) }
            src.resume()
            signalSources.append(src)
        }
    }
}

let args = Array(CommandLine.arguments.dropFirst())

switch args.first {
case "daemon":
    runDaemon()

case "on":
    var seconds: Int?
    var mode: SleepMode = .full
    var it = args.dropFirst().makeIterator()
    while let a = it.next() {
        switch a {
        case "-i", "--no-display":
            mode = .system
        case "--until":
            guard let v = it.next(), let s = secondsUntil(v) else { fail("nocturne: --until needs HH:MM") }
            seconds = s
        default:
            if let s = Duration.parse(a) { seconds = s }
            else { fail("nocturne: bad argument: \(a)") }
        }
    }
    ensureDaemon()
    guard let r = Client.send(Request(kind: .on, seconds: seconds, mode: mode)) else {
        fail("nocturne: daemon not reachable")
    }
    print("nocturne: \(r.message)")

case "off":
    if let r = Client.send(Request(kind: .off, seconds: nil, mode: nil)) {
        print("nocturne: \(r.message)")
    } else {
        print("nocturne: off")
    }

case "toggle":
    ensureDaemon()
    guard let r = Client.send(Request(kind: .toggle, seconds: nil, mode: nil)) else {
        fail("nocturne: daemon not reachable")
    }
    print("nocturne: \(r.message)")

case "status", nil:
    if let r = Client.send(Request(kind: .status, seconds: nil, mode: nil)) {
        print("nocturne: \(r.message)")
    } else {
        print("nocturne: off (daemon not running)")
    }

case "version", "--version", "-v":
    print("nocturne \(nocturneVersion)")

case "help", "-h", "--help":
    print(helpText)

default:
    fail("nocturne: unknown command: \(args.first ?? "")\n\n\(helpText)")
}
