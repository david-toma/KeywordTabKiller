import SafariServices
import os.log

/// Receives native messages from background.js and replies with the blocked-word list.
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let log = Logger(subsystem: "com.keywordblocker.app.extension", category: "native")

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey]
        log.debug("Received message: \(String(describing: message), privacy: .public)")

        let keywords = SharedStore.load()

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: ["keywords": keywords]]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
