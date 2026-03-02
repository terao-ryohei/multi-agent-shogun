import SwiftUI

struct ShogunScreen: View {
    @StateObject private var viewModel = ShogunViewModel()
    @StateObject private var speechService = SpeechService()
    @StateObject private var audioService = AudioService()

    var body: some View {
        ZStack {
            Color.shogunBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // 陣幕バー
                HStack(spacing: 8) {
                    Image(systemName: "bolt.shield.fill")
                        .foregroundColor(Color.shogunBlack)
                    Text("⚔️ 将軍")
                        .font(.headline)
                        .foregroundColor(Color.shogunBlack)
                    Spacer()
                    // BGMボタン
                    Button(action: { audioService.toggle() }) {
                        Image(systemName: audioService.isPlaying ? "music.note" : "music.note.list")
                            .foregroundColor(Color.shogunBlack)
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
                            .foregroundColor(speechService.isListening ? .red : Color.shogunBlack)
                    }
                    Circle()
                        .fill(viewModel.ssh.isConnected ? Color.green : Color.shogunCrimson)
                        .frame(width: 10, height: 10)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(Color.shogunGold)

                // ターミナル表示エリア
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(viewModel.terminalContent)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .id("bottom")
                    }
                    .onChange(of: viewModel.terminalContent) { _ in
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .background(Color.shogunBlack)

                // 特殊キーバー
                SpecialKeysBar(viewModel: viewModel)

                // 入力欄
                HStack(spacing: 8) {
                    TextField("コマンド入力", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                    Button("送信") {
                        Task { await viewModel.sendText() }
                    }
                    .foregroundColor(Color.shogunBlack)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.shogunGold)
                    .cornerRadius(6)
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || !viewModel.ssh.isConnected)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.shogunBlack.opacity(0.9))
            }
        }
        .onChange(of: speechService.transcript) { text in
            viewModel.inputText = text
        }
        .onAppear {
            audioService.configureSession()
            Task { await speechService.requestPermission() }
            viewModel.startUpdating()
        }
        .onDisappear { viewModel.stopUpdating() }
    }
}
