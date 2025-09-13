const std = @import("std");
const Easing = @import("easing.zig").Easing;

pub const Animation = struct {
    allocator: std.mem.Allocator,
    duration: f32,
    current_time: f32,
    is_playing: bool,
    is_paused: bool,
    loop: bool,
    ping_pong: bool,
    easing: Easing.Function,
    
    // Callbacks
    on_start: ?*const fn(*Animation) void,
    on_update: ?*const fn(*Animation, f32) void,
    on_complete: ?*const fn(*Animation) void,
    
    // User data
    user_data: ?*anyopaque,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, duration: f32) !*Self {
        var animation = try allocator.create(Self);
        animation.* = Self{
            .allocator = allocator,
            .duration = duration,
            .current_time = 0.0,
            .is_playing = false,
            .is_paused = false,
            .loop = false,
            .ping_pong = false,
            .easing = .Linear,
            .on_start = null,
            .on_update = null,
            .on_complete = null,
            .user_data = null,
        };
        return animation;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn start(self: *Self) void {
        self.is_playing = true;
        self.is_paused = false;
        if (self.on_start) |callback| {
            callback(self);
        }
    }

    pub fn stop(self: *Self) void {
        self.is_playing = false;
        self.is_paused = false;
        self.current_time = 0.0;
    }

    pub fn pause(self: *Self) void {
        self.is_paused = true;
    }

    pub fn resume(self: *Self) void {
        self.is_paused = false;
    }

    pub fn reset(self: *Self) void {
        self.current_time = 0.0;
        self.is_playing = false;
        self.is_paused = false;
    }

    pub fn update(self: *Self, delta_time: f32) void {
        if (!self.is_playing or self.is_paused) return;

        self.current_time += delta_time;

        if (self.current_time >= self.duration) {
            if (self.loop) {
                if (self.ping_pong) {
                    // Reverse direction for ping-pong
                    self.current_time = self.duration - (self.current_time - self.duration);
                } else {
                    self.current_time = std.math.fmod(self.current_time, self.duration);
                }
            } else {
                self.current_time = self.duration;
                self.is_playing = false;
                
                if (self.on_complete) |callback| {
                    callback(self);
                }
            }
        }

        if (self.on_update) |callback| {
            callback(self, self.getValue());
        }
    }

    pub fn getValue(self: *Self) f32 {
        if (self.duration <= 0.0) return 1.0;
        
        const t = std.math.clamp(self.current_time / self.duration, 0.0, 1.0);
        return Easing.apply(self.easing, t);
    }

    pub fn getProgress(self: *Self) f32 {
        if (self.duration <= 0.0) return 1.0;
        return std.math.clamp(self.current_time / self.duration, 0.0, 1.0);
    }

    pub fn setDuration(self: *Self, duration: f32) void {
        self.duration = @max(duration, 0.0);
    }

    pub fn setLoop(self: *Self, loop: bool) void {
        self.loop = loop;
    }

    pub fn setPingPong(self: *Self, ping_pong: bool) void {
        self.ping_pong = ping_pong;
    }

    pub fn setEasing(self: *Self, easing: Easing.Function) void {
        self.easing = easing;
    }

    pub fn setOnStart(self: *Self, callback: *const fn(*Animation) void) void {
        self.on_start = callback;
    }

    pub fn setOnUpdate(self: *Self, callback: *const fn(*Animation, f32) void) void {
        self.on_update = callback;
    }

    pub fn setOnComplete(self: *Self, callback: *const fn(*Animation) void) void {
        self.on_complete = callback;
    }
};

pub const AnimationManager = struct {
    allocator: std.mem.Allocator,
    animations: std.ArrayList(*Animation),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !*Self {
        var manager = try allocator.create(Self);
        manager.* = Self{
            .allocator = allocator,
            .animations = std.ArrayList(*Animation).init(allocator),
        };
        return manager;
    }

    pub fn deinit(self: *Self) void {
        for (self.animations.items) |animation| {
            animation.deinit();
        }
        self.animations.deinit();
        self.allocator.destroy(self);
    }

    pub fn addAnimation(self: *Self, animation: *Animation) !void {
        try self.animations.append(animation);
    }

    pub fn removeAnimation(self: *Self, animation: *Animation) void {
        for (self.animations.items, 0..) |anim, i| {
            if (anim == animation) {
                _ = self.animations.swapRemove(i);
                break;
            }
        }
    }

    pub fn update(self: *Self, delta_time: f32) void {
        // Update all animations
        for (self.animations.items) |animation| {
            animation.update(delta_time);
        }

        // Remove completed non-looping animations
        var i: usize = 0;
        while (i < self.animations.items.len) {
            const animation = self.animations.items[i];
            if (!animation.is_playing and !animation.loop) {
                _ = self.animations.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }

    pub fn stopAll(self: *Self) void {
        for (self.animations.items) |animation| {
            animation.stop();
        }
    }

    pub fn pauseAll(self: *Self) void {
        for (self.animations.items) |animation| {
            animation.pause();
        }
    }

    pub fn resumeAll(self: *Self) void {
        for (self.animations.items) |animation| {
            animation.resume();
        }
    }
};