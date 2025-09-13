// ZigUI - Native Zig UI Library
// Main library entry point

pub const Window = @import("core/window.zig").Window;
pub const Application = @import("core/application.zig").Application;
pub const Event = @import("core/events.zig").Event;
pub const EventType = @import("core/events.zig").EventType;
pub const Renderer = @import("graphics/renderer.zig").Renderer;
pub const Color = @import("graphics/color.zig").Color;
pub const Font = @import("graphics/font.zig").Font;
pub const Texture = @import("graphics/texture.zig").Texture;

// UI Components
pub const Button = @import("ui/button.zig").Button;
pub const Label = @import("ui/label.zig").Label;
pub const TextInput = @import("ui/text_input.zig").TextInput;
pub const Panel = @import("ui/panel.zig").Panel;
pub const Slider = @import("ui/slider.zig").Slider;
pub const CheckBox = @import("ui/checkbox.zig").CheckBox;
pub const ProgressBar = @import("ui/progress_bar.zig").ProgressBar;
pub const ListView = @import("ui/list_view.zig").ListView;
pub const TreeView = @import("ui/tree_view.zig").TreeView;
pub const TabView = @import("ui/tab_view.zig").TabView;

// Layout System
pub const Layout = @import("ui/layout.zig").Layout;
pub const LayoutType = @import("ui/layout.zig").LayoutType;
pub const FlexLayout = @import("ui/layout.zig").FlexLayout;
pub const GridLayout = @import("ui/layout.zig").GridLayout;

// Animation System
pub const Animation = @import("animation/animation.zig").Animation;
pub const Tween = @import("animation/tween.zig").Tween;
pub const Timeline = @import("animation/timeline.zig").Timeline;
pub const Easing = @import("animation/easing.zig").Easing;

// 3D Graphics
pub const Scene3D = @import("graphics/3d/scene.zig").Scene3D;
pub const Camera3D = @import("graphics/3d/camera.zig").Camera3D;
pub const Mesh3D = @import("graphics/3d/mesh.zig").Mesh3D;
pub const Material3D = @import("graphics/3d/material.zig").Material3D;

// Math utilities
pub const Vec2 = @import("math/vec2.zig").Vec2;
pub const Vec3 = @import("math/vec3.zig").Vec3;
pub const Vec4 = @import("math/vec4.zig").Vec4;
pub const Mat4 = @import("math/mat4.zig").Mat4;
pub const Rect = @import("math/rect.zig").Rect;

// Platform abstraction
pub const Platform = @import("platform/platform.zig").Platform;

// Memory management
pub const Allocator = @import("std").mem.Allocator;

// Version information
pub const version = .{
    .major = 1,
    .minor = 0,
    .patch = 0,
};

// Library initialization
pub fn init(allocator: Allocator) !void {
    try Platform.init(allocator);
}

pub fn deinit() void {
    Platform.deinit();
}

// Export tests
test {
    @import("std").testing.refAllDecls(@This());
}