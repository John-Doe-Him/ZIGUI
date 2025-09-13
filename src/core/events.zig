const std = @import("std");
const Vec2 = @import("../math/vec2.zig").Vec2;
const Platform = @import("../platform/platform.zig").Platform;

pub const EventType = enum {
    // Window events
    WindowClose,
    WindowResize,
    WindowMove,
    WindowFocus,
    WindowLostFocus,
    WindowMinimize,
    WindowMaximize,
    WindowRestore,
    
    // Input events
    KeyPress,
    KeyRelease,
    KeyRepeat,
    CharInput,
    MouseMove,
    MousePress,
    MouseRelease,
    MouseWheel,
    
    // Touch events (for future mobile support)
    TouchDown,
    TouchUp,
    TouchMove,
    
    // Custom events
    Custom,
};

pub const KeyEvent = struct {
    key: Platform.Key,
    scancode: u32,
    mods: Platform.KeyMods,
};

pub const CharEvent = struct {
    char: u21,
};

pub const MouseEvent = struct {
    position: Vec2,
    button: Platform.MouseButton,
    mods: Platform.KeyMods,
};

pub const MouseWheelEvent = struct {
    delta: Vec2,
};

pub const WindowResizeEvent = struct {
    width: u32,
    height: u32,
};

pub const WindowMoveEvent = struct {
    x: i32,
    y: i32,
};

pub const TouchEvent = struct {
    id: u32,
    position: Vec2,
    pressure: f32,
};

pub const CustomEvent = struct {
    data: ?*anyopaque,
    type_id: u32,
};

pub const Event = struct {
    type: EventType,
    timestamp: i64,
    
    // Event data union
    key: KeyEvent = undefined,
    char: CharEvent = undefined,
    mouse: MouseEvent = undefined,
    mouse_wheel: MouseWheelEvent = undefined,
    window_resize: WindowResizeEvent = undefined,
    window_move: WindowMoveEvent = undefined,
    touch: TouchEvent = undefined,
    custom: CustomEvent = undefined,

    const Self = @This();

    pub fn initKey(event_type: EventType, key: Platform.Key, scancode: u32, mods: Platform.KeyMods) Self {
        return Self{
            .type = event_type,
            .timestamp = std.time.milliTimestamp(),
            .key = KeyEvent{
                .key = key,
                .scancode = scancode,
                .mods = mods,
            },
        };
    }

    pub fn initChar(char: u21) Self {
        return Self{
            .type = .CharInput,
            .timestamp = std.time.milliTimestamp(),
            .char = CharEvent{
                .char = char,
            },
        };
    }

    pub fn initMouse(event_type: EventType, position: Vec2, button: Platform.MouseButton, mods: Platform.KeyMods) Self {
        return Self{
            .type = event_type,
            .timestamp = std.time.milliTimestamp(),
            .mouse = MouseEvent{
                .position = position,
                .button = button,
                .mods = mods,
            },
        };
    }

    pub fn initMouseWheel(delta: Vec2) Self {
        return Self{
            .type = .MouseWheel,
            .timestamp = std.time.milliTimestamp(),
            .mouse_wheel = MouseWheelEvent{
                .delta = delta,
            },
        };
    }

    pub fn initWindowResize(width: u32, height: u32) Self {
        return Self{
            .type = .WindowResize,
            .timestamp = std.time.milliTimestamp(),
            .window_resize = WindowResizeEvent{
                .width = width,
                .height = height,
            },
        };
    }

    pub fn initWindowMove(x: i32, y: i32) Self {
        return Self{
            .type = .WindowMove,
            .timestamp = std.time.milliTimestamp(),
            .window_move = WindowMoveEvent{
                .x = x,
                .y = y,
            },
        };
    }

    pub fn initTouch(event_type: EventType, id: u32, position: Vec2, pressure: f32) Self {
        return Self{
            .type = event_type,
            .timestamp = std.time.milliTimestamp(),
            .touch = TouchEvent{
                .id = id,
                .position = position,
                .pressure = pressure,
            },
        };
    }

    pub fn initCustom(data: ?*anyopaque, type_id: u32) Self {
        return Self{
            .type = .Custom,
            .timestamp = std.time.milliTimestamp(),
            .custom = CustomEvent{
                .data = data,
                .type_id = type_id,
            },
        };
    }
};