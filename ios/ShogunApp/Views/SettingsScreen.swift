import SwiftUI

struct SettingsScreen: View {
    @AppStorage("ssh_host") private var host = "192.168.1.1"
    @AppStorage("ssh_port") private var port = "22"
    @AppStorage("ssh_username") private var username = ""
    @AppStorage("ssh_password") private var password = ""
    @AppStorage("project_path") private var projectPath = ""
    @AppStorage("shogun_session") private var shogunSession = "shogun"
    @AppStorage("agents_session") private var agentsSession = "multiagent"

    @StateObject private var sshService = SSHService()
    @State private var testResult: String?
    @State private var showAlert = false
    @State private var isTesting = false

    var body: some View {
        Form {
            Section {
                TextField("SSHホスト", text: $host)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("SSHポート", text: $port)
                    .keyboardType(.numberPad)
                TextField("SSHユーザー", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("SSHパスワード", text: $password)
            } header: {
                Text("SSH設定")
                    .foregroundColor(.shogunGold)
            }

            Section {
                TextField("プロジェクトパス（サーバー側）", text: $projectPath)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("プロジェクト設定")
                    .foregroundColor(.shogunGold)
            }

            Section {
                TextField("将軍セッション名", text: $shogunSession)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("エージェントセッション名", text: $agentsSession)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("セッション設定")
                    .foregroundColor(.shogunGold)
            }

            Section {
                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Text("接続テスト")
                        if isTesting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isTesting || host.isEmpty || username.isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.shogunBlack)
        .navigationTitle("設定")
        .alert("接続テスト", isPresented: $showAlert) {
            Button("OK") {}
        } message: {
            Text(testResult ?? "")
        }
        .onChange(of: host)        { v in syncToAppGroup("ssh_host", v) }
        .onChange(of: port)        { v in syncToAppGroup("ssh_port", v) }
        .onChange(of: username)    { v in syncToAppGroup("ssh_username", v) }
        .onChange(of: password)    { v in syncToAppGroup("ssh_password", v) }
        .onChange(of: projectPath) { v in syncToAppGroup("project_path", v) }
        .onAppear {
            let suite = UserDefaults(suiteName: "group.com.shogun.app")
            suite?.set(host,        forKey: "ssh_host")
            suite?.set(port,        forKey: "ssh_port")
            suite?.set(username,    forKey: "ssh_username")
            suite?.set(password,    forKey: "ssh_password")
            suite?.set(projectPath, forKey: "project_path")
        }
    }

    private func syncToAppGroup(_ key: String, _ value: String) {
        UserDefaults(suiteName: "group.com.shogun.app")?.set(value, forKey: key)
    }

    private func testConnection() async {
        isTesting = true
        defer { isTesting = false }

        do {
            let portNum = Int(port) ?? 22
            try await sshService.connect(
                host: host,
                port: portNum,
                username: username,
                password: password
            )
            let hostname = try await sshService.exec("hostname")
            testResult = "接続成功: \(hostname.trimmingCharacters(in: .whitespacesAndNewlines))"
            await sshService.disconnect()
        } catch {
            testResult = "接続失敗: \(error.localizedDescription)"
        }
        showAlert = true
    }
}
