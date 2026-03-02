import SwiftUI

// ━━ 戦国カラーパレット ━━
// Based on android/.interface-design/system.md

extension Color {
    // Primitives
    static let shogunBlack   = Color(hex: "1A1A1A")  // 漆黒 — lacquered armor base
    static let shogunSumi    = Color(hex: "2D2D2D")  // 墨   — ink stone, castle wall
    static let shogunGold    = Color(hex: "C9A94E")  // 金箔 — gold leaf on shrine
    static let shogunIvory   = Color(hex: "E8DCC8")  // 象牙 — washi paper, scroll
    static let shogunCrimson = Color(hex: "B33B24")  // 朱赤 — vermilion torii gate
    static let shogunGreen   = Color(hex: "3C6E47")  // 松葉 — pine garden (success)
    static let shogunAccent  = Color(hex: "C9A94E")  // アクセント金
    static let shogunSteel   = Color(hex: "3A4A5C")  // 鉄紺 — iron armor plate
    static let shogunRed     = Color(hex: "CC3333")  // 紅   — blood red (error)

    // Surface elevation
    static let surface0 = Color(hex: "1A1A1A")  // Screen background
    static let surface1 = Color(hex: "2D2D2D")  // Cards, pane tiles
    static let surface2 = Color(hex: "363636")  // Dropdowns, dialogs
    static let surface3 = Color(hex: "404040")  // Modals, fullscreen overlays
    static let surface4 = Color(hex: "1E1E1E")  // Input field (inset)

    // Text hierarchy
    static let textPrimary   = Color(hex: "C9A94E")  // Headings, agent names, tab labels
    static let textSecondary = Color(hex: "E8DCC8")  // Body text, terminal output
    static let textTertiary  = Color(hex: "8A9BB0")  // Metadata, timestamps
    static let textMuted     = Color(hex: "666666")  // Disabled, placeholders

    // Borders — Kinpaku at opacity levels
    static let borderStandard = Color(hex: "C9A94E").opacity(0.2)
    static let borderEmphasis = Color(hex: "C9A94E").opacity(0.4)
    static let borderFocus    = Color(hex: "C9A94E").opacity(0.6)

    // Status — Jinmaku bar
    static let statusConnected    = Color(hex: "3C6E47")
    static let statusDisconnected = Color(hex: "CC3333")
    static let statusReconnecting = Color(hex: "C9A94E")

    // Dashboard markdown
    static let linkGold = Color(hex: "D4B96A")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
