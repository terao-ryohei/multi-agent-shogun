import Foundation
import SwiftUI

@MainActor
class AgentsViewModel: ObservableObject {
    @Published var panes: [PaneInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var rateLimitResult: String? = nil
    @Published var rateLimitLoading: Bool = false

    private let ssh = SSHService()
    private var updateTimer: Timer?
    private var isPaused = false
    private var isRefreshing = false

    func startUpdating() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.fetchAllPanes() }
        }
        Task { await fetchAllPanes() }
    }

    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    func pauseRefresh() { isPaused = true }

    func resumeRefresh() {
        isPaused = false
        Task { await fetchAllPanes() }
    }

    func refreshAllPanes() {
        Task { await fetchAllPanes() }
    }

    private func fetchAllPanes() async {
        guard !isPaused, !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        // 8ペイン一括取得（バッチSSHコマンド）
        let batchCmd = buildBatchCommand()
        do {
            let output = try await ssh.exec(batchCmd)
            panes = parseBatchOutput(output)
            errorMessage = nil
        } catch {
            errorMessage = "取得失敗: \(error.localizedDescription)"
        }
    }

    private func buildBatchCommand() -> String {
        var cmd = ""
        for i in 0...7 {
            cmd += "echo '===ID\(i)===';"
            cmd += "/usr/bin/tmux display-message -t multiagent:0.\(i) -p '#{@agent_id}' 2>/dev/null || echo 'pane\(i)';"
            cmd += "echo '===CONTENT\(i)===';"
            cmd += "/usr/bin/tmux capture-pane -t multiagent:0.\(i) -p -S -20 2>/dev/null;"
            cmd += "echo '===RATELIMIT\(i)===';"
        }
        return cmd
    }

    private func parseBatchOutput(_ output: String) -> [PaneInfo] {
        var result: [PaneInfo] = []
        for i in 0...7 {
            let idMarker = "===ID\(i)==="
            let contentMarker = "===CONTENT\(i)==="
            let rateLimitMarker = "===RATELIMIT\(i)==="
            let nextIdMarker = "===ID\(i + 1)==="

            guard let idStart = output.range(of: idMarker),
                  let contentStart = output.range(of: contentMarker),
                  let rateLimitStart = output.range(of: rateLimitMarker) else {
                result.append(PaneInfo(id: i, agentId: "pane\(i)", content: "", isActive: false, rateLimitOutput: ""))
                continue
            }

            let agentId = String(output[idStart.upperBound..<contentStart.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let contentEnd: String.Index
            if i < 7, let next = output.range(of: nextIdMarker) {
                contentEnd = next.lowerBound
            } else {
                contentEnd = output.endIndex
            }
            let content = String(output[contentStart.upperBound..<rateLimitStart.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let rateLimitOutput = String(output[rateLimitStart.upperBound..<contentEnd])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let isActive = content.hasSuffix("❯") || content.hasSuffix(">")

            result.append(PaneInfo(
                id: i,
                agentId: agentId.isEmpty ? "pane\(i)" : agentId,
                content: content,
                isActive: isActive,
                rateLimitOutput: rateLimitOutput
            ))
        }
        return result
    }

    func sendCommandToPane(_ paneIndex: Int, command: String) {
        Task {
            let escaped = command.replacingOccurrences(of: "'", with: "'\\''")
            try? await ssh.exec("/usr/bin/tmux send-keys -t multiagent:0.\(paneIndex) '\(escaped)'")
            try? await Task.sleep(nanoseconds: 300_000_000)
            try? await ssh.exec("/usr/bin/tmux send-keys -t multiagent:0.\(paneIndex) Enter")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await fetchAllPanes()
        }
    }

    func execRateLimitCheck(projectPath: String) {
        guard !projectPath.isEmpty else {
            rateLimitResult = "設定画面でプロジェクトパスを設定してください"
            return
        }
        rateLimitLoading = true
        rateLimitResult = nil
        Task {
            do {
                let output = try await ssh.exec("bash \(projectPath)/scripts/ratelimit_check.sh")
                rateLimitResult = output
            } catch {
                rateLimitResult = "取得失敗: \(error.localizedDescription)"
            }
            rateLimitLoading = false
        }
    }

    func clearRateLimitResult() {
        rateLimitResult = nil
    }
}
