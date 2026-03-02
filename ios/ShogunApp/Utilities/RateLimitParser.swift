import Foundation

enum RateLimitLevel {
    case green   // 0〜60%
    case yellow  // 61〜85%
    case red     // 86〜100%
}

struct RateLimitInfo {
    let percentage: Double    // 0.0〜1.0
    let label: String         // 表示テキスト e.g. "19.0% (5h)"
    let level: RateLimitLevel
}

struct RateLimitParser {
    /// ratelimit_check.sh の出力テキストをパースしてRateLimitInfoを返す
    /// 対象行例: "  5h window:  19.0% used  (resets 2026-03-02T02:59)"
    static func parse(_ output: String) -> RateLimitInfo? {
        guard !output.isEmpty else { return nil }

        // Pattern: "5h window:  {N.N}% used"
        let pattern = #"5h window:\s+(\d+\.?\d*)%\s+used"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: output,
                range: NSRange(output.startIndex..., in: output)
              ),
              let range = Range(match.range(at: 1), in: output)
        else { return nil }

        guard let raw = Double(output[range]) else { return nil }

        let percentage = (raw / 100.0).clamped(to: 0.0...1.0)
        let label = "\(String(format: "%.1f", raw))% (5h)"
        let level: RateLimitLevel
        switch raw {
        case ..<61:  level = .green
        case ..<86:  level = .yellow
        default:     level = .red
        }

        return RateLimitInfo(percentage: percentage, label: label, level: level)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
