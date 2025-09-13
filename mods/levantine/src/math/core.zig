const std = @import("std");
const math = std.math;
const testing = std.testing;

pub const PI = 3.1415926535897932384626433832795;
pub const E = 2.7182818284590452353602874713527;
pub const TAU = 2.0 * PI;
pub const PHI = 1.6180339887498948482045868343656;

pub fn factorial(comptime T: type, n: T) T {
    if (n < 0) return math.nan(T);
    if (n == 0) return 1;
    
    var result: T = 1;
    var i: T = 1;
    while (i <= n) : (i += 1) {
        result *= i;
    }
    return result;
}

pub fn gcd(comptime T: type, a: T, b: T) T {
    var x = a;
    var y = b;
    while (y != 0) {
        const temp = y;
        y = @mod(x, y);
        x = temp;
    }
    return x;
}

pub fn lcm(comptime T: type, a: T, b: T) T {
    if (a == 0 or b == 0) return 0;
    return (a / gcd(T, a, b)) * b;
}

pub fn isPrime(comptime T: type, n: T) bool {
    if (n <= 1) return false;
    if (n <= 3) return true;
    if (@mod(n, 2) == 0 or @mod(n, 3) == 0) return false;
    
    var i: T = 5;
    while (i * i <= n) : (i += 6) {
        if (@mod(n, i) == 0 or @mod(n, i + 2) == 0) {
            return false;
        }
    }
    return true;
}

pub fn pow(comptime T: type, base: T, exponent: T) T {
    return math.pow(T, base, exponent);
}

pub fn root(comptime T: type, x: T, n: T) T {
    if (x < 0 and @mod(n, 2) == 0) return math.nan(T);
    if (x == 0) return 0;
    
    var result = x / n;
    var prev = result + 1.0;
    
    while (math.fabs(result - prev) > 0.000001) {
        prev = result;
        result = ((n - 1) * prev + x / math.pow(T, prev, n - 1)) / n;
    }
    
    return result;
}

pub fn log(comptime T: type, x: T, base: T) T {
    return math.log(x) / math.log(base);
}

test "factorial" {
    try testing.expectEqual(@as(i32, 120), factorial(i32, 5));
    try testing.expectEqual(@as(i64, 1), factorial(i64, 0));
    try testing.expect(math.isNan(factorial(f64, -1)));
}

test "gcd and lcm" {
    try testing.expectEqual(@as(i32, 6), gcd(i32, 48, 18));
    try testing.expectEqual(@as(i64, 144), lcm(i64, 16, 18));
}

test "isPrime" {
    try testing.expect(!isPrime(i32, 1));
    try testing.expect(isPrime(i32, 2));
    try testing.expect(isPrime(i32, 7));
    try testing.expect(!isPrime(i32, 9));
    try testing.expect(isPrime(i32, 17));
}

test "pow and root" {
    try testing.approxEqAbs(f64, 8.0, pow(f64, 2.0, 3.0), 0.0001);
    try testing.approxEqAbs(f64, 2.0, root(f64, 8.0, 3.0), 0.0001);
}

test "log" {
    try testing.approxEqAbs(f64, 3.0, log(f64, 8.0, 2.0), 0.0001);
}
