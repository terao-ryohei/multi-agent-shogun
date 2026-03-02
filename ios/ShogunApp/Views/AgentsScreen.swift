import SwiftUI

struct AgentsScreen: View {
    @StateObject private var viewModel = AgentsViewModel()
    @State private var selectedPaneId: Int? = nil
    @State private var showRateLimitDialog = false

    // UserDefaultsからプロジェクトパスを取得
    private var projectPath: String {
        UserDefaults.standard.string(forKey: "project_path") ?? ""
    }

    // 選択中のペインをlive dataから取得（自動更新）
    private var selectedPane: PaneInfo? {
        guard let id = selectedPaneId else { return nil }
        return viewModel.panes.first { $0.id == id }
    }

    var body: some View {
        Group {
            if let pane = selectedPane {
                PaneFullScreenView(
                    pane: pane,
                    onBack: { selectedPaneId = nil },
                    onSendCommand: { viewModel.sendCommandToPane(pane.id, command: $0) },
                    onRefresh: { viewModel.refreshAllPanes() }
                )
            } else {
                gridView
            }
        }
        .onAppear { viewModel.startUpdating() }
        .onDisappear { viewModel.stopUpdating() }
    }

    private var gridView: some View {
        NavigationStack {
            ZStack {
                Color.shogunBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let error = viewModel.errorMessage {
                        Text("エラー: \(error)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 8
                        ) {
                            ForEach(viewModel.panes) { pane in
                                PaneCardView(pane: pane)
                                    .onTapGesture { selectedPaneId = pane.id }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                }

                // レートリミット確認ボタン（右下）
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showRateLimitDialog = true
                            viewModel.execRateLimitCheck(projectPath: projectPath)
                        } label: {
                            Image(systemName: "speedometer")
                                .font(.system(size: 24))
                                .foregroundColor(Color.shogunGold)
                                .frame(width: 48, height: 48)
                                .background(Color(white: 0.18))
                                .clipShape(Circle())
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("⚔️ エージェント一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showRateLimitDialog, onDismiss: { viewModel.clearRateLimitResult() }) {
            RateLimitDialogView(
                isLoading: viewModel.rateLimitLoading,
                rawText: viewModel.rateLimitResult ?? "",
                onClose: {
                    showRateLimitDialog = false
                    viewModel.clearRateLimitResult()
                }
            )
        }
    }
}

// ── ペイン全画面表示 ──────────────────────────────────────────────────────────

struct PaneFullScreenView: View {
    let pane: PaneInfo
    let onBack: () -> Void
    let onSendCommand: (String) -> Void
    let onRefresh: () -> Void

    @StateObject private var speechService = SpeechService()
    @StateObject private var audioService = AudioService()
    @State private var commandText = ""
    private let lines: [String]

    init(pane: PaneInfo, onBack: @escaping () -> Void, onSendCommand: @escaping (String) -> Void, onRefresh: @escaping () -> Void) {
        self.pane = pane
        self.onBack = onBack
        self.onSendCommand = onSendCommand
        self.onRefresh = onRefresh
        self.lines = pane.content.components(separatedBy: "\n")
    }

    var body: some View {
        ZStack {
            Color.shogunBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // トップバー
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.shogunGold)
                    }
                    Text(pane.agentId.isEmpty ? "pane\(pane.id)" : pane.agentId)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color.shogunGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    // BGMボタン
                    Button(action: { audioService.toggle() }) {
                        Image(systemName: audioService.isPlaying ? "music.note" : "music.note.list")
                            .foregroundColor(Color.shogunGold)
                    }
                    // マイクボタン
                    Button(action: {
                        if speechService.isListening {
                            speechService.stopListening()
                            audioService.unduck()
                        } else {
                            speechService.startListening()
                            audioService.duck()
                        }
                    }) {
                        Image(systemName: speechService.isListening ? "mic.fill" : "mic")
                            .foregroundColor(speechService.isListening ? .red : Color.shogunGold)
                    }
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color.shogunGold)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(white: 0.18))

                // ターミナル内容
                ScrollViewReader { proxy in
                    ScrollView([.horizontal, .vertical]) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                                Text(AnsiParser.parse(line))
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(Color.shogunIvory)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .onAppear {
                        proxy.scrollTo("bottom")
                    }
                    .onChange(of: lines.count) { _ in
                        proxy.scrollTo("bottom")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 特殊キーバー
                SpecialKeysRow(onSendKey: onSendCommand)

                // コマンド入力欄
                HStack(spacing: 4) {
                    TextField("コマンドを入力", text: $commandText)
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        guard !commandText.isEmpty else { return }
                        onSendCommand(commandText)
                        commandText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(commandText.isEmpty ? Color.gray : Color.shogunGold)
                    }
                    .disabled(commandText.isEmpty)
                }
                .padding(8)
                .background(Color(white: 0.12))
            }
        }
        .onChange(of: speechService.transcript) { text in
            commandText = text
        }
        .onAppear {
            audioService.configureSession()
            Task { await speechService.requestPermission() }
        }
    }
}

// ── 特殊キーバー ──────────────────────────────────────────────────────────────

struct SpecialKeysRow: View {
    let onSendKey: (String) -> Void

    private let keys: [(label: String, value: String)] = [
        ("Tab", "\t"),
        ("Ctrl+C", "\u{03}"),
        ("Ctrl+D", "\u{04}"),
        ("Esc", "\u{1B}"),
        ("↑", "\u{1B}[A"),
        ("↓", "\u{1B}[B"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(keys, id: \.label) { key in
                    Button(key.label) {
                        onSendKey(key.value)
                    }
                    .font(.caption.bold())
                    .foregroundColor(Color.shogunGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.22))
                    .cornerRadius(4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(white: 0.15))
    }
}

// ── レートリミットダイアログ ──────────────────────────────────────────────────

struct RateLimitDialogView: View {
    let isLoading: Bool
    let rawText: String
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.18).ignoresSafeArea()
                if isLoading {
                    ProgressView()
                        .tint(Color.shogunGold)
                } else {
                    ScrollView {
                        Text(rawText.isEmpty ? "データなし" : rawText)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.shogunIvory)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .navigationTitle("Claude レートリミット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる", action: onClose)
                        .foregroundColor(Color.shogunGold)
                }
            }
        }
    }
}

#Preview {
    AgentsScreen()
}
