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
    binary = bundle / info["CFBundleExecutable"]
    platform = subprocess.check_output(
        ["xcrun", "vtool", "-show-build", str(binary)], text=True
    )
    if "platform IOS\n" not in platform or "IOSSIMULATOR" in platform:
        raise SystemExit(f"Not an iPhone binary: {binary}\n{platform}")
    if info.get("ProbeAppGroup") != group:
        raise SystemExit(f"Unexpected group configuration in {bundle}")
    print(platform)
    return {"bundle_id": info["CFBundleIdentifier"], "executable": info["CFBundleExecutable"]}


if not extension.is_dir():
    raise SystemExit("Share extension is missing; refusing to package IPA")
manifest = {
    "signed": False,
    "app": inspect(app),
    "share_extension": inspect(extension),
    "app_group": group,
    "note": "Unsigned device build. Signed provisioning and device sharing remain unverified.",
}
output.mkdir(parents=True, exist_ok=True)
ipa = output / "ClipboardDeviceProbe-unsigned.ipa"
with zipfile.ZipFile(ipa, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
    for path in sorted(app.rglob("*")):
        if path.is_file():
            bundle.write(path, pathlib.Path("Payload") / app.name / path.relative_to(app))
manifest["ipa_sha256"] = hashlib.sha256(ipa.read_bytes()).hexdigest()
(output / "build-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(json.dumps(manifest, indent=2))
