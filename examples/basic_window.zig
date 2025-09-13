const std = @import("std");
const zigui = @import("../src/zigui.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize ZigUI
    try zigui.init(allocator);
    defer zigui.deinit();

    // Create application
    var app = try zigui.Application.init(allocator);
    defer app.deinit();

    // Create window
    const window_config = zigui.Window.WindowConfig{
        .title = "ZigUI Basic Window",
        .width = 800,
        .height = 600,
        .resizable = true,
    };
    
    var window = try zigui.Window.init(allocator, window_config);
    defer window.deinit();

    try window.center();
    try window.show();
    try app.addWindow(window);

    // Set background color
    window.setBackgroundColor(zigui.Color.initRGB(0.95, 0.95, 0.95));

    // Create a simple label
    var label = try zigui.Label.init(allocator, "Welcome to ZigUI!");
    defer label.deinit();
    
    label.component.setBounds(zigui.Rect.init(50, 50, 200, 30));
    try window.addComponent(&label.component);

    // Create a button
    var button = try zigui.Button.init(allocator, "Click Me!");
    defer button.deinit();
    
    button.component.setBounds(zigui.Rect.init(50, 100, 100, 40));
    button.setOnClick(buttonClicked);
    try window.addComponent(&button.component);

    std.log.info("Starting ZigUI Basic Window Example...");
    try app.run();
}

fn buttonClicked(button: *zigui.Button) void {
    _ = button;
    std.log.info("Button was clicked!");
}