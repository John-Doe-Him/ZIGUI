const plutonium = @import("plutonium.zig");
const std = @import("std");

pub fn main() !void {
    const width = 800;
    const height = 600;
    
    var window = try plutonium.Window.init(
        width,
        height,
        "Plutonium Demo",
    );
    defer window.deinit();
    
    // Main loop
    while (!window.shouldClose()) {
        plutonium.Window.pollEvents();
        
        // Clear to black
        window.clear(0, 0, 0);
        
        // Draw a simple pattern
        const time = @as(f32, @floatFromInt(std.time.milliTimestamp() % 10000)) / 1000.0;
        const center_x = @as(f32, @floatFromInt(width)) * 0.5;
        const center_y = @as(f32, @floatFromInt(height)) * 0.5;
        const radius = @min(width, height) * 0.4;
        
        for (0..width) |x| {
            for (0..height) |y| {
                const dx = @as(f32, @floatFromInt(x)) - center_x;
                const dy = @as(f32, @floatFromInt(y)) - center_y;
                const dist = @sqrt(dx * dx + dy * dy);
                
                if (dist < radius) {
                    const angle = std.math.atan2(f32, dy, dx);
                    const r = @as(u8, @intFromFloat((1.0 + @sin(angle * 2.0 + time)) * 127.5));
                    const g = @as(u8, @intFromFloat((1.0 + @sin(angle * 3.0 + time * 1.5)) * 127.5));
                    const b = @as(u8, @intFromFloat((1.0 + @sin(angle * 5.0 + time * 0.7)) * 127.5));
                    
                    window.setPixel(
                        @intCast(x),
                        @intCast(y),
                        r,
                        g,
                        b,
                    );
                }
            }
        }
        
        window.render();
    }
}
