import hashlib
import json
import pathlib
import plistlib
import subprocess
import sys
import zipfile

archive = pathlib.Path(sys.argv[1]).resolve()
output = pathlib.Path(sys.argv[2]).resolve()
app = archive / "Products/Applications/ClipboardDeviceProbe.app"
extension = app / "PlugIns/ClipboardProbeShare.appex"
group = "group.org.sino87.clipboardprobe"


def inspect(bundle):
    with (bundle / "Info.plist").open("rb") as handle:
        info = plistlib.load(handle)
    if not info["CFBundleDisplayName"].isascii():
        raise SystemExit(f"AltServer registration requires an ASCII app name: {bundle}")
    binary = bundle / info["CFBundleExecutable"]
    platform = subprocess.check_output(
        ["xcrun", "vtool", "-show-build", str(binary)], text=True
    )
    if "platform IOS\n" not in platform or "IOSSIMULATOR" in platform:
        raise SystemExit(f"Not an iPhone binary: {binary}\n{platform}")
    if info.get("ProbeAppGroup") != group:
        raise SystemExit(f"Unexpected group configuration in {bundle}")
    entitlements_xml = subprocess.check_output(
        ["codesign", "-d", "--entitlements", ":-", str(bundle)], stderr=subprocess.PIPE
    )
    entitlements = plistlib.loads(entitlements_xml)
    if entitlements.get("com.apple.security.application-groups") != [group]:
        raise SystemExit(f"App Groups entitlement missing from signature: {bundle}")
    subprocess.run(["codesign", "--verify", "--strict", str(bundle)], check=True)
    print(platform)
    return {
        "bundle_id": info["CFBundleIdentifier"],
        "display_name": info["CFBundleDisplayName"],
        "build_version": info["CFBundleVersion"],
        "executable": info["CFBundleExecutable"],
        "requested_entitlements": entitlements,
    }


if not extension.is_dir():
    raise SystemExit("Share extension is missing; refusing to package IPA")
manifest = {
    "apple_signed": False,
    "signature": "ad-hoc; requires Apple Account signing before installation",
    "app": inspect(app),
    "share_extension": inspect(extension),
    "app_group": group,
    "note": "No Apple provisioning. Both bundles carry requested App Groups entitlements in local ad-hoc signatures. Free-account provisioning and device sharing remain unverified.",
}
output.mkdir(parents=True, exist_ok=True)
ipa = output / "ClipboardDeviceProbe-resign.ipa"
with zipfile.ZipFile(ipa, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
    for path in sorted(app.rglob("*")):
        if path.is_file():
            bundle.write(path, pathlib.Path("Payload") / app.name / path.relative_to(app))
manifest["ipa_sha256"] = hashlib.sha256(ipa.read_bytes()).hexdigest()
(output / "build-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(json.dumps(manifest, indent=2))
