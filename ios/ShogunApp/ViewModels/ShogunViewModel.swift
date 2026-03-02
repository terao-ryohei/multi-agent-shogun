import SwiftUI

// MARK: - SpecialKey

enum SpecialKey: String {
    case enter, ctrlC, ctrlB
    case arrowUp, arrowDown, arrowLeft, arrowRight
    case tab, escape, ctrlO, ctrlD

    var tmuxKey: String {
        switch self {
        case .enter: return "Enter"
        case .ctrlC: return "C-c"
        case .ctrlB: return "C-b"
        case .arrowUp: return "Up"
        case .arrowDown: return "Down"
        case .arrowLeft: return "Left"
        case .arrowRight: return "Right"
        case .tab: return "Tab"
        case .escape: return "Escape"
        case .ctrlO: return "C-o"
        case .ctrlD: return "C-d"
        }
    }

    var label: String {
        switch self {
        case .enter: return "↩"
        case .ctrlC: return "C-c"
        case .ctrlB: return "C-b"
        case .arrowUp: return "↑"
        case .arrowDown: return "↓"
        case .arrowLeft: return "←"
        case .arrowRight: return "→"
        case .tab: return "Tab"
        case .escape: return "ESC"
        case .ctrlO: return "C-o"
        case .ctrlD: return "C-d"
        }
    }
}

// MARK: - ShogunViewModel

@MainActor
class ShogunViewModel: ObservableObject {
    @Published var terminalContent: AttributedString = AttributedString("")
    @Published var inputText: String = ""

    let ssh = SSHService()
    private var updateTimer: Timer?

    private let targetPane = "shogun:0.0"

    // MARK: Auto-refresh (3秒ごと tmux capture-pane)

    func startUpdating() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refreshTerminal()
            }
        }
    }

    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func refreshTerminal() async {
        guard let raw = try? await ssh.exec("tmux capture-pane -t \(targetPane) -p") else { return }
        terminalContent = AnsiParser.parse(raw)
    }

    // MARK: テキスト送信 (text → 300ms → Enter)

    func sendText() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let escaped = text.replacingOccurrences(of: "'", with: "'\\''")
        try? await ssh.exec("tmux send-keys -t \(targetPane) '\(escaped)'")
        try? await Task.sleep(nanoseconds: 300_000_000)
        try? await ssh.exec("tmux send-keys -t \(targetPane) Enter")
        inputText = ""
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        await refreshTerminal()
    }

    // MARK: 特殊キー送信

    func sendKey(_ key: SpecialKey) async {
        try? await ssh.exec("tmux send-keys -t \(targetPane) \(key.tmuxKey) Enter")
        try? await Task.sleep(nanoseconds: 500_000_000)
        await refreshTerminal()
    }
}
