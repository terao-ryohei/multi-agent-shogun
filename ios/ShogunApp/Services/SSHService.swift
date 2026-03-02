import Foundation
import Citadel
import NIO

@MainActor
class SSHService: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var errorMessage: String? = nil
    private var client: SSHClient?

    // Stored for reconnect
    private var lastHost = ""
    private var lastPort = 22
    private var lastUsername = ""
    private var lastPassword = ""

    func connect(host: String, port: Int, username: String, password: String) async throws {
        lastHost = host
        lastPort = port
        lastUsername = username
        lastPassword = password

        do {
            client = try await SSHClient.connect(
                host: host,
                port: port,
                authenticationMethod: .passwordBased(username: username, password: password),
                hostKeyValidator: .acceptAnything(),
                reconnect: .never
            )
            isConnected = true
            errorMessage = nil
        } catch {
            isConnected = false
            errorMessage = "SSH接続失敗: \(error.localizedDescription)"
            throw error
        }
    }

    func exec(_ command: String) async throws -> String {
        guard let client else {
            throw SSHError.notConnected
        }
        let buffer = try await client.executeCommand(command)
        return String(buffer: buffer)
    }

    func disconnect() async {
        try? await client?.close()
        client = nil
        isConnected = false
    }

    func reconnect() async throws {
        await disconnect()
        try await connect(
            host: lastHost,
            port: lastPort,
            username: lastUsername,
            password: lastPassword
        )
    }
}

enum SSHError: LocalizedError {
    case notConnected

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "SSH未接続"
        }
    }
}
