import Foundation

func require(_ condition: Bool, _ message: String) {
  guard condition else { fatalError(message) }
}

func der(_ tag: UInt8, _ content: Data) -> Data {
  let length = content.count
  let encodedLength: [UInt8]
  if length < 128 {
    encodedLength = [UInt8(length)]
  } else if length < 256 {
    encodedLength = [0x81, UInt8(length)]
  } else {
    encodedLength = [0x82, UInt8(length >> 8), UInt8(length & 0xff)]
  }
  return Data([tag] + encodedLength) + content
}

func profile(entitlements: [String: Any]) throws -> Data {
  let plist = try PropertyListSerialization.data(fromPropertyList: ["Entitlements": entitlements], format: .xml, options: 0)
  let dataOID = der(0x06, Data([0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x07, 0x01]))
  let signedDataOID = der(0x06, Data([0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x07, 0x02]))
  let content = der(0x30, dataOID + der(0xa0, der(0x04, plist)))
  let signedData = der(0x30, der(0x02, Data([1])) + der(0x31, Data()) + content + der(0x31, Data()))
  return der(0x30, signedDataOID + der(0xa0, signedData))
}

let group = "group.org.sino87.clipboardprobe"
let populated = try profile(entitlements: ["com.apple.security.application-groups": [group]])
require(try ProfileDiagnostics.appGroups(in: populated) == [group], "App Group must be extracted from CMS content")
require(try ProfileDiagnostics.appGroups(in: profile(entitlements: [:])).isEmpty, "Missing capability must be distinct from unreadable data")
for invalid in [Data(), Data(populated.dropLast()), try profile(entitlements: ["com.apple.security.application-groups": "invalid"])] {
  do {
    _ = try ProfileDiagnostics.appGroups(in: invalid)
    fatalError("Malformed data must not report App Groups absent")
  } catch {}
}
if CommandLine.arguments.count > 1 {
  let genuineCMS = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
  require(try ProfileDiagnostics.appGroups(in: genuineCMS) == [group], "OpenSSL CMS content must decode")
}
print("Profile parser checks passed: present, absent, malformed, and CMS encoding")
