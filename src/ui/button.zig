const std = @import("std");
const UIComponent = @import("component.zig").UIComponent;
const ComponentType = @import("component.zig").ComponentType;
const Event = @import("../core/events.zig").Event;
const EventType = @import("../core/events.zig").EventType;
const Renderer = @import("../graphics/renderer.zig").Renderer;
const Color = @import("../graphics/color.zig").Color;
const Vec2 = @import("../math/vec2.zig").Vec2;
const Rect = @import("../math/rect.zig").Rect;
const Animation = @import("../animation/animation.zig").Animation;
const Tween = @import("../animation/tween.zig").Tween;
const Easing = @import("../animation/easing.zig").Easing;

pub const ButtonState = enum {
    Normal,
    Hovered,
    Pressed,
    Disabled,
};

pub const ButtonStyle = struct {
    normal_color: Color = Color.initRGBA(0x6200EAFF),
    hover_color: Color = Color.initRGBA(0x3700B3FF),
    pressed_color: Color = Color.initRGBA(0x03DAC6FF),
    disabled_color: Color = Color.initRGBA(0x808080FF),
    text_color: Color = Color.WHITE,
    border_radius: f32 = 8.0,
    padding: Vec2 = Vec2.init(16, 8),
    font_size: f32 = 14.0,
};

pub const Button = struct {
    component: UIComponent,
    text: []const u8,
    style: ButtonStyle,
    state: ButtonState,
    on_click: ?*const fn(*Button) void,
    
    // Animation
    hover_animation: ?*Animation,
    press_animation: ?*Animation,
    current_color: Color,
    target_color: Color,
    
    // Internal state
    is_mouse_inside: bool,
    was_pressed: bool,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, text: []const u8) !*Self {
        var button = try allocator.create(Self);
        
        button.* = Self{
            .component = try UIComponent.init(allocator, .Button),
            .text = try allocator.dupe(u8, text),
            .style = ButtonStyle{},
            .state = .Normal,
            .on_click = null,
            .hover_animation = null,
            .press_animation = null,
            .current_color = ButtonStyle{}.normal_color,
            .target_color = ButtonStyle{}.normal_color,
            .is_mouse_inside = false,
            .was_pressed = false,
        };

        button.component.user_data = button;
        button.component.render_fn = renderButton;
        button.component.event_fn = handleButtonEvent;
        button.component.update_fn = updateButton;

        // Setup animations
        try button.setupAnimations(allocator);

        return button;
    }

    pub fn deinit(self: *Self) void {
        if (self.hover_animation) |anim| anim.deinit();
        if (self.press_animation) |anim| anim.deinit();
        self.component.allocator.free(self.text);
        self.component.deinit();
        self.component.allocator.destroy(self);
    }

    pub fn setText(self: *Self, text: []const u8) !void {
        self.component.allocator.free(self.text);
        self.text = try self.component.allocator.dupe(u8, text);
    }

    pub fn setStyle(self: *Self, style: ButtonStyle) void {
        self.style = style;
        self.updateTargetColor();
    }

    pub fn setOnClick(self: *Self, callback: *const fn(*Button) void) void {
        self.on_click = callback;
    }

    pub fn setState(self: *Self, state: ButtonState) void {
        if (self.state != state) {
            self.state = state;
            self.updateTargetColor();
            self.startColorAnimation();
        }
    }

    pub fn setEnabled(self: *Self, enabled: bool) void {
        self.setState(if (enabled) .Normal else .Disabled);
    }

    pub fn isEnabled(self: *Self) bool {
        return self.state != .Disabled;
    }

    pub fn click(self: *Self) void {
        if (self.isEnabled() and self.on_click != null) {
            self.on_click.?(self);
        }
    }

    fn setupAnimations(self: *Self, allocator: std.mem.Allocator) !void {
        // Hover animation
        self.hover_animation = try Animation.init(allocator, 0.15);
        self.hover_animation.?.easing = .EaseOut;
        
        // Press animation  
        self.press_animation = try Animation.init(allocator, 0.1);
        self.press_animation.?.easing = .EaseOut;
    }

    fn updateTargetColor(self: *Self) void {
        self.target_color = switch (self.state) {
            .Normal => self.style.normal_color,
            .Hovered => self.style.hover_color,
            .Pressed => self.style.pressed_color,
            .Disabled => self.style.disabled_color,
        };
    }

    fn startColorAnimation(self: *Self) void {
        if (self.hover_animation) |anim| {
            anim.reset();
            anim.start();
        }
    }

    fn renderButton(component: *UIComponent, renderer: *Renderer, delta_time: f32) !void {
        _ = delta_time;
        const self: *Self = @ptrCast(@alignCast(component.user_data));
        
        const bounds = component.bounds;
        
        // Draw button background with rounded corners
        try renderer.drawRect(bounds, self.current_color);
        
        // Draw border if needed
        if (self.state == .Hovered or self.state == .Pressed) {
            const border_color = self.current_color.withAlpha(0.3);
            const border_thickness: f32 = 2.0;
            
            // Top border
            try renderer.drawRect(
                Rect.init(bounds.x, bounds.y, bounds.width, border_thickness),
                border_color
            );
            // Bottom border  
            try renderer.drawRect(
                Rect.init(bounds.x, bounds.y + bounds.height - border_thickness, bounds.width, border_thickness),
                border_color
            );
            // Left border
            try renderer.drawRect(
                Rect.init(bounds.x, bounds.y, border_thickness, bounds.height),
                border_color
            );
            // Right border
            try renderer.drawRect(
                Rect.init(bounds.x + bounds.width - border_thickness, bounds.y, border_thickness, bounds.height),
                border_color
            );
        }
        
        // Draw text centered
        const text_pos = Vec2.init(
            bounds.x + bounds.width / 2.0 - (@as(f32, @floatFromInt(self.text.len)) * self.style.font_size * 0.3),
            bounds.y + bounds.height / 2.0 - self.style.font_size / 2.0
        );
        
        try renderer.drawText(self.text, text_pos, self.style.text_color);
    }

    fn handleButtonEvent(component: *UIComponent, event: Event) !void {
        const self: *Self = @ptrCast(@alignCast(component.user_data));
        
        if (!self.isEnabled()) return;
        
        switch (event.type) {
            .MouseMove => {
                const mouse_pos = event.mouse.position;
                const was_inside = self.is_mouse_inside;
                self.is_mouse_inside = component.bounds.containsPoint(mouse_pos);
                
                if (self.is_mouse_inside and !was_inside) {
                    // Mouse entered
                    if (self.state == .Normal) {
                        self.setState(.Hovered);
                    }
                } else if (!self.is_mouse_inside and was_inside) {
                    // Mouse exited
                    if (self.state == .Hovered) {
                        self.setState(.Normal);
                    } else if (self.state == .Pressed) {
                        self.setState(.Normal);
                        self.was_pressed = false;
                    }
                }
            },
            .MousePress => {
                if (event.mouse.button == .Left and self.is_mouse_inside) {
                    self.setState(.Pressed);
                    self.was_pressed = true;
                }
            },
            .MouseRelease => {
                if (event.mouse.button == .Left) {
                    if (self.was_pressed and self.is_mouse_inside) {
                        // Button clicked
                        self.click();
                        self.setState(.Hovered);
                    } else if (self.state == .Pressed) {
                        self.setState(if (self.is_mouse_inside) .Hovered else .Normal);
                    }
                    self.was_pressed = false;
                }
            },
            else => {},
        }
    }

    fn updateButton(component: *UIComponent, delta_time: f32) !void {
        const self: *Self = @ptrCast(@alignCast(component.user_data));
        
        // Update color animation
        if (self.hover_animation) |anim| {
            anim.update(delta_time);
            if (anim.is_playing) {
                self.current_color = self.current_color.lerp(self.target_color, anim.getValue());
            } else {
                self.current_color = self.target_color;
            }
        }
    }
};