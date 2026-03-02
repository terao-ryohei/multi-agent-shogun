import UIKit
import Social
import UniformTypeIdentifiers
import Citadel
import NIO

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Task { await handleShare() }
    }

    private func handleShare() async {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            do {
                let imageURL = try await itemProvider.loadItem(
                    forTypeIdentifier: UTType.image.identifier
                ) as! URL

                let defaults = UserDefaults(suiteName: "group.com.shogun.app")
                let host = defaults?.string(forKey: "ssh_host") ?? ""
                let port = defaults?.integer(forKey: "ssh_port") ?? 22
                let user = defaults?.string(forKey: "ssh_username") ?? ""
                let pass = defaults?.string(forKey: "ssh_password") ?? ""

                let client = try await SSHClient.connect(
                    host: host,
                    port: port,
                    authenticationMethod: .passwordBased(username: user, password: pass),
                    hostKeyValidator: .acceptAnything(),
                    reconnect: .never
                )

                let sftp = try await client.openSFTP()
                let imageData = try Data(contentsOf: imageURL)
                let remotePath = "/home/terao/private/shared/\(imageURL.lastPathComponent)"

                try await sftp.withFile(
                    filePath: remotePath,
                    flags: [.create, .write, .truncate]
                ) { file in
                    var buffer = ByteBuffer(data: imageData)
                    try await file.write(&buffer, at: 0)
                }

                try? await client.close()
                extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } catch {
                extensionContext?.cancelRequest(withError: error)
            }
        } else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
