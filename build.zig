const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ZigUI Core Library
    const zigui = b.addStaticLibrary(.{
        .name = "zigui",
        .root_source_file = b.path("src/zigui.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link system libraries based on platform
    if (target.result.os.tag == .windows) {
        zigui.linkSystemLibrary("user32");
        zigui.linkSystemLibrary("gdi32");
        zigui.linkSystemLibrary("opengl32");
        zigui.linkSystemLibrary("kernel32");
    } else if (target.result.os.tag == .macos) {
        zigui.linkFramework("Cocoa");
        zigui.linkFramework("OpenGL");
        zigui.linkFramework("CoreGraphics");
    } else {
        zigui.linkSystemLibrary("X11");
        zigui.linkSystemLibrary("GL");
        zigui.linkSystemLibrary("GLU");
        zigui.linkSystemLibrary("pthread");
    }

    zigui.linkLibC();
    b.installArtifact(zigui);

    // Example applications
    const examples = [_][]const u8{
        "basic_window",
        "ui_components",
        "animations_demo",
        "3d_demo",
        "complex_app",
    };

    for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example,
            .root_source_file = b.path(b.fmt("examples/{s}.zig", .{example})),
            .target = target,
            .optimize = optimize,
        });
        exe.linkLibrary(zigui);
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        
        const run_step = b.step(b.fmt("run-{s}", .{example}), b.fmt("Run {s} example", .{example}));
        run_step.dependOn(&run_cmd.step);
    }

    // Tests
    const tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.linkLibrary(zigui);

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_tests.step);
}