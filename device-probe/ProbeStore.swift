import Foundation

struct ProviderValue: Codable {
  let runtimeType: String
  let value: String?
  let error: String?
}

struct ProviderRecord: Codable {
  let itemIndex: Int
  let attachmentIndex: Int
  let identifiers: [String]
  let text: ProviderValue?
  let url: ProviderValue?
}

struct ShareRecord: Codable {
  let receivedAt: Date
  let hostToken: String?
  let providers: [ProviderRecord]
  var composeURL: String?
  var composeText: String?
  var openDispatched: Bool?
}

enum ProbeStore {
  static var groupIdentifier: String {
    Bundle.main.object(forInfoDictionaryKey: "ProbeAppGroup") as? String ?? ""
  }

  static var directory: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
  }

  static func hostToken() -> String? {
    guard let directory else { return nil }
    return try? String(contentsOf: directory.appendingPathComponent("host-token.txt"), encoding: .utf8)
  }

  static func prepareHost() throws -> String {
    guard let directory else { throw StoreError.unavailable }
    if let token = hostToken() { return token }
    let token = UUID().uuidString
    try token.write(to: directory.appendingPathComponent("host-token.txt"), atomically: true, encoding: .utf8)
    return token
  }

  static func save(_ record: ShareRecord) throws {
    guard let directory else { throw StoreError.unavailable }
    try encoded(record).write(to: directory.appendingPathComponent("latest-share.json"), options: .atomic)
  }

  static func load() throws -> ShareRecord? {
    guard let directory else { throw StoreError.unavailable }
    let path = directory.appendingPathComponent("latest-share.json")
    guard FileManager.default.fileExists(atPath: path.path) else { return nil }
    return try JSONDecoder().decode(ShareRecord.self, from: Data(contentsOf: path))
  }

  static func encoded(_ record: ShareRecord) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return try encoder.encode(record)
  }

  enum StoreError: LocalizedError {
    case unavailable

    var errorDescription: String? {
      "App Groupsの共有領域にアクセスできません。署名・プロファイル・グループIDの確認が必要です。"
    }
  }
}
