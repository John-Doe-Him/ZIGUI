const std = @import("std");
const zigui = @import("../src/zigui.zig");

var animated_button: ?*zigui.Button = null;
var bounce_animation: ?*zigui.Animation = null;
var color_animation: ?*zigui.Animation = null;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try zigui.init(allocator);
    defer zigui.deinit();

    var app = try zigui.Application.init(allocator);
    defer app.deinit();

    const window_config = zigui.Window.WindowConfig{
        .title = "ZigUI Animations Demo",
        .width = 900,
        .height = 600,
        .resizable = true,
    };
    
    var window = try zigui.Window.init(allocator, window_config);
    defer window.deinit();

    try window.center();
    try window.show();
    try app.addWindow(window);

    // Create animated components
    try createAnimatedComponents(allocator, window);

    std.log.info("Starting ZigUI Animations Demo...");
    try app.run();
}

fn createAnimatedComponents(allocator: std.mem.Allocator, window: *zigui.Window) !void {
    // Title
    var title_label = try zigui.Label.init(allocator, "ZigUI Animation Showcase");
    defer title_label.deinit();
    title_label.component.setBounds(zigui.Rect.init(20, 20, 400, 40));
    try window.addComponent(&title_label.component);

    // Animated button
    animated_button = try zigui.Button.init(allocator, "Animated Button");
    animated_button.?.component.setBounds(zigui.Rect.init(50, 100, 150, 50));
    animated_button.?.setOnClick(onAnimatedButtonClick);
    try window.addComponent(&animated_button.?.component);

    // Bounce animation
    bounce_animation = try zigui.Animation.init(allocator, 1.0);
    bounce_animation.?.setEasing(.EaseOutBounce);
    bounce_animation.?.setLoop(true);
    bounce_animation.?.setOnUpdate(onBounceUpdate);

    // Color animation
    color_animation = try zigui.Animation.init(allocator, 2.0);
    color_animation.?.setEasing(.EaseInOut);
    color_animation.?.setLoop(true);
    color_animation.?.setPingPong(true);
    color_animation.?.setOnUpdate(onColorUpdate);

    // Start animations
    bounce_animation.?.start();
    color_animation.?.start();

    // Easing demonstration buttons
    try createEasingDemo(allocator, window);

    // Animated progress bar
    try createAnimatedProgressBar(allocator, window);

    // Particle system demo
    try createParticleDemo(allocator, window);
}

fn createEasingDemo(allocator: std.mem.Allocator, window: *zigui.Window) !void {
    var easing_label = try zigui.Label.init(allocator, "Easing Functions:");
    defer easing_label.deinit();
    easing_label.component.setBounds(zigui.Rect.init(250, 80, 200, 30));
    try window.addComponent(&easing_label.component);

    const easings = [_]struct { name: []const u8, easing: zigui.Easing.Function }{
        .{ .name = "Linear", .easing = .Linear },
        .{ .name = "Ease In", .easing = .EaseIn },
        .{ .name = "Ease Out", .easing = .EaseOut },
        .{ .name = "Ease In-Out", .easing = .EaseInOut },
        .{ .name = "Bounce", .easing = .EaseOutBounce },
        .{ .name = "Elastic", .easing = .EaseOutElastic },
        .{ .name = "Back", .easing = .EaseOutBack },
    };

    for (easings, 0..) |easing_info, i| {
        var button = try zigui.Button.init(allocator, easing_info.name);
        defer button.deinit();
        
        const row = i / 3;
        const col = i % 3;
        const x = 250 + @as(f32, @floatFromInt(col)) * 120;
        const y = 110 + @as(f32, @floatFromInt(row)) * 45;
        
        button.component.setBounds(zigui.Rect.init(x, y, 110, 35));
        try window.addComponent(&button.component);
    }
}

fn createAnimatedProgressBar(allocator: std.mem.Allocator, window: *zigui.Window) !void {
    var progress_label = try zigui.Label.init(allocator, "Animated Progress:");
    defer progress_label.deinit();
    progress_label.component.setBounds(zigui.Rect.init(50, 300, 200, 30));
    try window.addComponent(&progress_label.component);

    var progress_bar = try zigui.ProgressBar.init(allocator, 0.0, 100.0);
    defer progress_bar.deinit();
    progress_bar.component.setBounds(zigui.Rect.init(50, 330, 300, 25));
    try window.addComponent(&progress_bar.component);

    // Animate progress bar
    var progress_animation = try zigui.Animation.init(allocator, 3.0);
    defer progress_animation.deinit();
    progress_animation.setEasing(.EaseInOut);
    progress_animation.setLoop(true);
    progress_animation.setPingPong(true);
    progress_animation.start();
}

fn createParticleDemo(allocator: std.mem.Allocator, window: *zigui.Window) !void {
    var particle_label = try zigui.Label.init(allocator, "Particle System:");
    defer particle_label.deinit();
    particle_label.component.setBounds(zigui.Rect.init(50, 400, 200, 30));
    try window.addComponent(&particle_label.component);

    // Create particle emitter button
    var particle_button = try zigui.Button.init(allocator, "Emit Particles");
    defer particle_button.deinit();
    particle_button.component.setBounds(zigui.Rect.init(50, 430, 150, 40));
    particle_button.setOnClick(onEmitParticles);
    try window.addComponent(&particle_button.component);

    // Create particle canvas
    var particle_canvas = try zigui.Panel.init(allocator);
    defer particle_canvas.deinit();
    particle_canvas.component.setBounds(zigui.Rect.init(220, 400, 300, 150));
    try window.addComponent(&particle_canvas.component);
}

fn onAnimatedButtonClick(button: *zigui.Button) void {
    _ = button;
    std.log.info("Animated button clicked! Playing special animation...");
    
    if (bounce_animation) |anim| {
        anim.reset();
        anim.start();
    }
}

fn onBounceUpdate(animation: *zigui.Animation, value: f32) void {
    _ = animation;
    
    if (animated_button) |button| {
        const base_y: f32 = 100;
        const bounce_height: f32 = 30;
        const new_y = base_y - (value * bounce_height);
        
        var bounds = button.component.bounds;
        bounds.y = new_y;
        button.component.setBounds(bounds);
    }
}

fn onColorUpdate(animation: *zigui.Animation, value: f32) void {
    _ = animation;
    
    if (animated_button) |button| {
        // Animate through different colors
        const hue = value * 360.0;
        const color = zigui.Color.initHSV(hue, 0.8, 0.9);
        
        var style = button.style;
        style.normal_color = color;
        style.hover_color = color.multiply(zigui.Color.initRGB(0.8, 0.8, 0.8));
        button.setStyle(style);
    }
}

fn onEmitParticles(button: *zigui.Button) void {
    _ = button;
    std.log.info("Emitting particles!");
    // Implementation would create particle effects
}