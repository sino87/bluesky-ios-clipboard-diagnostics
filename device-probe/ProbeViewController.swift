import UIKit

final class ProbeViewController: UIViewController {
  private let groupStatus = UILabel()
  private let shareStatus = UILabel()
  private let signingDetails = UILabel()
  private let composedText = UITextView()
  private let providerDetails = UITextView()
  private let clipboardDetails = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "共有テスト"
    view.backgroundColor = .systemBackground

    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scroll)
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    scroll.addSubview(stack)
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)
    ])

    stack.addArrangedSubview(label("他のアプリの共有シートで「共有テスト」を選び、戻って結果を確認してください。これはBlueskyの投稿画面ではありません。"))
    groupStatus.numberOfLines = 0
    shareStatus.numberOfLines = 0
    stack.addArrangedSubview(groupStatus)
    stack.addArrangedSubview(button("結果を更新", action: #selector(refresh)))
    signingDetails.numberOfLines = 0
    signingDetails.font = .preferredFont(forTextStyle: .footnote)
    stack.addArrangedSubview(label("署名後のApp Groups許可（診断用）"))
    stack.addArrangedSubview(signingDetails)
    stack.addArrangedSubview(shareStatus)
    stack.addArrangedSubview(label("修正済み共有処理が作った本文"))
    configure(composedText, height: 150, editable: false)
    stack.addArrangedSubview(composedText)
    stack.addArrangedSubview(label("受信した共有データ・処理結果"))
    configure(providerDetails, height: 280, editable: false)
    stack.addArrangedSubview(providerDetails)

    stack.addArrangedSubview(label("通常ペーストの比較用：標準UITextView"))
    stack.addArrangedSubview(label("下の欄を長押ししてペーストしてください。React Nativeの投稿欄とは異なります。"))
    let pasteInput = UITextView()
    configure(pasteInput, height: 150, editable: true)
    stack.addArrangedSubview(pasteInput)
    stack.addArrangedSubview(button("クリップボードの構成を見る", action: #selector(inspectClipboard)))
    configure(clipboardDetails, height: 160, editable: false)
    stack.addArrangedSubview(clipboardDetails)
    refresh()
  }

  @objc func refresh() {
    guard isViewLoaded else { return }
    let extensionURL = Bundle.main.bundleURL.appendingPathComponent("PlugIns/ClipboardProbeShare.appex")
    signingDetails.text = [
      ProfileDiagnostics.describe(bundleURL: Bundle.main.bundleURL, name: "本体", requestedGroup: ProbeStore.groupIdentifier),
      ProfileDiagnostics.describe(bundleURL: extensionURL, name: "共有拡張", requestedGroup: ProbeStore.groupIdentifier)
    ].joined(separator: "\n\n")
    do {
      let token = try ProbeStore.prepareHost()
      groupStatus.text = "App Groups：本体から読み書き可能\n\(ProbeStore.groupIdentifier)"
      guard let record = try ProbeStore.load() else {
        shareStatus.text = "共有結果はまだありません。先にこの画面を開いた状態で、他のアプリから共有してください。"
        return
      }
      let exchange = record.hostToken == token ? "本体 → 拡張 → 本体の連携成功" : "拡張で本体の確認データを読めていません。もう一度共有してください。"
      shareStatus.text = "\(exchange)\n受信：\(record.receivedAt.formatted())\n\(record.composeURL == nil ? "composeリンク未取得" : "composeリンク取得済み")"
      composedText.text = record.composeText ?? "本文を取得していません。下の受信データを確認してください。"
      providerDetails.text = String(data: try ProbeStore.encoded(record), encoding: .utf8)
    } catch {
      groupStatus.text = "App Groups：確認失敗\n\(error.localizedDescription)\n設定ID：\(ProbeStore.groupIdentifier)"
    }
  }

  @objc private func inspectClipboard() {
    let board = UIPasteboard.general
    clipboardDetails.text = board.items.enumerated().map { index, item in
      "Item \(index + 1): \(item.keys.sorted().joined(separator: ", "))"
    }.joined(separator: "\n")
    if board.items.isEmpty { clipboardDetails.text = "クリップボードにアイテムがありません。" }
  }

  private func label(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    return label
  }

  private func button(_ text: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(text, for: .normal)
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  private func configure(_ textView: UITextView, height: CGFloat, editable: Bool) {
    textView.isEditable = editable
    textView.font = .preferredFont(forTextStyle: .body)
    textView.backgroundColor = .secondarySystemBackground
    textView.layer.cornerRadius = 8
    textView.heightAnchor.constraint(equalToConstant: height).isActive = true
  }
}
