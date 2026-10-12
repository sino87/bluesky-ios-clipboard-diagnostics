import Foundation

func require(_ condition: Bool, _ message: String) {
  guard condition else { fatalError(message) }
}

func integer(_ value: Int, littleEndian: Bool = false) -> Data {
  let bytes = [24, 16, 8, 0].map { UInt8((value >> $0) & 0xff) }
  return Data(littleEndian ? Array(bytes.reversed()) : bytes)
}

func executable(groups: Any?, xml: Bool = true) throws -> Data {
  let entitlements = groups.map { ["com.apple.security.application-groups": $0] } ?? [:]
  let plist = try PropertyListSerialization.data(fromPropertyList: entitlements, format: .xml, options: 0)
  let xmlBlob = integer(0xfade7171) + integer(plist.count + 8) + plist
  let derBlob = integer(0xfade7172) + integer(10) + Data([0x31, 0])
  let count = xml ? 2 : 1
  let indicesSize = 12 + count * 8
  var indices = Data()
  if xml { indices += integer(5) + integer(indicesSize) }
  indices += integer(7) + integer(indicesSize + (xml ? xmlBlob.count : 0))
  let blobs = (xml ? xmlBlob : Data()) + derBlob
  let signature = integer(0xfade0cc0) + integer(indicesSize + blobs.count) + integer(count) + indices + blobs
  let header = [0xfeedfacf, 0x100000c, 0, 2, 1, 16, 0, 0].reduce(Data()) { $0 + integer($1, littleEndian: true) }
  let command = [0x1d, 16, 48, signature.count].reduce(Data()) { $0 + integer($1, littleEndian: true) }
  return header + command + signature
}

let group = "group.org.sino87.clipboardprobe"
let populated = try executable(groups: [group])
let declaration = try SignatureDiagnostics.read(populated)
require(declaration.xmlGroups == [group] && declaration.hasDER, "XML groups and DER presence must be read")
require(try SignatureDiagnostics.read(executable(groups: nil)).xmlGroups == [], "Missing XML capability must report absent")
let derOnly = try SignatureDiagnostics.read(executable(groups: nil, xml: false))
require(derOnly.xmlGroups == nil && derOnly.hasDER, "DER-only data must leave XML groups undetermined")
var invalidOffset = populated
invalidOffset.replaceSubrange(40..<44, with: integer(0xffffffff, littleEndian: true))
for invalid in [Data(), Data(populated.dropLast()), invalidOffset, try executable(groups: "invalid")] {
  do {
    _ = try SignatureDiagnostics.read(invalid)
    fatalError("Unreadable signature must not report groups absent")
  } catch {}
}
require(CommandLine.arguments.count == 3, "Pass both generated device executables")
for path in CommandLine.arguments.dropFirst() {
  let actual = try SignatureDiagnostics.read(Data(contentsOf: URL(fileURLWithPath: path)))
  require(actual.xmlGroups == [group] && actual.hasDER, "Actual device signature must match codesign entitlements")
}
print("Signature checks passed: groups present, absent, XML unavailable, malformed, and both real device signatures")
