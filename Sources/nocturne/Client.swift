import Foundation

// The CLI side: open the socket, send one request, read one reply.
enum Client {
    // Returns nil if no daemon is listening.
    static func send(_ req: Request) -> StatusReply? {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return nil }
        defer { close(fd) }

        let connected = UnixSocket.withAddress(Wire.socketPath) { ptr, size in
            connect(fd, ptr, size)
        }
        guard connected == 0 else { return nil }

        UnixSocket.writeFrame(fd, Wire.encode(req))
        return Wire.decode(StatusReply.self, from: UnixSocket.readFrame(fd))
    }

    static func daemonIsRunning() -> Bool {
        send(Request(kind: .status, seconds: nil, mode: nil)) != nil
    }
}
