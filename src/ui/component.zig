const std = @import("std");
const Event = @import("../core/events.zig").Event;
const Renderer = @import("../graphics/renderer.zig").Renderer;
const Rect = @import("../math/rect.zig").Rect;
const Vec2 = @import("../math/vec2.zig").Vec2;

pub const ComponentType = enum {
    Panel,
    Button,
    Label,
    TextInput,
    Slider,
    CheckBox,
    ProgressBar,
    ListView,
    TreeView,
    TabView,
    ScrollView,
    Canvas3D,
};

pub const UIComponent = struct {
    allocator: std.mem.Allocator,
    component_type: ComponentType,
    
    // Hierarchy
    parent: ?*UIComponent,
    children: std.ArrayList(*UIComponent),
    
    // Layout and positioning
    bounds: Rect,
    margin: Rect,
    padding: Rect,
    min_size: Vec2,
    max_size: Vec2,
    preferred_size: Vec2,
    
    // State
    visible: bool,
    enabled: bool,
    focused: bool,
    
    // Style
    z_index: i32,
    opacity: f32,
    
    // User data and callbacks
    user_data: ?*anyopaque,
    render_fn: ?*const fn(*UIComponent, *Renderer, f32) anyerror!void,
    event_fn: ?*const fn(*UIComponent, Event) anyerror!void,
    update_fn: ?*const fn(*UIComponent, f32) anyerror!void,
    layout_fn: ?*const fn(*UIComponent, Rect) anyerror!void,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, component_type: ComponentType) !Self {
        return Self{
            .allocator = allocator,
            .component_type = component_type,
            .parent = null,
            .children = std.ArrayList(*UIComponent).init(allocator),
            .bounds = Rect.init(0, 0, 100, 50),
            .margin = Rect.init(0, 0, 0, 0),
            .padding = Rect.init(8, 8, 8, 8),
            .min_size = Vec2.init(0, 0),
            .max_size = Vec2.init(std.math.inf(f32), std.math.inf(f32)),
            .preferred_size = Vec2.init(100, 50),
            .visible = true,
            .enabled = true,
            .focused = false,
            .z_index = 0,
            .opacity = 1.0,
            .user_data = null,
            .render_fn = null,
            .event_fn = null,
            .update_fn = null,
            .layout_fn = null,
        };
    }

    pub fn deinit(self: *Self) void {
        // Remove from parent
        if (self.parent) |parent| {
            parent.removeChild(self);
        }
        
        // Cleanup children
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit();
    }

    pub fn addChild(self: *Self, child: *UIComponent) !void {
        if (child.parent) |old_parent| {
            old_parent.removeChild(child);
        }
        
        try self.children.append(child);
        child.parent = self;
    }

    pub fn removeChild(self: *Self, child: *UIComponent) void {
        for (self.children.items, 0..) |c, i| {
            if (c == child) {
                _ = self.children.swapRemove(i);
                child.parent = null;
                break;
            }
        }
    }

    pub fn setBounds(self: *Self, bounds: Rect) void {
        self.bounds = bounds;
        self.onBoundsChanged();
    }

    pub fn setPosition(self: *Self, position: Vec2) void {
        self.bounds.x = position.x;
        self.bounds.y = position.y;
        self.onBoundsChanged();
    }

    pub fn setSize(self: *Self, size: Vec2) void {
        self.bounds.width = size.x;
        self.bounds.height = size.y;
        self.onBoundsChanged();
    }

    pub fn getPosition(self: *Self) Vec2 {
        return Vec2.init(self.bounds.x, self.bounds.y);
    }

    pub fn getSize(self: *Self) Vec2 {
        return Vec2.init(self.bounds.width, self.bounds.height);
    }

    pub fn getContentBounds(self: *Self) Rect {
        return Rect.init(
            self.bounds.x + self.padding.x,
            self.bounds.y + self.padding.y,
            self.bounds.width - self.padding.x - self.padding.width,
            self.bounds.height - self.padding.y - self.padding.height
        );
    }

    pub fn setVisible(self: *Self, visible: bool) void {
        self.visible = visible;
    }

    pub fn setEnabled(self: *Self, enabled: bool) void {
        self.enabled = enabled;
        // Also update children
        for (self.children.items) |child| {
            child.setEnabled(enabled);
        }
    }

    pub fn setFocused(self: *Self, focused: bool) void {
        self.focused = focused;
    }

    pub fn setOpacity(self: *Self, opacity: f32) void {
        self.opacity = std.math.clamp(opacity, 0.0, 1.0);
    }

    pub fn setZIndex(self: *Self, z_index: i32) void {
        self.z_index = z_index;
        // Resort children by z-index if this component has a parent
        if (self.parent) |parent| {
            parent.sortChildrenByZIndex();
        }
    }

    pub fn bringToFront(self: *Self) void {
        if (self.parent) |parent| {
            var max_z: i32 = std.math.minInt(i32);
            for (parent.children.items) |child| {
                max_z = @max(max_z, child.z_index);
            }
            self.setZIndex(max_z + 1);
        }
    }

    pub fn sendToBack(self: *Self) void {
        if (self.parent) |parent| {
            var min_z: i32 = std.math.maxInt(i32);
            for (parent.children.items) |child| {
                min_z = @min(min_z, child.z_index);
            }
            self.setZIndex(min_z - 1);
        }
    }

    pub fn containsPoint(self: *Self, point: Vec2) bool {
        return self.bounds.containsPoint(point);
    }

    pub fn getChildAt(self: *Self, point: Vec2) ?*UIComponent {
        // Check children in reverse z-index order (front to back)
        var i = self.children.items.len;
        while (i > 0) {
            i -= 1;
            const child = self.children.items[i];
            if (child.visible and child.containsPoint(point)) {
                return child;
            }
        }
        return null;
    }

    pub fn render(self: *Self, renderer: *Renderer, delta_time: f32) !void {
        if (!self.visible or self.opacity <= 0.0) return;

        // Apply opacity to renderer state if needed
        const previous_opacity = renderer.getCurrentOpacity();
        renderer.setOpacity(previous_opacity * self.opacity);
        
        // Render this component
        if (self.render_fn) |render_func| {
            try render_func(self, renderer, delta_time);
        }
        
        // Render children sorted by z-index
        var sorted_children = try self.allocator.alloc(*UIComponent, self.children.items.len);
        defer self.allocator.free(sorted_children);
        
        std.mem.copy(*UIComponent, sorted_children, self.children.items);
        std.sort.sort(*UIComponent, sorted_children, {}, compareZIndex);
        
        for (sorted_children) |child| {
            try child.render(renderer, delta_time);
        }
        
        // Restore previous opacity
        renderer.setOpacity(previous_opacity);
    }

    pub fn update(self: *Self, delta_time: f32) !void {
        if (!self.visible) return;

        // Update this component
        if (self.update_fn) |update_func| {
            try update_func(self, delta_time);
        }
        
        // Update children
        for (self.children.items) |child| {
            try child.update(delta_time);
        }
    }

    pub fn handleEvent(self: *Self, event: Event) !void {
        if (!self.visible or !self.enabled) return;

        // Handle event for this component
        if (self.event_fn) |event_func| {
            try event_func(self, event);
        }
        
        // Propagate to children (in reverse z-index order for mouse events)
        switch (event.type) {
            .MouseMove, .MousePress, .MouseRelease => {
                var i = self.children.items.len;
                while (i > 0) {
                    i -= 1;
                    const child = self.children.items[i];
                    if (child.visible and child.enabled) {
                        try child.handleEvent(event);
                        // Stop propagation if child consumed the event
                        // (This would need additional logic to determine consumption)
                    }
                }
            },
            else => {
                for (self.children.items) |child| {
                    try child.handleEvent(event);
                }
            },
        }
    }

    pub fn layout(self: *Self, available_rect: Rect) !void {
        if (self.layout_fn) |layout_func| {
            try layout_func(self, available_rect);
        } else {
            // Default layout - just use the available rect
            self.setBounds(available_rect);
        }
        
        // Layout children
        const content_bounds = self.getContentBounds();
        for (self.children.items) |child| {
            try child.layout(content_bounds);
        }
    }

    // Private methods
    fn onBoundsChanged(self: *Self) void {
        // Layout children when bounds change
        const content_bounds = self.getContentBounds();
        for (self.children.items) |child| {
            child.layout(content_bounds) catch {};
        }
    }

    fn sortChildrenByZIndex(self: *Self) void {
        std.sort.sort(*UIComponent, self.children.items, {}, compareZIndex);
    }

    fn compareZIndex(_: void, a: *UIComponent, b: *UIComponent) bool {
        return a.z_index < b.z_index;
    }
};

// Extension of Renderer to track opacity
const RendererExtension = struct {
    pub fn getCurrentOpacity(renderer: *Renderer) f32 {
        _ = renderer;
        return 1.0; // This would be properly implemented
    }
    
    pub fn setOpacity(renderer: *Renderer, opacity: f32) void {
        _ = renderer;
        _ = opacity;
        // This would be properly implemented
    }
};