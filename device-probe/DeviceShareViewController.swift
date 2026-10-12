import UIKit

final class DeviceShareViewController: ShareViewController {
  private var started = false
  private var record: ShareRecord?
  private let details = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    details.isEditable = false
    details.font = .preferredFont(forTextStyle: .body)
    details.text = "共有データを確認中…"
    let close = UIButton(type: .system)
    close.setTitle("閉じる", for: .normal)
    close.addTarget(self, action: #selector(closeRequest), for: .touchUpInside)
    stack.addArrangedSubview(close)
    stack.addArrangedSubview(details)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    guard !started else { return }
    started = true
    Task { @MainActor in
      var items: [ItemRecord] = []
      var providers: [ProviderRecord] = []
      for (itemIndex, input) in (extensionContext?.inputItems ?? []).enumerated() {
        guard let item = input as? NSExtensionItem else { continue }
        items.append(ItemRecord(
          itemIndex: itemIndex,
          title: item.attributedTitle?.string,
          contentText: item.attributedContentText?.string,
          userInfoKeys: (item.userInfo?.keys.map { String(describing: $0) } ?? []).sorted()
        ))
        for (attachmentIndex, provider) in (item.attachments ?? []).enumerated() {
          let text = await loadedValue(provider, identifier: "public.text")
          let url = await loadedValue(provider, identifier: "public.url")
          providers.append(ProviderRecord(
            itemIndex: itemIndex,
            attachmentIndex: attachmentIndex,
            identifiers: provider.registeredTypeIdentifiers,
            text: text,
            url: url
          ))
        }
      }
      let record = ShareRecord(receivedAt: Date(), hostToken: ProbeStore.hostToken(), items: items, providers: providers)
      self.record = record
      do {
        try ProbeStore.save(record)
        runSharedController(animated)
      } catch {
        let payload = (try? ProbeStore.encoded(record)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "不明"
        let profile = ProfileDiagnostics.describe(bundleURL: bundle.bundleURL, name: "実行中の共有拡張", requestedGroup: ProbeStore.groupIdentifier)
        let signature = SignatureDiagnostics.describe(bundleURL: bundle.bundleURL, name: "実行中の共有拡張", requestedGroup: ProbeStore.groupIdentifier)
        details.text = "App Groups：確認失敗\n\(error.localizedDescription)\n設定ID：\(ProbeStore.groupIdentifier)\n実行中：\(bundle.bundleIdentifier ?? "不明")（ビルド\(version)）\n\n\(profile)\n\n\(signature)\n\n受信データ：\n\(payload)"
      }
    }
  }

  override func openURL(_ url: URL) -> Bool {
    guard var record else { return false }
    record.composeURL = url.absoluteString
    record.composeText = URLComponents(url: url, resolvingAgainstBaseURL: false)?
      .queryItems?.first(where: { $0.name == "text" })?.value
    do {
      try ProbeStore.save(record)
      let dispatched = super.openURL(url)
      record.openDispatched = dispatched
      try ProbeStore.save(record)
      self.record = record
      return dispatched
    } catch {
      details.text = error.localizedDescription
      return false
    }
  }

  private func runSharedController(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  private func loadedValue(_ provider: NSItemProvider, identifier: String) async -> ProviderValue? {
    guard provider.hasItemConformingToTypeIdentifier(identifier) else { return nil }
    do {
      let value = try await provider.loadItem(forTypeIdentifier: identifier)
      let text: String?
      if let url = value as? URL {
        text = url.absoluteString
      } else if let string = value as? String {
        text = string
      } else if let data = value as? Data {
        text = String(data: data, encoding: .utf8)
      } else {
        text = nil
      }
      return ProviderValue(runtimeType: String(describing: type(of: value)), value: text, error: nil)
    } catch {
      return ProviderValue(runtimeType: "load failed", value: nil, error: error.localizedDescription)
    }
  }

  @objc private func closeRequest() {
    extensionContext?.completeRequest(returningItems: nil)
  }
}
