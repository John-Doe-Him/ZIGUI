const std = @import("std");
const Platform = @import("../platform/platform.zig").Platform;
const Event = @import("events.zig").Event;
const Renderer = @import("../graphics/renderer.zig").Renderer;
const UIComponent = @import("../ui/component.zig").UIComponent;
const Layout = @import("../ui/layout.zig").Layout;
const Vec2 = @import("../math/vec2.zig").Vec2;
const Color = @import("../graphics/color.zig").Color;

pub const WindowConfig = struct {
    title: []const u8 = "ZigUI Window",
    width: u32 = 800,
    height: u32 = 600,
    resizable: bool = true,
    fullscreen: bool = false,
    vsync: bool = true,
    multisampling: u8 = 4,
};

pub const Window = struct {
    allocator: std.mem.Allocator,
    handle: Platform.WindowHandle,
    config: WindowConfig,
    visible: bool,
    focused: bool,
    width: u32,
    height: u32,
    position: Vec2,
    root_component: *UIComponent,
    layout: *Layout,
    background_color: Color,
    application: ?*@import("application.zig").Application,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, config: WindowConfig) !*Self {
        var window = try allocator.create(Self);
        
        const handle = try Platform.createWindow(config);
        const root = try UIComponent.init(allocator, .Panel);
        const layout = try Layout.init(allocator, .Flex);

        window.* = Self{
            .allocator = allocator,
            .handle = handle,
            .config = config,
            .visible = false,
            .focused = false,
            .width = config.width,
            .height = config.height,
            .position = Vec2.init(0, 0),
            .root_component = root,
            .layout = layout,
            .background_color = Color.init(0.95, 0.95, 0.95, 1.0),
            .application = null,
        };

        try Platform.setWindowUserData(handle, window);
        return window;
    }

    pub fn deinit(self: *Self) void {
        self.root_component.deinit();
        self.layout.deinit();
        Platform.destroyWindow(self.handle);
        self.allocator.destroy(self);
    }

    pub fn show(self: *Self) !void {
        try Platform.showWindow(self.handle);
        self.visible = true;
    }

    pub fn hide(self: *Self) !void {
        try Platform.hideWindow(self.handle);
        self.visible = false;
    }

    pub fn close(self: *Self) void {
        self.visible = false;
    }

    pub fn setTitle(self: *Self, title: []const u8) !void {
        try Platform.setWindowTitle(self.handle, title);
        self.config.title = title;
    }

    pub fn setSize(self: *Self, width: u32, height: u32) !void {
        try Platform.setWindowSize(self.handle, width, height);
        self.width = width;
        self.height = height;
        try self.updateLayout();
    }

    pub fn setPosition(self: *Self, x: i32, y: i32) !void {
        try Platform.setWindowPosition(self.handle, x, y);
        self.position = Vec2.init(@floatFromInt(x), @floatFromInt(y));
    }

    pub fn center(self: *Self) !void {
        const screen_size = try Platform.getScreenSize();
        const x = @as(i32, @intFromFloat(screen_size.x / 2.0 - @as(f32, @floatFromInt(self.width)) / 2.0));
        const y = @as(i32, @intFromFloat(screen_size.y / 2.0 - @as(f32, @floatFromInt(self.height)) / 2.0));
        try self.setPosition(x, y);
    }

    pub fn setFullscreen(self: *Self, fullscreen: bool) !void {
        try Platform.setWindowFullscreen(self.handle, fullscreen);
        self.config.fullscreen = fullscreen;
    }

    pub fn addComponent(self: *Self, component: *UIComponent) !void {
        try self.root_component.addChild(component);
        try self.updateLayout();
    }

    pub fn removeComponent(self: *Self, component: *UIComponent) !void {
        self.root_component.removeChild(component);
        try self.updateLayout();
    }

    pub fn setBackgroundColor(self: *Self, color: Color) void {
        self.background_color = color;
    }

    pub fn pollEvents(self: *Self) !std.ArrayList(Event) {
        return Platform.pollWindowEvents(self.handle);
    }

    pub fn handleEvent(self: *Self, event: Event) !void {
        try self.root_component.handleEvent(event);
    }

    pub fn handleResize(self: *Self, width: u32, height: u32) !void {
        self.width = width;
        self.height = height;
        try self.updateLayout();
    }

    pub fn render(self: *Self, renderer: *Renderer, delta_time: f32) !void {
        // Clear background
        try renderer.clear(self.background_color);
        
        // Set viewport
        try renderer.setViewport(0, 0, self.width, self.height);
        
        // Render UI components
        try self.root_component.render(renderer, delta_time);
        
        // Present frame
        try Platform.swapBuffers(self.handle);
    }

    pub fn getMousePosition(self: *Self) Vec2 {
        return Platform.getMousePosition(self.handle);
    }

    pub fn isKeyPressed(self: *Self, key: Platform.Key) bool {
        return Platform.isKeyPressed(self.handle, key);
    }

    pub fn isMouseButtonPressed(self: *Self, button: Platform.MouseButton) bool {
        return Platform.isMouseButtonPressed(self.handle, button);
    }

    fn updateLayout(self: *Self) !void {
        const window_rect = @import("../math/rect.zig").Rect.init(
            0, 0, 
            @floatFromInt(self.width), 
            @floatFromInt(self.height)
        );
        try self.layout.calculate(self.root_component, window_rect);
    }
};