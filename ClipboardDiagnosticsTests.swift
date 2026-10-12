import XCTest
import UIKit
import UniformTypeIdentifiers
@testable import ClipboardDiagnostics

final class ClipboardDiagnosticsTests: XCTestCase {
  private let title = "名探偵プリキュア！\n#TVer"
  private let link = URL(string: "https://tver.jp/episodes/epgiwg33av")!

  @MainActor
  func testNativeTextOnlyPaste() async {
    let text = await paste([[UTType.utf8PlainText.identifier: title]])
    XCTAssertEqual(text, title)
  }

  @MainActor
  func testNativeURLOnlyPaste() async {
    let text = await paste([[UTType.url.identifier: link]])
    XCTAssertTrue(text.contains(link.absoluteString), "URL-only paste: \(text.debugDescription)")
  }

  @MainActor
  func testNativeSeparateTextAndURLPaste() async {
    let text = await paste([
      [UTType.utf8PlainText.identifier: title],
      [UTType.url.identifier: link],
    ])
    XCTAssertTrue(text.contains(title), "Text was lost: \(text.debugDescription)")
    XCTAssertTrue(text.contains(link.absoluteString), "URL was lost: \(text.debugDescription)")
  }

  @MainActor
  func testNativeCombinedTextPasteControl() async {
    let combined = "\(title) \(link.absoluteString)"
    let text = await paste([[UTType.utf8PlainText.identifier: combined]])
    XCTAssertEqual(text, combined)
  }

  @MainActor
  func testShareTextOnly() async {
    let text = await share([extensionItem([textProvider(title)])])
    XCTAssertEqual(text, title)
  }

  @MainActor
  func testShareURLOnly() async {
    let text = await share([extensionItem([urlProvider(link)])])
    XCTAssertEqual(text, link.absoluteString)
  }

  @MainActor
  func testShareSeparateTextAndURLAttachments() async {
    let text = await share([extensionItem([textProvider(title), urlProvider(link)])])
    XCTAssertEqual(text, "\(title) \(link.absoluteString)")
  }

  @MainActor
  func testSharePlainTextAndURLWithContentMetadata() async {
    let caption = "A shared caption\nJoin code: EXAMPLE"
    let url = URL(string: "https://example.com/invite")!
    let plainText = NSItemProvider(item: caption as NSString, typeIdentifier: UTType.plainText.identifier)
    let item = extensionItem([plainText, urlProvider(url)])
    item.attributedContentText = NSAttributedString(string: caption)
    let text = await share([item])
    XCTAssertEqual(text, "\(caption) \(url.absoluteString)")
  }

  @MainActor
  func testShareSeparateExtensionItems() async {
    let text = await share([
      extensionItem([textProvider(title)]),
      extensionItem([urlProvider(link)]),
    ])
    XCTAssertEqual(text, "\(title) \(link.absoluteString)")
  }

  @MainActor
  func testShareDoesNotDuplicateURLAlreadyInText() async {
    let combined = "\(title) \(link.absoluteString)"
    let text = await share([extensionItem([textProvider(combined), urlProvider(link)])])
    XCTAssertEqual(text, combined)
  }

  @MainActor
  func testShareURLBeforeText() async {
    let text = await share([extensionItem([urlProvider(link), textProvider(title)])])
    XCTAssertEqual(text, "\(title) \(link.absoluteString)")
  }

  @MainActor
  func testShareDuplicateURLProviders() async {
    let text = await share([extensionItem([textProvider(title), urlProvider(link), urlProvider(link)])])
    XCTAssertEqual(text, "\(title) \(link.absoluteString)")
  }

  @MainActor
  func testShareURLPrefixIsNotADuplicate() async {
    let longerLink = "\(link.absoluteString)/details"
    let body = "\(title) \(longerLink)"
    let text = await share([extensionItem([textProvider(body), urlProvider(link)])])
    XCTAssertEqual(text, "\(body) \(link.absoluteString)")
  }

  @MainActor
  func testShareMultipleURLs() async {
    let secondLink = URL(string: "https://example.com/second")!
    let text = await share([extensionItem([urlProvider(link), urlProvider(secondLink)])])
    XCTAssertEqual(text, "\(link.absoluteString) \(secondLink.absoluteString)")
  }

  @MainActor
  func testShareTextDoesNotAppendMediaFileURL() async {
    let fileURL = URL(string: "file:///tmp/image.jpeg")!
    let text = await share([extensionItem([textProvider(title), urlProvider(fileURL)])])
    XCTAssertEqual(text, title)
  }

  @MainActor
  func testShareTextDoesNotLoadImageAttachment() async {
    let image = NSItemProvider(item: UIImage(), typeIdentifier: UTType.image.identifier)
    let text = await share([extensionItem([textProvider(title), urlProvider(link), image])])
    XCTAssertEqual(text, "\(title) \(link.absoluteString)")
  }

  @MainActor
  func testShareEmptyText() async {
    let text = await share([extensionItem([textProvider("")])])
    XCTAssertEqual(text, "")
  }

  @MainActor
  func testShareUnreadableTextDoesNotOpenComposer() async {
    let provider = NSItemProvider(item: NSNumber(value: 42), typeIdentifier: UTType.text.identifier)
    let text = await share([extensionItem([provider])])
    XCTAssertNil(text)
  }

  func testMediaURLClassification() {
    XCTAssertEqual(URL(string: "file:///tmp/image.jpeg")!.type, .image)
    XCTAssertEqual(URL(string: "file:///tmp/video.mp4")!.type, .movie)
    XCTAssertEqual(URL(string: "https://example.com/image.jpeg")!.type, .other)
  }

  @MainActor
  private func paste(_ items: [[String: Any]]) async -> String {
    let pasteboard = UIPasteboard.general
    let previousItems = pasteboard.items
    defer { pasteboard.items = previousItems }
    pasteboard.items = items
    print("[clipboard-diagnostics] types=\(pasteboard.items.map { Array($0.keys).sorted() })")
    print("[clipboard-diagnostics] strings=\(String(describing: pasteboard.strings)) urls=\(String(describing: pasteboard.urls))")
    if let data = pasteboard.data(forPasteboardType: UTType.url.identifier) {
      let propertyList = try? PropertyListSerialization.propertyList(from: data, format: nil)
      print("[clipboard-diagnostics] urlData=\(String(describing: String(data: data, encoding: .utf8))) urlPropertyList=\(String(describing: propertyList))")
    }

    let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
    let pasted = expectation(description: "Native text view changed after paste")
    pasted.assertForOverFulfill = false
    let delegate = CapturingTextViewDelegate()
    delegate.onChange = { pasted.fulfill() }
    textView.delegate = delegate
    let host = UIApplication.shared.delegate as! AppDelegate
    host.window!.rootViewController!.view.addSubview(textView)
    defer {
      textView.resignFirstResponder()
      textView.removeFromSuperview()
    }
    XCTAssertTrue(textView.becomeFirstResponder(), "Paste test must have a focused text view")
    textView.paste(nil)
    await fulfillment(of: [pasted], timeout: 10)
    print("[clipboard-diagnostics] inserted=\(textView.text.debugDescription)")
    return textView.text
  }

  @MainActor
  private func share(_ items: [NSExtensionItem]) async -> String? {
    let completed = expectation(description: "Share request completed")
    let context = CapturingExtensionContext()
    context.items = items
    context.onComplete = { completed.fulfill() }
    let controller = CapturingShareViewController(context: context)
    print("[clipboard-diagnostics] contextItems=\(controller.extensionContext?.inputItems.count ?? -1)")
    for provider in items.flatMap({ $0.attachments ?? [] }) {
      for identifier in ["public.text", "public.url"] where provider.hasItemConformingToTypeIdentifier(identifier) {
        do {
          let value = try await provider.loadItem(forTypeIdentifier: identifier)
          print("[clipboard-diagnostics] loaded \(identifier): type=\(type(of: value)) string=\(String(describing: value as? String)) url=\(String(describing: value as? URL))")
        } catch {
          print("[clipboard-diagnostics] loadFailed \(identifier): \(error)")
        }
      }
    }
    controller.viewDidAppear(false)
    await fulfillment(of: [completed], timeout: 5)
    print("[clipboard-diagnostics] providers=\(items.map { $0.attachments?.map(\.registeredTypeIdentifiers) ?? [] })")
    print("[clipboard-diagnostics] composeURL=\(String(describing: controller.composeURL))")
    guard let url = controller.composeURL else { return nil }
    return URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?.first(where: { $0.name == "text" })?.value
  }

  private func textProvider(_ value: String) -> NSItemProvider {
    NSItemProvider(item: value as NSString, typeIdentifier: UTType.utf8PlainText.identifier)
  }

  private func urlProvider(_ value: URL) -> NSItemProvider {
    NSItemProvider(item: value as NSURL, typeIdentifier: UTType.url.identifier)
  }

  private func extensionItem(_ providers: [NSItemProvider]) -> NSExtensionItem {
    let item = NSExtensionItem()
    item.attachments = providers
    return item
  }
}

@MainActor
private final class CapturingTextViewDelegate: NSObject, UITextViewDelegate {
  var onChange: (() -> Void)?

  func textViewDidChange(_ textView: UITextView) {
    onChange?()
  }
}

private final class CapturingExtensionContext: NSExtensionContext {
  var items: [NSExtensionItem] = []
  var onComplete: (() -> Void)?

  override var inputItems: [Any] { items }

  override func completeRequest(
    returningItems items: [Any]?,
    completionHandler: ((Bool) -> Void)? = nil
  ) {
    onComplete?()
    completionHandler?(false)
  }
}

@MainActor
private final class CapturingShareViewController: ShareViewController {
  let context: CapturingExtensionContext
  var composeURL: URL?

  init(context: CapturingExtensionContext) {
    self.context = context
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("Use init(context:)") }

  override var extensionContext: NSExtensionContext? { context }

  override func openURL(_ url: URL) -> Bool {
    composeURL = url
    return true
  }
}
