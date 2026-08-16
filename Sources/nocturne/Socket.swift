import Foundation

// Minimal Unix-domain-socket plumbing shared by client and server.
enum UnixSocket {
    // Fill a sockaddr_un for `path` and run `body` with a pointer to it.
    static func withAddress<R>(_ path: String, _ body: (UnsafePointer<sockaddr>, socklen_t) -> R) -> R {
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let capacity = MemoryLayout.size(ofValue: addr.sun_path) // 104 on macOS
        _ = path.withCString { src in
            withUnsafeMutablePointer(to: &addr.sun_path) {
                $0.withMemoryRebound(to: CChar.self, capacity: capacity) {
                    strcpy($0, src)
                }
            }
        }
        let size = socklen_t(MemoryLayout<sockaddr_un>.size)
        return withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { body($0, size) }
        }
    }

    // Read one newline-terminated frame from `fd`.
    static func readFrame(_ fd: Int32) -> Data {
        var buf = [UInt8]()
        var chunk = [UInt8](repeating: 0, count: 4096)
        while true {
            let n = read(fd, &chunk, chunk.count)
            if n <= 0 { break }
            buf.append(contentsOf: chunk[0..<n])
            if buf.last == 0x0A { break }
        }
        return Data(buf)
    }

    static func writeFrame(_ fd: Int32, _ data: Data) {
        data.withUnsafeBytes { _ = write(fd, $0.baseAddress, $0.count) }
    }
}
