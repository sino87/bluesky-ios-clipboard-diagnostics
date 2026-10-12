import Foundation

enum ProfileDiagnostics {
  static func describe(bundleURL: URL, name: String, requestedGroup: String) -> String {
    do {
      let data = try Data(contentsOf: bundleURL.appendingPathComponent("embedded.mobileprovision"))
      let groups = try appGroups(in: data)
      let permitted = groups.contains(requestedGroup) ? "あり" : "なし"
      let values = groups.isEmpty ? "App Groupsなし" : groups.joined(separator: "\n")
      return "\(name)：\(values)\n設定IDの許可：\(permitted)"
    } catch {
      return "\(name)：プロファイルを確認できません\n\(error.localizedDescription)"
    }
  }

  static func appGroups(in profile: Data) throws -> [String] {
    let root = try elements(in: profile)
    guard root.count == 1, root[0].tag == 0x30 else { throw ReadError.invalidCMS }
    let contentInfo = try elements(in: root[0].content)
    let signedDataOID = Data([0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x07, 0x02])
    guard contentInfo.count == 2,
          contentInfo[0].tag == 0x06, contentInfo[0].content == signedDataOID,
          contentInfo[1].tag == 0xa0 else { throw ReadError.invalidCMS }
    let signedDataWrapper = try elements(in: contentInfo[1].content)
    guard signedDataWrapper.count == 1, signedDataWrapper[0].tag == 0x30 else { throw ReadError.invalidCMS }
    let signedData = try elements(in: signedDataWrapper[0].content)
    guard signedData.count >= 3, signedData[2].tag == 0x30 else { throw ReadError.invalidCMS }
    let encapsulated = try elements(in: signedData[2].content)
    let dataOID = Data([0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x07, 0x01])
    guard encapsulated.count == 2,
          encapsulated[0].tag == 0x06, encapsulated[0].content == dataOID,
          encapsulated[1].tag == 0xa0 else { throw ReadError.invalidCMS }
    let payload = try elements(in: encapsulated[1].content)
    guard payload.count == 1, payload[0].tag == 0x04 else { throw ReadError.invalidCMS }
    let plist = try PropertyListSerialization.propertyList(from: payload[0].content, options: [], format: nil)
    guard let dictionary = plist as? [String: Any],
          let entitlements = dictionary["Entitlements"] as? [String: Any] else { throw ReadError.invalidPlist }
    guard let groups = entitlements["com.apple.security.application-groups"] else { return [] }
    guard let groups = groups as? [String] else { throw ReadError.invalidPlist }
    return groups
  }

  private struct Element {
    let tag: UInt8
    let content: Data
  }

  private static func elements(in data: Data) throws -> [Element] {
    let bytes = [UInt8](data)
    var index = 0
    var result: [Element] = []
    while index < bytes.count {
      guard bytes.count - index >= 2 else { throw ReadError.invalidCMS }
      let tag = bytes[index]
      let firstLength = bytes[index + 1]
      index += 2
      var length = Int(firstLength)
      if firstLength & 0x80 != 0 {
        let count = Int(firstLength & 0x7f)
        guard count > 0, count <= 4, bytes.count - index >= count else { throw ReadError.invalidCMS }
        length = 0
        for byte in bytes[index..<(index + count)] { length = (length << 8) | Int(byte) }
        index += count
      }
      guard length <= bytes.count - index else { throw ReadError.invalidCMS }
      result.append(Element(tag: tag, content: Data(bytes[index..<(index + length)])))
      index += length
    }
    return result
  }

  private enum ReadError: LocalizedError {
    case invalidCMS
    case invalidPlist

    var errorDescription: String? {
      switch self {
      case .invalidCMS: "プロファイルのCMS形式を読み取れません。権限の有無は未判定です。"
      case .invalidPlist: "プロファイルのEntitlementsを読み取れません。権限の有無は未判定です。"
      }
    }
  }
}
