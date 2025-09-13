const std = @import("std");
const Window = @import("window.zig").Window;
const Event = @import("events.zig").Event;
const EventType = @import("events.zig").EventType;
const Renderer = @import("../graphics/renderer.zig").Renderer;
const Timeline = @import("../animation/timeline.zig").Timeline;

pub const Application = struct {
    allocator: std.mem.Allocator,
    windows: std.ArrayList(*Window),
    running: bool,
    renderer: *Renderer,
    timeline: *Timeline,
    fps_target: u32,
    frame_time: f64,
    last_frame_time: i64,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !*Self {
        var app = try allocator.create(Self);
        app.* = Self{
            .allocator = allocator,
            .windows = std.ArrayList(*Window).init(allocator),
            .running = false,
            .renderer = try Renderer.init(allocator),
            .timeline = try Timeline.init(allocator),
            .fps_target = 60,
            .frame_time = 1.0 / 60.0,
            .last_frame_time = std.time.milliTimestamp(),
        };
        return app;
    }

    pub fn deinit(self: *Self) void {
        for (self.windows.items) |window| {
            window.deinit();
        }
        self.windows.deinit();
        self.renderer.deinit();
        self.timeline.deinit();
        self.allocator.destroy(self);
    }

    pub fn addWindow(self: *Self, window: *Window) !void {
        try self.windows.append(window);
        window.application = self;
    }

    pub fn removeWindow(self: *Self, window: *Window) void {
        for (self.windows.items, 0..) |w, i| {
            if (w == window) {
                _ = self.windows.swapRemove(i);
                break;
            }
        }
        if (self.windows.items.len == 0) {
            self.quit();
        }
    }

    pub fn run(self: *Self) !void {
        self.running = true;
        
        while (self.running and self.windows.items.len > 0) {
            const current_time = std.time.milliTimestamp();
            const delta_time = @as(f64, @floatFromInt(current_time - self.last_frame_time)) / 1000.0;
            self.last_frame_time = current_time;

            // Process events for all windows
            for (self.windows.items) |window| {
                try self.processWindowEvents(window);
            }

            // Update animations
            self.timeline.update(@floatCast(delta_time));

            // Render all windows
            for (self.windows.items) |window| {
                if (window.visible) {
                    try self.renderWindow(window, @floatCast(delta_time));
                }
            }

            // Frame rate control
            self.limitFrameRate();
        }
    }

    pub fn quit(self: *Self) void {
        self.running = false;
    }

    pub fn setTargetFPS(self: *Self, fps: u32) void {
        self.fps_target = fps;
        self.frame_time = 1.0 / @as(f64, @floatFromInt(fps));
    }

    fn processWindowEvents(self: *Self, window: *Window) !void {
        var events = try window.pollEvents();
        defer events.deinit();

        for (events.items) |event| {
            try self.handleEvent(window, event);
        }
    }

    fn handleEvent(self: *Self, window: *Window, event: Event) !void {
        switch (event.type) {
            .WindowClose => {
                window.close();
                self.removeWindow(window);
            },
            .WindowResize => {
                try window.handleResize(event.window_resize.width, event.window_resize.height);
                try self.renderer.handleWindowResize(window, event.window_resize.width, event.window_resize.height);
            },
            .KeyPress, .KeyRelease, .MouseMove, .MousePress, .MouseRelease => {
                try window.handleEvent(event);
            },
            else => {},
        }
    }

    fn renderWindow(self: *Self, window: *Window, delta_time: f32) !void {
        try self.renderer.beginFrame(window);
        try window.render(self.renderer, delta_time);
        try self.renderer.endFrame();
    }

    fn limitFrameRate(self: *Self) void {
        const frame_end_time = std.time.milliTimestamp();
        const frame_duration = @as(f64, @floatFromInt(frame_end_time - self.last_frame_time)) / 1000.0;
        
        if (frame_duration < self.frame_time) {
            const sleep_time = self.frame_time - frame_duration;
            std.time.sleep(@as(u64, @intFromFloat(sleep_time * 1_000_000_000)));
        }
    }
};