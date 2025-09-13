const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const json = std.json;

const Config = @This();

precision: Precision = .double,
display_mode: DisplayMode = .decimal,
trig_unit: TrigUnit = .radians,
max_decimal_places: u8 = 6,

const Precision = enum {
    float,
    double,
    long_double,
};

const DisplayMode = enum {
    decimal,
    scientific,
    engineering,
    hex,
    binary,
};

const TrigUnit = enum {
    degrees,
    radians,
    gradians,
};

const ConfigFile = struct {
    precision: ?Precision = null,
    display_mode: ?DisplayMode = null,
    trig_unit: ?TrigUnit = null,
    max_decimal_places: ?u8 = null,
};

pub fn load(allocator: std.mem.Allocator) !Config {
    const config_dir = try getConfigDir(allocator);
    defer allocator.free(config_dir);
    
    const config_path = try fs.path.join(allocator, &[_][]const u8{ config_dir, "config.json" });
    defer allocator.free(config_path);
    
    var config_file = fs.cwd().openFile(config_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            return Config{}; // Return default config if no config file exists
        }
        return err;
    };
    defer config_file.close();
    
    const file_size = (try config_file.stat()).size;
    const file_content = try allocator.alloc(u8, file_size);
    defer allocator.free(file_content);
    
    _ = try config_file.readAll(file_content);
    
    const config_data = try json.parseFromSlice(ConfigFile, allocator, file_content, .{});
    defer config_data.deinit();
    
    return Config{
        .precision = config_data.value.precision orelse .double,
        .display_mode = config_data.value.display_mode orelse .decimal,
        .trig_unit = config_data.value.trig_unit orelse .radians,
        .max_decimal_places = config_data.value.max_decimal_places orelse 6,
    };
}

pub fn save(self: Config, allocator: std.mem.Allocator) !void {
    const config_dir = try getConfigDir(allocator);
    defer allocator.free(config_dir);
    
    try fs.cwd().makePath(config_dir);
    
    const config_path = try fs.path.join(allocator, &[_][]const u8{ config_dir, "config.json" });
    defer allocator.free(config_path);
    
    const config_file = try fs.cwd().createFile(config_path, .{});
    defer config_file.close();
    
    const config_data = ConfigFile{
        .precision = self.precision,
        .display_mode = self.display_mode,
        .trig_unit = self.trig_unit,
        .max_decimal_places = self.max_decimal_places,
    };
    
    try json.stringify(config_data, .{}, config_file.writer());
}

pub fn deinit(self: *Config) void {
    _ = self;
}

fn getConfigDir(allocator: std.mem.Allocator) ![]const u8 {
    const home_dir = std.os.getenv("HOME") orelse 
                     std.os.getenv("USERPROFILE") orelse
                     ".";
    
    if (builtin.os.tag == .windows) {
        return fs.path.join(allocator, &[_][]const u8{ home_dir, "AppData", "Roaming", "levantine" });
    } else {
        return fs.path.join(allocator, &[_][]const u8{ home_dir, ".config", "levantine" });
    }
}

test "config save and load" {
    const allocator = std.testing.allocator;
    
    var config = Config{
        .precision = .double,
        .display_mode = .scientific,
        .trig_unit = .degrees,
        .max_decimal_places = 8,
    };
    
    try config.save(allocator);
    // Clean up test config file at the end
    defer {
        if (getConfigDir(allocator)) |dir| {
            defer allocator.free(dir);
            if (fs.path.join(allocator, &[_][]const u8{ dir, "config.json" })) |config_path| {
                defer allocator.free(config_path);
                _ = fs.cwd().deleteFile(config_path) catch {};
                _ = fs.cwd().deleteDir(dir) catch {};
            } else |_| {}
        } else |_| {}
    }
    
    const loaded_config = try Config.load(allocator);
    
    try std.testing.expectEqual(config.precision, loaded_config.precision);
    try std.testing.expectEqual(config.display_mode, loaded_config.display_mode);
    try std.testing.expectEqual(config.trig_unit, loaded_config.trig_unit);
    try std.testing.expectEqual(config.max_decimal_places, loaded_config.max_decimal_places);
}
