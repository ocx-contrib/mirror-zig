# zig/tests/smoke.star — stable across upstream Zig releases.
# Asserts behavior/contract (exit codes, version digits, a real compile-and-run,
# env-var honoring), never upstream-controlled prose. See testing-practices.md.
ZIG = "zig.exe" if ocx.target_platform.os == ocx.os.Windows else "zig"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE.
# `zig version` prints a bare semver (e.g. "0.14.0") to stdout.
r_version = ocx.run(ZIG, "version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 4 wiring (set up first; reused by the Tier-3 run below).
# Zig writes its global cache where ZIG_GLOBAL_CACHE_DIR points, and needs a
# writable HOME for hermetic runs. Point both at scratch so the side effect is
# observable and the run never touches the real user home. zig-cache is left
# for zig to CREATE — its appearance proves the env var was honored.
ocx.mkdir("home")
cache = ocx.scratch_root + "/zig-cache"
home = ocx.scratch_root + "/home"
zig_env = {"ZIG_GLOBAL_CACHE_DIR": cache, "HOME": home}
expect.false(ocx.exists("zig-cache"))   # absent before the compile

# Tier 3: functional behavior on hermetic input — compile AND EXECUTE a real
# program, then assert on what it COMPUTED. `@import("std")` only resolves if
# the bundle's `lib/` stdlib tree shipped alongside the binary and zig found it
# relative to its own executable, so a passing run proves the archive is whole,
# not merely that the compiler starts. The token embeds the sum of i² for
# i in 0..6 (0+1+4+9+16+25+36 = 91), computed at runtime — an echoed literal
# could not produce it.
#
# `std.debug.print` is the one printing API stable across the whole mirrored
# range (0.14 → 0.16, which reworked the Writer interface); it writes to
# stderr, which is where the token is asserted.
ocx.write_file("hello.zig", """
const std = @import("std");
pub fn main() void {
    var sum: u32 = 0;
    var i: u32 = 0;
    while (i < 7) : (i += 1) sum += i * i;
    std.debug.print("ocx-zig-smoke-{d}\\n", .{sum});
}
""")
r_run = ocx.run(ZIG, "run", "hello.zig", env=zig_env)
expect.ok(r_run)
expect.contains(r_run.stderr, "ocx-zig-smoke-91")

# Tier 4: behavioral honoring — the build above was told to cache under the
# scratch dir via ZIG_GLOBAL_CACHE_DIR. Zig creates the global cache (with its
# `h/` hash manifests) on any successful build, so its presence proves the
# binary read and honored the env var rather than falling back to the real
# user cache.
expect.true(ocx.exists("zig-cache"))
expect.true(ocx.exists("zig-cache/h"))
