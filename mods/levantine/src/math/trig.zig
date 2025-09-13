const std = @import("std");
const math = std.math;
const testing = std.testing;
const core = @import("core.zig");

pub const PI = core.PI;
pub const TAU = core.TAU;

pub const TrigUnit = enum {
    degrees,
    radians,
    gradians,
};

fn toRadians(angle: f64, unit: TrigUnit) f64 {
    return switch (unit) {
        .degrees => angle * (PI / 180.0),
        .radians => angle,
        .gradians => angle * (PI / 200.0),
    };
}

fn fromRadians(angle: f64, unit: TrigUnit) f64 {
    return switch (unit) {
        .degrees => angle * (180.0 / PI),
        .radians => angle,
        .gradians => angle * (200.0 / PI),
    };
}

pub fn sin(angle: f64, unit: TrigUnit) f64 {
    return math.sin(toRadians(angle, unit));
}

pub fn cos(angle: f64, unit: TrigUnit) f64 {
    return math.cos(toRadians(angle, unit));
}

pub fn tan(angle: f64, unit: TrigUnit) f64 {
    return math.tan(toRadians(angle, unit));
}

pub fn asin(x: f64, unit: TrigUnit) f64 {
    return fromRadians(math.asin(x), unit);
}

pub fn acos(x: f64, unit: TrigUnit) f64 {
    return fromRadians(math.acos(x), unit);
}

pub fn atan(x: f64, unit: TrigUnit) f64 {
    return fromRadians(math.atan(x), unit);
}

pub fn atan2(y: f64, x: f64, unit: TrigUnit) f64 {
    return fromRadians(math.atan2(f64, y, x), unit);
}

pub fn sinh(x: f64) f64 {
    return (math.exp(x) - math.exp(-x)) / 2.0;
}

pub fn cosh(x: f64) f64 {
    return (math.exp(x) + math.exp(-x)) / 2.0;
}

pub fn tanh(x: f64) f64 {
    return sinh(x) / cosh(x);
}

pub fn asinh(x: f64) f64 {
    return math.log(x + math.sqrt(x * x + 1.0));
}

pub fn acosh(x: f64) f64 {
    if (x < 1.0) return math.nan(f64);
    return math.log(x + math.sqrt(x * x - 1.0));
}

pub fn atanh(x: f64) f64 {
    if (x <= -1.0 or x >= 1.0) return math.nan(f64);
    return 0.5 * math.log((1.0 + x) / (1.0 - x));
}

test "trigonometric functions" {
    const epsilon = 0.0001;
    
    // Test basic trig functions
    try testing.approxEqAbs(f64, 0.0, sin(0.0, .radians), epsilon);
    try testing.approxEqAbs(f64, 1.0, sin(90.0, .degrees), epsilon);
    try testing.approxEqAbs(f64, 0.0, cos(90.0, .degrees), epsilon);
    
    // Test inverse trig functions
    try testing.approxEqAbs(f64, 90.0, asin(1.0, .degrees), epsilon);
    try testing.approxEqAbs(f64, 0.0, acos(1.0, .radians), epsilon);
    
    // Test hyperbolic functions
    try testing.approxEqAbs(f64, 1.1752, sinh(1.0), epsilon);
    try testing.approxEqAbs(f64, 1.54308, cosh(1.0), epsilon);
    
    // Test inverse hyperbolic functions
    try testing.approxEqAbs(f64, 1.0, asinh(1.1752), epsilon);
    try testing.approxEqAbs(f64, 1.0, acosh(1.54308), epsilon);
}
