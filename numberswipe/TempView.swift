

import SwiftUI
import MessageUI
import LinkPresentation

struct MessageComposeView: UIViewControllerRepresentable {
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView

        init(parent: MessageComposeView) {
            self.parent = parent
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = context.coordinator

        if MFMessageComposeViewController.canSendText() {
            // Example link metadata
            let metadata = LPLinkMetadata()
            metadata.title = "Example Title"
            metadata.originalURL = URL(string: "https://www.example.com")
            metadata.iconProvider = NSItemProvider(contentsOf: URL(string: "https://www.example.com/icon.png")!)
            
            // Convert metadata to a data attachment
            let linkPreviewData = try! NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
            
            // Attach metadata
            messageComposeVC.addAttachmentData(linkPreviewData, typeIdentifier: "com.apple.link-presentation", filename: "link.metadata")
        }

        return messageComposeVC
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        // No update needed for this use case
    }
}

struct TempView: View {
    @State private var showMessageCompose = false

        var body: some View {
            Button("Send Message") {
                showMessageCompose = true
            }
            .sheet(isPresented: $showMessageCompose) {
                MessageComposeView()
            }
        }
}

#Preview {
    TempView()
}
