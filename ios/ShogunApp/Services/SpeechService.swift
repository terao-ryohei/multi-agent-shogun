import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechService: ObservableObject {
    @Published var isListening: Bool = false
    @Published var transcript: String = ""
    @Published var errorMessage: String? = nil

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startListening() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "音声認識が利用できません"
            return
        }

        // Stop any existing session
        stopListening()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        // Configure audio session for recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "オーディオセッション設定失敗: \(error.localizedDescription)"
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            errorMessage = "オーディオエンジン起動失敗: \(error.localizedDescription)"
            cleanupAudioTap()
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    self.transcript = result.bestTranscription.formattedString

                    if result.isFinal {
                        self.restartListeningIfActive()
                    }
                }

                if let error {
                    // Ignore cancellation errors from intentional stop
                    if (error as NSError).code == 216 || (error as NSError).code == 209 {
                        return
                    }
                    self.errorMessage = "認識エラー: \(error.localizedDescription)"
                    self.restartListeningIfActive()
                }
            }
        }

        isListening = true
        errorMessage = nil
    }

    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        cleanupAudioTap()
        isListening = false
    }

    private func cleanupAudioTap() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func restartListeningIfActive() {
        guard isListening else { return }
        cleanupAudioTap()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        // Brief delay before restart to avoid rapid cycling
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            guard self.isListening else { return }
            self.startListening()
        }
    }
}
