# /// script
# requires-python = ">=3.13"
# dependencies = ["ocx-mirror-sdk"]
#
# [tool.uv.sources]
# ocx-mirror-sdk = { url = "https://github.com/ocx-sh/ocx-mirror-sdk/releases/download/v0.5.2/ocx_mirror_sdk-0.5.2-py3-none-any.whl" }
# ///
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The OCX Authors

"""Generate url_index JSON for Zig releases.

Zig does not publish prebuilt binaries via GitHub Releases (the GitHub repo
moved to Codeberg and ships only a source bootstrap tarball). The canonical
download index is `https://ziglang.org/download/index.json`, shaped as:

    {
      "master": { ... },                       # nightly — skipped
      "0.15.1": {
        "date": "...", "src": {...}, "bootstrap": {...},
        "x86_64-linux":   {"tarball": "<url>", "shasum": "...", "size": "..."},
        "aarch64-linux":  {...},
        "x86_64-macos":   {...},
        ...
      },
      ...
    }

The arch-os object keys we care about map to the six OCX target platforms.
The download FILENAME ordering changed across releases (0.14.0 ships
`zig-linux-x86_64-<v>.tar.xz`; 0.14.1+ ships `zig-x86_64-linux-<v>.tar.xz`),
so we derive each filename from the basename of the `tarball` URL rather than
constructing it — both orderings flow through unchanged and the mirror's
`assets:` patterns match either form.
"""

from urllib.parse import urlparse

from ocx_mirror_sdk import IndexBuilder
from ocx_mirror_sdk.http import fetch_json

INDEX_URL = "https://ziglang.org/download/index.json"

# index arch-os object key -> OCX platform. Only the six we publish; the index
# also carries armv7a/riscv64/powerpc64le/x86/loongarch entries we ignore.
PLATFORM_KEYS = {
    "x86_64-linux": "linux/amd64",
    "aarch64-linux": "linux/arm64",
    "x86_64-macos": "darwin/amd64",
    "aarch64-macos": "darwin/arm64",
    "x86_64-windows": "windows/amd64",
    "aarch64-windows": "windows/arm64",
}


def main() -> None:
    data = fetch_json(INDEX_URL)
    index = IndexBuilder()

    for version, entry in data.items():
        if version == "master":  # nightly — never published
            continue
        if not isinstance(entry, dict):
            continue

        assets: dict[str, str] = {}
        for key in PLATFORM_KEYS:
            platform_entry = entry.get(key)
            if not isinstance(platform_entry, dict):
                continue
            url = platform_entry.get("tarball")
            if not url:
                continue
            filename = urlparse(url).path.rsplit("/", 1)[-1]
            assets[filename] = url

        if assets:
            index.add_version(version, assets=assets, prerelease=False)

    index.emit()


if __name__ == "__main__":
    main()
