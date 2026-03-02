import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var markdownContent: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let ssh = SSHService()

    func fetch() async {
        if !ssh.isConnected {
            await connect()
            guard ssh.isConnected else { return }
        }

        isLoading = true
        defer { isLoading = false }

        let projectPath = UserDefaults.standard.string(forKey: "project_path")
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? "/home/terao/private/multi-agent-shogun"

        do {
            markdownContent = try await ssh.exec("cat \(projectPath)/dashboard.md")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func connect() async {
        let host = UserDefaults.standard.string(forKey: "ssh_host") ?? ""
        let portStr = UserDefaults.standard.string(forKey: "ssh_port") ?? "22"
        let port = Int(portStr) ?? 22
        let username = UserDefaults.standard.string(forKey: "ssh_username") ?? ""
        let password = UserDefaults.standard.string(forKey: "ssh_password") ?? ""

        guard !host.isEmpty, !username.isEmpty else {
            errorMessage = "設定画面でSSH接続情報を設定してください"
            return
        }

        do {
            try await ssh.connect(host: host, port: port, username: username, password: password)
        } catch {
            errorMessage = "SSH接続失敗: \(error.localizedDescription)"
        }
    }
}
