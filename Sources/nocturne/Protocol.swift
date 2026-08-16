import Foundation

// Wire types shared by the CLI client and the daemon server.

struct Request: Codable {
    enum Kind: String, Codable { case on, off, status, toggle }
    var kind: Kind
    var seconds: Int?     // for .on — nil means indefinite
    var mode: SleepMode?  // for .on — defaults to .full
}

struct StatusReply: Codable {
    var active: Bool
    var mode: SleepMode?
    var remaining: Int?   // nil means indefinite (when active)
    var message: String
}

enum Wire {
    // Short path so it fits sockaddr_un.sun_path (104 bytes on macOS).
    static var socketPath: String { "\(NSHomeDirectory())/.nocturne.sock" }

    static func encode<T: Encodable>(_ value: T) -> Data {
        var d = try! JSONEncoder().encode(value)
        d.append(0x0A) // newline-terminated frame
        return d
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        try? JSONDecoder().decode(T.self, from: data)
    }
}
