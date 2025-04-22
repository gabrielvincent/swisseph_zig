const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const swisseph_dir = b.option([]const u8, "swisseph_dir", "Path to swisseph directory") orelse "swisseph";

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("swisseph_zig", .{
        .root_source_file = b.path("src/root.zig"),
    });

    const lib = b.addStaticLibrary(.{
        .name = "swisseph_zig",
        .root_module = lib_mod,
    });

    lib.addIncludePath(b.path(swisseph_dir));

    const lib_path = b.pathJoin(&.{ swisseph_dir, "libswe.a" });
    lib.addObjectFile(b.path(lib_path));

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}

