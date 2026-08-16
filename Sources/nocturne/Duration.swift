import Foundation

// Parsing and formatting of human durations: "2h" / "90m" / "45s" / raw seconds.
enum Duration {
    static func parse(_ s: String) -> Int? {
        guard let last = s.last else { return nil }
        let unit: Int
        let digits: Substring
        switch last {
        case "h", "H": unit = 3600; digits = s.dropLast()
        case "m", "M": unit = 60;   digits = s.dropLast()
        case "s", "S": unit = 1;    digits = s.dropLast()
        default:       unit = 1;    digits = Substring(s)
        }
        guard let n = Int(digits), n >= 0 else { return nil }
        return n * unit
    }

    static func human(_ seconds: Int) -> String {
        var s = max(0, seconds)
        let h = s / 3600; s %= 3600
        let m = s / 60;   s %= 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h)h") }
        if m > 0 { parts.append("\(m)m") }
        parts.append("\(s)s")
        return parts.joined(separator: " ")
    }
}
