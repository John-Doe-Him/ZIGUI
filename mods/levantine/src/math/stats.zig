const std = @import("std");
const math = std.math;
const testing = std.testing;

pub fn mean(comptime T: type, data: []const T) T {
    if (data.len == 0) return math.nan(T);
    
    var sum: T = 0;
    for (data) |value| {
        sum += value;
    }
    
    return @as(T, @floatFromInt(sum)) / @as(T, @floatFromInt(data.len));
}

pub fn median(comptime T: type, data: []T) T {
    if (data.len == 0) return math.nan(T);
    
    std.sort.insertion(T, data, {}, comptime std.sort.asc(T));
    
    const mid = data.len / 2;
    if (data.len % 2 == 1) {
        return data[mid];
    } else {
        return (data[mid - 1] + data[mid]) / 2;
    }
}

pub fn mode(comptime T: type, data: []const T) ?T {
    if (data.len == 0) return null;
    
    var freq = std.AutoHashMap(T, usize).init(std.heap.page_allocator);
    defer freq.deinit();
    
    for (data) |value| {
        const entry = try freq.getOrPut(value);
        if (entry.found_existing) {
            entry.value_ptr.* += 1;
        } else {
            entry.value_ptr.* = 1;
        }
    }
    
    var max_freq: usize = 0;
    var mode_val: T = data[0];
    var has_mode = false;
    
    var it = freq.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* > max_freq) {
            max_freq = entry.value_ptr.*;
            mode_val = entry.key_ptr.*;
            has_mode = true;
        } else if (entry.value_ptr.* == max_freq) {
            has_mode = false;
        }
    }
    
    return if (has_mode) mode_val else null;
}

pub fn variance(comptime T: type, data: []const T) T {
    if (data.len < 2) return math.nan(T);
    
    const m = mean(T, data);
    var sum: T = 0;
    
    for (data) |value| {
        const diff = value - m;
        sum += diff * diff;
    }
    
    return sum / @as(T, @floatFromInt(data.len - 1));
}

pub fn standardDeviation(comptime T: type, data: []const T) T {
    return math.sqrt(variance(T, data));
}

pub fn min(comptime T: type, data: []const T) T {
    if (data.len == 0) return math.nan(T);
    
    var min_val = data[0];
    for (data[1..]) |value| {
        if (value < min_val) {
            min_val = value;
        }
    }
    return min_val;
}

pub fn max(comptime T: type, data: []const T) T {
    if (data.len == 0) return math.nan(T);
    
    var max_val = data[0];
    for (data[1..]) |value| {
        if (value > max_val) {
            max_val = value;
        }
    }
    return max_val;
}

pub fn range(comptime T: type, data: []const T) T {
    return max(T, data) - min(T, data);
}

pub fn percentile(comptime T: type, data: []T, p: T) T {
    if (data.len == 0) return math.nan(T);
    if (p <= 0) return min(T, data);
    if (p >= 100) return max(T, data);
    
    std.sort.insertion(T, data, {}, comptime std.sort.asc(T));
    
    const pos = (p / 100.0) * @as(T, @floatFromInt(data.len - 1));
    const k = @as(usize, @intFromFloat(@floor(pos)));
    const d = pos - @as(T, @floatFromInt(k));
    
    return data[k] + d * (data[k + 1] - data[k]);
}

pub fn correlation(comptime T: type, x: []const T, y: []const T) T {
    if (x.len != y.len or x.len < 2) return math.nan(T);
    
    const x_mean = mean(T, x);
    const y_mean = mean(T, y);
    
    var sum_xy: T = 0;
    var sum_x2: T = 0;
    var sum_y2: T = 0;
    
    for (x, y) |xi, yi| {
        const x_diff = xi - x_mean;
        const y_diff = yi - y_mean;
        
        sum_xy += x_diff * y_diff;
        sum_x2 += x_diff * x_diff;
        sum_y2 += y_diff * y_diff;
    }
    
    if (sum_x2 == 0 or sum_y2 == 0) return math.nan(T);
    
    return sum_xy / math.sqrt(sum_x2 * sum_y2);
}

test "statistics functions" {
    const data = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    const epsilon = 0.0001;
    
    try testing.approxEqAbs(f64, 3.0, mean(f64, &data), epsilon);
    try testing.approxEqAbs(f64, 3.0, median(f64, &data), epsilon);
    try testing.approxEqAbs(f64, 2.5, variance(f64, &data), epsilon);
    try testing.approxEqAbs(f64, 1.5811, standardDeviation(f64, &data), epsilon);
    try testing.approxEqAbs(f64, 1.0, min(f64, &data), epsilon);
    try testing.approxEqAbs(f64, 5.0, max(f64, &data), epsilon);
    try testing.approxEqAbs(f64, 4.0, range(f64, &data), epsilon);
    try testing.approxEqAbs(f64, 3.0, percentile(f64, &data, 50.0), epsilon);
    
    const x = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0 };
    const y = [_]f64{ 2.0, 3.0, 4.0, 5.0, 6.0 };
    try testing.approxEqAbs(f64, 1.0, correlation(f64, &x, &y), epsilon);
}
