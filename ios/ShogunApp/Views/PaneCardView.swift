import SwiftUI

struct PaneCardView: View {
    let pane: PaneInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // ヘッダー: エージェント名 + アクティブドット
            HStack {
                Text(pane.agentId.isEmpty ? "pane\(pane.id)" : pane.agentId)
                    .font(.caption.bold())
                    .foregroundColor(Color.shogunGold)
                    .fontDesign(.monospaced)
                Spacer()
                Circle()
                    .fill(pane.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }

            // ボディ: ANSI解析済みコンテンツ（最新5行）
            Text(AnsiParser.parse(lastLines(pane.content, 5)))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color.shogunIvory)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // フッター: RateLimitView（足軽5号のコンポーネント）
            RateLimitView(info: RateLimitParser.parse(pane.rateLimitOutput))
        }
        .padding(8)
        .frame(height: 160)
        .background(Color.shogunBlack)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.shogunGold, lineWidth: 2))
    }

    private func lastLines(_ text: String, _ n: Int) -> String {
        text.components(separatedBy: "\n").suffix(n).joined(separator: "\n")
    }
}

#Preview {
    PaneCardView(pane: PaneInfo(
        id: 1,
        agentId: "ashigaru1",
        content: "line1\nline2\nline3\nline4\nline5 ❯",
        isActive: true,
        rateLimitOutput: ""
    ))
    .frame(width: 200)
    .padding()
    .background(Color.black)
}
