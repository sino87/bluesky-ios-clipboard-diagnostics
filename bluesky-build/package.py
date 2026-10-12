import hashlib
import json
import pathlib
import plistlib
import subprocess
import sys
import zipfile

archive, output = [pathlib.Path(value).resolve() for value in sys.argv[1:3]]
apps = list((archive / "Products/Applications").glob("*.app"))
if len(apps) != 1:
    raise SystemExit("Expected one main app")
app = apps[0]
extensions = sorted((app / "PlugIns").glob("*.appex"))
expected = {"org.sino87.blueskysharetest", "org.sino87.blueskysharetest.Share-with-Bluesky", "org.sino87.blueskysharetest.BlueskyNSE"}
if len(extensions) != 2 or (app / "AppClips").exists():
    raise SystemExit("Share/notification extensions must remain; no App Clip")
if not (app / "main.jsbundle").is_file():
    raise SystemExit("Release JavaScript bundle missing")
group = "group.org.sino87.blueskysharetest"
output.mkdir(parents=True, exist_ok=True)
entitlements = output / "requested-entitlements.plist"
entitlements.write_bytes(plistlib.dumps({"com.apple.security.application-groups": [group]}))
for nested in sorted(app.rglob("*.framework"), key=lambda item: len(item.parts), reverse=True):
    subprocess.run(["codesign", "--force", "--sign", "-", str(nested)], check=True)
for nested in app.rglob("*.dylib"):
    subprocess.run(["codesign", "--force", "--sign", "-", str(nested)], check=True)
records = []
for bundle in [*extensions, app]:
    subprocess.run(["codesign", "--force", "--sign", "-", "--generate-entitlement-der", "--entitlements", str(entitlements), str(bundle)], check=True)
    info = plistlib.loads((bundle / "Info.plist").read_bytes())
    executable = bundle / info["CFBundleExecutable"]
    platform = subprocess.check_output(["xcrun", "vtool", "-show-build", str(executable)], text=True)
    if "platform IOS\n" not in platform or "IOSSIMULATOR" in platform:
        raise SystemExit("Not an iPhone executable")
    values = plistlib.loads(subprocess.check_output(["codesign", "-d", "--entitlements", ":-", str(bundle)], stderr=subprocess.PIPE))
    if values.get("com.apple.security.application-groups") != [group]:
        raise SystemExit("Required App Group missing")
    if not info["CFBundleDisplayName"].isascii():
        raise SystemExit("AltServer requires ASCII display names")
    if bundle.name == "Share-with-Bluesky.appex" and info.get("MainAppScheme") != "sino87blueskysharetest":
        raise SystemExit("Share extension must return to the verification app")
    records.append({"bundleID": info["CFBundleIdentifier"], "name": info["CFBundleDisplayName"], "group": group})
if {item["bundleID"] for item in records} != expected:
    raise SystemExit("Unexpected bundle identifiers")
info = plistlib.loads((app / "Info.plist").read_bytes())
schemes = [value for item in info["CFBundleURLTypes"] for value in item["CFBundleURLSchemes"]]
if "sino87blueskysharetest" not in schemes or "bluesky" in schemes or "bsky" in schemes:
    raise SystemExit("Verification URL scheme must be isolated")
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
ipa = output / "BlueskyShareTest-resign.ipa"
with zipfile.ZipFile(ipa, "w", compression=zipfile.ZIP_DEFLATED) as destination:
    for item in sorted(app.rglob("*")):
        if item.is_file():
            destination.write(item, pathlib.Path("Payload") / app.name / item.relative_to(app))
manifest = {"appleSigned": False, "requires": "Apple Account re-signing before installation", "bundles": records, "hasReleaseJSBundle": True, "sha256": hashlib.sha256(ipa.read_bytes()).hexdigest(), "bytes": ipa.stat().st_size}
(output / "build-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(json.dumps(manifest, indent=2))
