import Foundation

// The daemon side: accept connections on a background thread, apply each
// request to Core on the main thread, reply with the resulting status.
final class Server {
    func start() {
        let path = Wire.socketPath
        unlink(path)

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { fatalError("nocturne: socket() failed") }

        let bound = UnixSocket.withAddress(path) { ptr, size in bind(fd, ptr, size) }
        guard bound == 0 else { fatalError("nocturne: bind() failed at \(path)") }
        listen(fd, 8)

        DispatchQueue.global(qos: .utility).async {
            while true {
                let cfd = accept(fd, nil, nil)
                if cfd < 0 { continue }
                self.handle(cfd)
                close(cfd)
            }
        }
    }

    private func handle(_ fd: Int32) {
        guard let req = Wire.decode(Request.self, from: UnixSocket.readFrame(fd)) else { return }
        var reply = StatusReply(active: false, mode: nil, remaining: nil, message: "error")
        DispatchQueue.main.sync {
            switch req.kind {
            case .on:     Core.shared.turnOn(seconds: req.seconds, mode: req.mode ?? .full)
            case .off:    Core.shared.turnOff()
            case .toggle: Core.shared.toggle()
            case .status: break
            }
            reply = Core.shared.status()
        }
        UnixSocket.writeFrame(fd, Wire.encode(reply))
    }
}
