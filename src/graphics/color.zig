const std = @import("std");

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,

    const Self = @This();

    pub fn init(r: f32, g: f32, b: f32, a: f32) Self {
        return Self{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn initRGB(r: f32, g: f32, b: f32) Self {
        return Self.init(r, g, b, 1.0);
    }

    pub fn initRGBA(rgba: u32) Self {
        const r = @as(f32, @floatFromInt((rgba >> 24) & 0xFF)) / 255.0;
        const g = @as(f32, @floatFromInt((rgba >> 16) & 0xFF)) / 255.0;
        const b = @as(f32, @floatFromInt((rgba >> 8) & 0xFF)) / 255.0;
        const a = @as(f32, @floatFromInt(rgba & 0xFF)) / 255.0;
        return Self.init(r, g, b, a);
    }

    pub fn initHSV(h: f32, s: f32, v: f32) Self {
        return Self.initHSVA(h, s, v, 1.0);
    }

    pub fn initHSVA(h: f32, s: f32, v: f32, a: f32) Self {
        const c = v * s;
        const x = c * (1.0 - @abs(@mod(h / 60.0, 2.0) - 1.0));
        const m = v - c;
        
        var r: f32 = 0;
        var g: f32 = 0;
        var b: f32 = 0;
        
        if (h >= 0 and h < 60) {
            r = c; g = x; b = 0;
        } else if (h >= 60 and h < 120) {
            r = x; g = c; b = 0;
        } else if (h >= 120 and h < 180) {
            r = 0; g = c; b = x;
        } else if (h >= 180 and h < 240) {
            r = 0; g = x; b = c;
        } else if (h >= 240 and h < 300) {
            r = x; g = 0; b = c;
        } else if (h >= 300 and h < 360) {
            r = c; g = 0; b = x;
        }
        
        return Self.init(r + m, g + m, b + m, a);
    }

    pub fn lerp(self: Self, other: Self, t: f32) Self {
        return Self.init(
            self.r + (other.r - self.r) * t,
            self.g + (other.g - self.g) * t,
            self.b + (other.b - self.b) * t,
            self.a + (other.a - self.a) * t,
        );
    }

    pub fn multiply(self: Self, other: Self) Self {
        return Self.init(
            self.r * other.r,
            self.g * other.g,
            self.b * other.b,
            self.a * other.a,
        );
    }

    pub fn add(self: Self, other: Self) Self {
        return Self.init(
            @min(self.r + other.r, 1.0),
            @min(self.g + other.g, 1.0),
            @min(self.b + other.b, 1.0),
            @min(self.a + other.a, 1.0),
        );
    }

    pub fn withAlpha(self: Self, alpha: f32) Self {
        return Self.init(self.r, self.g, self.b, alpha);
    }

    pub fn toRGBA(self: Self) u32 {
        const r = @as(u32, @intFromFloat(self.r * 255.0));
        const g = @as(u32, @intFromFloat(self.g * 255.0));
        const b = @as(u32, @intFromFloat(self.b * 255.0));
        const a = @as(u32, @intFromFloat(self.a * 255.0));
        return (r << 24) | (g << 16) | (b << 8) | a;
    }

    // Predefined colors
    pub const WHITE = Self.init(1.0, 1.0, 1.0, 1.0);
    pub const BLACK = Self.init(0.0, 0.0, 0.0, 1.0);
    pub const RED = Self.init(1.0, 0.0, 0.0, 1.0);
    pub const GREEN = Self.init(0.0, 1.0, 0.0, 1.0);
    pub const BLUE = Self.init(0.0, 0.0, 1.0, 1.0);
    pub const YELLOW = Self.init(1.0, 1.0, 0.0, 1.0);
    pub const MAGENTA = Self.init(1.0, 0.0, 1.0, 1.0);
    pub const CYAN = Self.init(0.0, 1.0, 1.0, 1.0);
    pub const TRANSPARENT = Self.init(0.0, 0.0, 0.0, 0.0);
    pub const GRAY = Self.init(0.5, 0.5, 0.5, 1.0);
    pub const LIGHT_GRAY = Self.init(0.75, 0.75, 0.75, 1.0);
    pub const DARK_GRAY = Self.init(0.25, 0.25, 0.25, 1.0);
    
    // Material Design colors
    pub const PRIMARY = Self.initRGBA(0x6200EAFF);
    pub const PRIMARY_VARIANT = Self.initRGBA(0x3700B3FF);
    pub const SECONDARY = Self.initRGBA(0x03DAC6FF);
    pub const SECONDARY_VARIANT = Self.initRGBA(0x018786FF);
    pub const BACKGROUND = Self.initRGBA(0xFFFFFFFF);
    pub const SURFACE = Self.initRGBA(0xFFFFFFFF);
    pub const ERROR = Self.initRGBA(0xB00020FF);
    pub const ON_PRIMARY = Self.initRGBA(0xFFFFFFFF);
    pub const ON_SECONDARY = Self.initRGBA(0x000000FF);
    pub const ON_BACKGROUND = Self.initRGBA(0x000000FF);
    pub const ON_SURFACE = Self.initRGBA(0x000000FF);
    pub const ON_ERROR = Self.initRGBA(0xFFFFFFFF);
};

test "Color initialization" {
    const testing = std.testing;
    
    const color = Color.init(0.5, 0.7, 0.9, 1.0);
    try testing.expectEqual(@as(f32, 0.5), color.r);
    try testing.expectEqual(@as(f32, 0.7), color.g);
    try testing.expectEqual(@as(f32, 0.9), color.b);
    try testing.expectEqual(@as(f32, 1.0), color.a);
}

test "Color RGBA conversion" {
    const testing = std.testing;
    
    const color = Color.initRGBA(0xFF8080FF);
    try testing.expectApproxEqAbs(@as(f32, 1.0), color.r, 0.01);
    try testing.expectApproxEqAbs(@as(f32, 0.502), color.g, 0.01);
    try testing.expectApproxEqAbs(@as(f32, 0.502), color.b, 0.01);
    try testing.expectApproxEqAbs(@as(f32, 1.0), color.a, 0.01);
}