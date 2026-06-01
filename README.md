# mirror-zig

OCX mirror for [Zig](https://ziglang.org). Publishes the official
`ziglang.org/download` archives to `ocx.sh/zig` with cascade tags after a
smoke test per `(version, platform)`.

Zig does not ship prebuilt binaries via GitHub Releases (the GitHub repo
moved to Codeberg and carries only a source bootstrap tarball). The canonical
download index lives at `https://ziglang.org/download/index.json`, so this
mirror runs a small `generate.py` that emits a `url_index` JSON document. The
script uses [`ocx-mirror-sdk`](https://github.com/ocx-sh/ocx-mirror-sdk)
(pinned to the published wheel via PEP 723 inline metadata).

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror.yml` | hand | `ocx-mirror pipeline generate ci` |
| `generate.py` | hand | — |
| `tests/smoke.star` | hand | — |
| `metadata.json`, `CATALOG.md`, `logo.*` | hand | — |
| `.github/workflows/*.yml` | generated | re-run when `mirror.yml` changes |

CI fails on drift via `ocx-mirror pipeline generate ci --check`.

## Bumping the SDK pin

Edit the `[tool.uv.sources]` block at the top of `generate.py` to point at
a newer wheel:

```toml
ocx-mirror-sdk = { url = "https://github.com/ocx-sh/ocx-mirror-sdk/releases/download/vX.Y.Z/ocx_mirror_sdk-X.Y.Z-py3-none-any.whl" }
```

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_MIRROR_REGISTRY_TOKEN` + `OCX_MIRROR_REGISTRY_USER` | `ocx package push` to `ocx.sh` |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets (Zig logo, mirrored
binaries) are out of scope; see [`NOTICE.md`](NOTICE.md).
