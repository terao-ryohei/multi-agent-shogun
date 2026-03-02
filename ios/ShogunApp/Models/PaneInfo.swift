import Foundation

struct PaneInfo: Identifiable {
    let id: Int           // ペインインデックス 1-8
    let agentId: String   // e.g. "ashigaru1", "gunshi"
    let content: String   // ANSIを含むターミナル内容（直近20行）
    let isActive: Bool    // "❯" or ">" で終わるかどうか
    let rateLimitOutput: String  // ratelimit_check.sh の生出力
}
