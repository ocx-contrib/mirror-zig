# tests/smoke.star — stable across upstream Zig releases.
# Asserts behavior/contract (exit codes, version digits, a real compile,
# env-var honoring), never upstream-controlled prose. See testing-practices.md.
ZIG = "zig.exe" if ocx.target_platform.os == ocx.os.Windows else "zig"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE.
# `zig version` prints a bare semver (e.g. "0.14.0") to stdout.
r_version = ocx.run(ZIG, "version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 4 wiring (set up first; reused by the Tier-3 compile below).
# Zig writes its global cache where ZIG_GLOBAL_CACHE_DIR points, and needs a
# writable HOME for hermetic runs. Point both at scratch so the side effect is
# observable and the run never touches the real user home. zig-cache is left
# for zig to CREATE — its appearance proves the env var was honored.
ocx.mkdir("home")
cache = ocx.scratch_root + "/zig-cache"
home = ocx.scratch_root + "/home"
zig_env = {"ZIG_GLOBAL_CACHE_DIR": cache, "HOME": home}
expect.false(ocx.exists("zig-cache"))   # absent before the compile

# Tier 3: functional behavior on hermetic input — compile a real program and
# assert the compiler exits 0 (exercises the actual codegen path, not a
# --version short-circuit). build-exe produces the binary in the CWD (scratch).
ocx.write_file("hello.zig", """
const std = @import("std");
pub fn main() void {
    std.debug.print("hi\\n", .{});
}
""")
r_build = ocx.run(ZIG, "build-exe", "hello.zig", env=zig_env)
expect.ok(r_build)

# Tier 4: behavioral honoring — the compile was told to cache under the scratch
# dir via ZIG_GLOBAL_CACHE_DIR. Zig creates the global cache (with its `h/` hash
# manifests) on any successful build, so its presence proves the binary read and
# honored the env var rather than falling back to the real user cache.
expect.true(ocx.exists("zig-cache"))
expect.true(ocx.exists("zig-cache/h"))
