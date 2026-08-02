# mirror-ziglang

OCX mirror for [Zig](https://ziglang.org). One repository, one spec directory
per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [zig](https://ziglang.org) | [`zig/mirror.yml`](zig/mirror.yml) | `ghcr.io/ocx-contrib/ziglang/zig` | `ocx.sh/ziglang/zig` | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> This repository previously published the same upstream to the flat coordinate
> `ocx.sh/zig`. `ziglang/zig` is the grouped successor.

Zig ships **no prebuilt binaries via GitHub Releases** — the GitHub repo moved
to Codeberg and carries only a source bootstrap tarball. The canonical download
index lives at `https://ziglang.org/download/index.json`, so this mirror runs a
small [`zig/scripts/generate.py`](zig/scripts/generate.py) that emits a
`url_index` JSON document. The script uses
[`ocx-mirror-sdk`](https://github.com/ocx-sh/ocx-mirror-sdk), pinned to a
published wheel via PEP 723 inline metadata, and runs under the `uv` pinned in
[`ocx.toml`](ocx.toml).

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
zig/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
├── scripts/generate.py the url_index generator
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire. The generator lives under `zig/` for the same reason:
that is what the mirror workflow's `zig/**` path trigger watches.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

`zig` publishes six platform entries: both Linux arches, both macOS arches and
both Windows arches. Zig is self-hosted and links its Linux releases **fully
statically** — byte-measured on the `zig` executable from both Linux tarballs,
neither carries a `PT_INTERP` or a single `DT_NEEDED`, and upstream publishes
no musl/glibc split to choose between. `os.features` states what an artifact
requires *of the host*, so both Linux keys are **bare**: tagging them
`+libc.musl` would be a false requirement that hid them from every glibc host.
The `alpine:3.20` container leg in `mirror-base.yml` is what turns that claim
into evidence; the measurement itself is recorded above the `assets:` block in
`zig/mirror.yml`.

The download **filename ordering flipped mid-range** — 0.14.0 ships
`zig-linux-x86_64-<v>.tar.xz`, 0.14.1+ ships `zig-x86_64-linux-<v>.tar.xz` — so
every platform key carries both orderings, newer first. The version floor is
`0.14.0`, the oldest release whose index entry carries all six published
platforms.

`windows/arm64` excludes `0.16.0` (`aarch64-windows` `build-exe` segfault);
every other in-range version publishes it.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `zig/mirror.yml` | hand | yes — see below |
| `zig/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `zig/scripts/generate.py` | hand | — |
| `zig/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec zig/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## Bumping the SDK pin

Edit the `[tool.uv.sources]` block at the top of `zig/scripts/generate.py` to
point at a newer wheel:

```toml
ocx-mirror-sdk = { url = "https://github.com/ocx-sh/ocx-mirror-sdk/releases/download/vX.Y.Z/ocx_mirror_sdk-X.Y.Z-py3-none-any.whl" }
```

## The binaries claim

Zig ships an archive whose executable sits **at the content root**, beside the
`lib/` stdlib tree and `doc/` — so the bundle's only PATH entry is a bare
`${installPath}`. `bin_scan` only looks *below* an `${installPath}/<dir>` entry,
so `auto`/`verify` is rejected at spec load with exit 65. `mirror-base.yml`
therefore sets `bin_scan: off` and `zig/metadata.json` hand-lists
`binaries: ["zig"]` — which is also the right answer on the merits: a scan would
walk `lib/` and claim its exec-bit-carrying stdlib files as interface binaries.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
