import Foundation

enum SignatureDiagnostics {
  struct Declaration {
    let xmlGroups: [String]?
    let hasDER: Bool
  }

  static func describe(bundleURL: URL, name: String, requestedGroup: String) -> String {
    do {
      guard let executable = Bundle(url: bundleURL)?.executableURL else { throw ReadError.malformed }
      let declaration = try read(Data(contentsOf: executable))
      let groups: String
      if let values = declaration.xmlGroups {
        groups = values.isEmpty ? "App Groupsなし" : values.joined(separator: "\n")
      } else {
        groups = "XML宣言なし（権限は未判定）"
      }
      let permitted = declaration.xmlGroups.map { $0.contains(requestedGroup) ? "あり" : "なし" } ?? "未判定"
      return "\(name)・コード署名XML：\(groups)\n設定IDの宣言：\(permitted)\nDER宣言ブロック：\(declaration.hasDER ? "あり" : "なし")"
    } catch {
      return "\(name)・コード署名を読み取れません\n\(error.localizedDescription)"
    }
  }

  static func read(_ data: Data) throws -> Declaration {
    let bytes = [UInt8](data)
    func integer(_ offset: Int, littleEndian: Bool = false) throws -> Int {
      guard offset >= 0, offset <= bytes.count - 4 else { throw ReadError.malformed }
      let value = Array(bytes[offset..<(offset + 4)])
      return (littleEndian ? Array(value.reversed()) : value).reduce(0) { ($0 << 8) | Int($1) }
    }
    guard try integer(0, littleEndian: true) == 0xfeedfacf else { throw ReadError.unsupported }
    let commands = try integer(16, littleEndian: true)
    let commandsSize = try integer(20, littleEndian: true)
    guard commandsSize <= bytes.count - 32, commands <= commandsSize / 8 else { throw ReadError.malformed }
    var cursor = 32
    for _ in 0..<commands {
      let command = try integer(cursor, littleEndian: true)
      let size = try integer(cursor + 4, littleEndian: true)
      guard size >= 8, size <= 32 + commandsSize - cursor else { throw ReadError.malformed }
      if command == 0x1d {
        guard size >= 16 else { throw ReadError.malformed }
        let start = try integer(cursor + 8, littleEndian: true)
        let signatureSize = try integer(cursor + 12, littleEndian: true)
        guard start <= bytes.count, signatureSize <= bytes.count - start,
              signatureSize >= 12, try integer(start) == 0xfade0cc0 else { throw ReadError.malformed }
        let length = try integer(start + 4)
        let count = try integer(start + 8)
        guard length >= 12, length <= signatureSize, count <= (length - 12) / 8 else { throw ReadError.malformed }
        var xmlGroups: [String]?
        var hasDER = false
        for index in 0..<count {
          let entry = start + 12 + index * 8
          let slot = try integer(entry)
          guard slot == 5 || slot == 7 else { continue }
          let relative = try integer(entry + 4)
          guard relative >= 12 + count * 8, relative <= length - 8 else { throw ReadError.malformed }
          let blob = start + relative
          let blobLength = try integer(blob + 4)
          guard blobLength >= 8, blobLength <= length - relative else { throw ReadError.malformed }
          if slot == 5 {
            guard xmlGroups == nil, try integer(blob) == 0xfade7171 else { throw ReadError.malformed }
            let plist = try PropertyListSerialization.propertyList(from: Data(bytes[(blob + 8)..<(blob + blobLength)]), options: [], format: nil)
            guard let entitlements = plist as? [String: Any] else { throw ReadError.malformed }
            if let groups = entitlements["com.apple.security.application-groups"] {
              guard let values = groups as? [String] else { throw ReadError.malformed }
              xmlGroups = values
            } else {
              xmlGroups = []
            }
          } else {
            guard !hasDER, try integer(blob) == 0xfade7172 else { throw ReadError.malformed }
            hasDER = true
          }
        }
        return Declaration(xmlGroups: xmlGroups, hasDER: hasDER)
      }
      cursor += size
    }
    throw ReadError.missing
  }

  private enum ReadError: LocalizedError {
    case unsupported, malformed, missing

    var errorDescription: String? {
      switch self {
      case .unsupported: "この診断は生成した64ビットMach-O形式のみ対応します。権限は未判定です。"
      case .malformed: "コード署名の形式を読み取れません。権限は未判定です。"
      case .missing: "コード署名ブロックがありません。権限は未判定です。"
      }
    }
  }
}
