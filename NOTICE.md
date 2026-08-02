# NOTICE

This repository packages and redistributes upstream software published by the
[Zig Software Foundation](https://ziglang.org). The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `zig` | `ghcr.io/ocx-contrib/ziglang/zig` | `MIT` |

---

## `zig`

Upstream: <https://ziglang.org> (source: <https://codeberg.org/ziglang/zig>)
Published to `ghcr.io/ocx-contrib/ziglang/zig`.

| Component | SPDX | Holder |
|---|---|---|
| Zig compiler + toolchain (`zig`, `lib/`, `doc/`) | **MIT** | Copyright (c) Zig contributors |

Permissive; redistribution of the compiled toolchain is granted provided the
copyright notice and permission notice are retained. Upstream ships a `LICENSE`
file inside every release archive and it is republished untouched as part of
the bundle; the terms are those of
<https://github.com/ziglang/zig/blob/master/LICENSE>. The bundled `lib/`
tree additionally vendors third-party sources (musl, glibc headers, libcxx,
mingw-w64, compiler-rt and others) under their own permissive licenses,
enumerated in upstream's `lib/libc/*/LICENSE*` and `LICENSE` appendix.

The Zig name is used for catalog identification under nominative fair use. The
logo shipped with this package is the Zig logomark (`zig-mark.svg` from
[ziglang/logo](https://github.com/ziglang/logo)), CC BY-SA 4.0, the Zig
Software Foundation — reproduced for catalog identification only. The marks
remain the property of their respective owners and no endorsement is implied.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
