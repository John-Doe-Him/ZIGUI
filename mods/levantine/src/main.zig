const std = @import("std");
const lev = @import("root");
const Config = lev.Config;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    
    const allocator = gpa.allocator();
    
    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    
    if (args.len < 2) {
        try printUsage(args[0]);
        return;
    }
    
    // Load config
    var config = try Config.load(allocator);
    defer config.deinit();
    
    // Process commands
    if (std.mem.eql(u8, args[1], "version")) {
        try printVersion();
    } else if (std.mem.eql(u8, args[1], "config")) {
        try handleConfigCommand(allocator, args[2..]);
    } else if (std.mem.eql(u8, args[1], "calc")) {
        try handleCalcCommand(allocator, args[2..], config);
    } else {
        try printUsage(args[0]);
    }
}

fn printUsage(executable: []const u8) !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print(
        \\Usage: {s} <command> [options]
        \\Commands:
        \\  version         Show version information
        \\  config          Manage configuration
        \\  calc <expr>     Evaluate a mathematical expression
        \\
    , .{executable});
}

fn printVersion() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Levantine v0.1.0\n", .{});
}

fn handleConfigCommand(allocator: std.mem.Allocator, args: [][]const u8) !void {
    if (args.len == 0) {
        try printConfigUsage();
        return;
    }
    
    if (std.mem.eql(u8, args[0], "get")) {
        if (args.len < 2) {
            try printConfigUsage();
            return;
        }
        // Handle config get
    } else if (std.mem.eql(u8, args[0], "set")) {
        if (args.len < 3) {
            try printConfigUsage();
            return;
        }
        // Handle config set
    } else {
        try printConfigUsage();
    }
}

fn printConfigUsage() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print(
        \\Usage: levantine config <command> [options]
        \\Commands:
        \\  get <key>       Get configuration value
        \\  set <key> <value> Set configuration value
        \\
    , .{});
}

fn handleCalcCommand(allocator: std.mem.Allocator, args: [][]const u8, config: Config) !void {
    if (args.len == 0) {
        const stderr = std.io.getStdErr().writer();
        try stderr.print("Error: No expression provided\n", .{});
        return;
    }
    
    // Simple expression evaluation (to be expanded)
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Expression evaluation coming soon!\n", .{});
}
