import Foundation
import SwiftUI

struct AnsiParser {

    private static let ansiColorPattern = try! NSRegularExpression(
        pattern: "\u{001B}\\[([0-9;]*)m"
    )
    private static let ansiEscapePattern = try! NSRegularExpression(
        pattern: "\u{001B}(?:\\[[0-9;]*[A-Za-z]|[^\\[])"
    )

    // Standard 8-color palette (codes 30-37)
    private static let standardColors: [Color] = [
        Color(red: 0, green: 0, blue: 0),                         // 0 black
        Color(red: 0xCC/255.0, green: 0x44/255.0, blue: 0x44/255.0), // 1 red
        Color(red: 0x66/255.0, green: 0xBB/255.0, blue: 0x6A/255.0), // 2 green
        Color(red: 0xFF/255.0, green: 0xEB/255.0, blue: 0x3B/255.0), // 3 yellow
        Color(red: 0x42/255.0, green: 0xA5/255.0, blue: 0xF5/255.0), // 4 blue
        Color(red: 0xAB/255.0, green: 0x47/255.0, blue: 0xBC/255.0), // 5 magenta
        Color(red: 0x26/255.0, green: 0xC6/255.0, blue: 0xDA/255.0), // 6 cyan
        Color(red: 0xE0/255.0, green: 0xE0/255.0, blue: 0xE0/255.0), // 7 white
    ]

    // Bright 8-color palette (codes 90-97)
    private static let brightColors: [Color] = [
        Color(red: 0x75/255.0, green: 0x75/255.0, blue: 0x75/255.0), // 8  bright black (gray)
        Color(red: 0xFF/255.0, green: 0x52/255.0, blue: 0x52/255.0), // 9  bright red
        Color(red: 0x69/255.0, green: 0xF0/255.0, blue: 0xAE/255.0), // 10 bright green
        Color(red: 0xFF/255.0, green: 0xD7/255.0, blue: 0x40/255.0), // 11 bright yellow
        Color(red: 0x44/255.0, green: 0x8A/255.0, blue: 0xFF/255.0), // 12 bright blue
        Color(red: 0xE0/255.0, green: 0x40/255.0, blue: 0xFB/255.0), // 13 bright magenta
        Color(red: 0x18/255.0, green: 0xFF/255.0, blue: 0xFF/255.0), // 14 bright cyan
        .white,                                                        // 15 bright white
    ]

    /// Convert 256-color code (0-255) to SwiftUI Color
    private static func color256(_ n: Int) -> Color? {
        switch n {
        case 0...7:
            return standardColors[n]
        case 8...15:
            return brightColors[n - 8]
        case 16...231:
            let idx = n - 16
            let r = Double((idx / 36) * 51) / 255.0
            let g = Double(((idx % 36) / 6) * 51) / 255.0
            let b = Double((idx % 6) * 51) / 255.0
            return Color(red: r, green: g, blue: b)
        case 232...255:
            let gray = Double(8 + (n - 232) * 10) / 255.0
            return Color(red: gray, green: gray, blue: gray)
        default:
            return nil
        }
    }

    /// ANSI エスケープシーケンスをAttributedStringに変換
    static func parse(_ text: String) -> AttributedString {
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = ansiColorPattern.matches(in: text, range: fullRange)

        if matches.isEmpty {
            return AttributedString(stripAnsi(text))
        }

        var result = AttributedString()
        var currentColor: Color?
        var isBold = false
        var pos = 0

        func appendChunk(_ substring: String) {
            let clean = ansiEscapePattern.stringByReplacingMatches(
                in: substring,
                range: NSRange(location: 0, length: (substring as NSString).length),
                withTemplate: ""
            )
            guard !clean.isEmpty else { return }
            var attributed = AttributedString(clean)
            if let color = currentColor {
                attributed.foregroundColor = color
            }
            if isBold {
                attributed.font = .body.bold()
            }
            result.append(attributed)
        }

        for match in matches {
            let matchRange = match.range
            let beforeRange = NSRange(location: pos, length: matchRange.location - pos)
            if beforeRange.length > 0 {
                appendChunk(nsText.substring(with: beforeRange))
            }

            let codesStr = nsText.substring(with: match.range(at: 1))
            if codesStr.isEmpty {
                currentColor = nil
                isBold = false
            } else {
                let codes = codesStr.split(separator: ";").compactMap { Int($0) }
                var i = 0
                while i < codes.count {
                    switch codes[i] {
                    case 0:
                        currentColor = nil
                        isBold = false
                    case 1:
                        isBold = true
                    case 2, 22:
                        isBold = false
                    case 30...37:
                        currentColor = standardColors[codes[i] - 30]
                    case 39:
                        currentColor = nil
                    case 40...47, 49:
                        break // background, skip
                    case 90...97:
                        currentColor = brightColors[codes[i] - 90]
                    case 100...107:
                        break // bright background, skip
                    case 38:
                        if i + 1 < codes.count {
                            if codes[i + 1] == 5, i + 2 < codes.count {
                                currentColor = color256(codes[i + 2])
                                i += 2
                            } else if codes[i + 1] == 2, i + 4 < codes.count {
                                let r = Double(min(max(codes[i + 2], 0), 255)) / 255.0
                                let g = Double(min(max(codes[i + 3], 0), 255)) / 255.0
                                let b = Double(min(max(codes[i + 4], 0), 255)) / 255.0
                                currentColor = Color(red: r, green: g, blue: b)
                                i += 4
                            }
                        }
                    case 48:
                        if i + 1 < codes.count {
                            if codes[i + 1] == 5 { i += 2 }
                            else if codes[i + 1] == 2 { i += 4 }
                        }
                    default:
                        break
                    }
                    i += 1
                }
            }

            pos = matchRange.location + matchRange.length
        }

        if pos < nsText.length {
            appendChunk(nsText.substring(from: pos))
        }

        return result
    }

    /// ANSIコードを除去してプレーンテキストを返す（デバッグ用）
    static func stripAnsi(_ text: String) -> String {
        ansiEscapePattern.stringByReplacingMatches(
            in: text,
            range: NSRange(location: 0, length: (text as NSString).length),
            withTemplate: ""
        )
    }
}
