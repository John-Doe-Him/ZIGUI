const std = @import("std");

// Import and re-export config
pub const config = @import("config.zig");

// Import and re-export math modules
pub const math = struct {
    pub const core = @import("math/core.zig");
    pub const trig = @import("math/trig.zig");
    pub const stats = @import("math/stats.zig");
    pub const linear = @import("math/linear.zig");
};

// Re-export common types and functions for easy access
pub const Config = config.Config;
pub const Vector = math.linear.Vector;
pub const Matrix = math.linear.Matrix;

// Test suite
const testing = std.testing;

test "import tests" {
    _ = @import("math/core.zig");
    _ = @import("math/trig.zig");
    _ = @import("math/stats.zig");
    _ = @import("math/linear.zig");
}
