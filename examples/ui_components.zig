const std = @import("std");
const zigui = @import("../src/zigui.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try zigui.init(allocator);
    defer zigui.deinit();

    var app = try zigui.Application.init(allocator);
    defer app.deinit();

    const window_config = zigui.Window.WindowConfig{
        .title = "ZigUI Components Demo",
        .width = 1000,
        .height = 700,
        .resizable = true,
    };
    
    var window = try zigui.Window.init(allocator, window_config);
    defer window.deinit();

    try window.center();
    try window.show();
    try app.addWindow(window);

    // Create various UI components
    try createComponents(allocator, window);

    std.log.info("Starting ZigUI Components Demo...");
    try app.run();
}

fn createComponents(allocator: std.mem.Allocator, window: *zigui.Window) !void {
    // Title label
    var title_label = try zigui.Label.init(allocator, "ZigUI Components Showcase");
    defer title_label.deinit();
    title_label.component.setBounds(zigui.Rect.init(20, 20, 400, 40));
    try window.addComponent(&title_label.component);

    // Buttons section
    var button_label = try zigui.Label.init(allocator, "Buttons:");
    defer button_label.deinit();
    button_label.component.setBounds(zigui.Rect.init(20, 80, 100, 30));
    try window.addComponent(&button_label.component);

    var primary_button = try zigui.Button.init(allocator, "Primary");
    defer primary_button.deinit();
    primary_button.component.setBounds(zigui.Rect.init(20, 110, 100, 35));
    primary_button.setOnClick(onPrimaryClick);
    try window.addComponent(&primary_button.component);

    var secondary_button = try zigui.Button.init(allocator, "Secondary");
    defer secondary_button.deinit();
    secondary_button.component.setBounds(zigui.Rect.init(130, 110, 100, 35));
    secondary_button.setOnClick(onSecondaryClick);
    try window.addComponent(&secondary_button.component);

    // Text input section
    var input_label = try zigui.Label.init(allocator, "Text Input:");
    defer input_label.deinit();
    input_label.component.setBounds(zigui.Rect.init(20, 170, 100, 30));
    try window.addComponent(&input_label.component);

    var text_input = try zigui.TextInput.init(allocator, "Enter text here...");
    defer text_input.deinit();
    text_input.component.setBounds(zigui.Rect.init(20, 200, 200, 30));
    try window.addComponent(&text_input.component);

    // Checkbox section
    var checkbox_label = try zigui.Label.init(allocator, "Options:");
    defer checkbox_label.deinit();
    checkbox_label.component.setBounds(zigui.Rect.init(20, 250, 100, 30));
    try window.addComponent(&checkbox_label.component);

    var checkbox1 = try zigui.CheckBox.init(allocator, "Enable notifications");
    defer checkbox1.deinit();
    checkbox1.component.setBounds(zigui.Rect.init(20, 280, 200, 25));
    try window.addComponent(&checkbox1.component);

    var checkbox2 = try zigui.CheckBox.init(allocator, "Dark mode");
    defer checkbox2.deinit();
    checkbox2.component.setBounds(zigui.Rect.init(20, 310, 200, 25));
    try window.addComponent(&checkbox2.component);

    // Slider section
    var slider_label = try zigui.Label.init(allocator, "Volume:");
    defer slider_label.deinit();
    slider_label.component.setBounds(zigui.Rect.init(20, 350, 100, 30));
    try window.addComponent(&slider_label.component);

    var volume_slider = try zigui.Slider.init(allocator, 0.0, 100.0, 50.0);
    defer volume_slider.deinit();
    volume_slider.component.setBounds(zigui.Rect.init(20, 380, 200, 20));
    try window.addComponent(&volume_slider.component);

    // Progress bar section
    var progress_label = try zigui.Label.init(allocator, "Progress:");
    defer progress_label.deinit();
    progress_label.component.setBounds(zigui.Rect.init(20, 420, 100, 30));
    try window.addComponent(&progress_label.component);

    var progress_bar = try zigui.ProgressBar.init(allocator, 0.0, 100.0);
    defer progress_bar.deinit();
    progress_bar.component.setBounds(zigui.Rect.init(20, 450, 200, 20));
    progress_bar.setValue(75.0);
    try window.addComponent(&progress_bar.component);

    // List view section
    var list_label = try zigui.Label.init(allocator, "List:");
    defer list_label.deinit();
    list_label.component.setBounds(zigui.Rect.init(300, 80, 100, 30));
    try window.addComponent(&list_label.component);

    var list_view = try zigui.ListView.init(allocator);
    defer list_view.deinit();
    list_view.component.setBounds(zigui.Rect.init(300, 110, 200, 150));
    try list_view.addItem("Item 1");
    try list_view.addItem("Item 2");
    try list_view.addItem("Item 3");
    try list_view.addItem("Item 4");
    try window.addComponent(&list_view.component);

    // Tab view section
    var tab_view = try zigui.TabView.init(allocator);
    defer tab_view.deinit();
    tab_view.component.setBounds(zigui.Rect.init(520, 80, 300, 200));
    try tab_view.addTab("General", null);
    try tab_view.addTab("Advanced", null);
    try tab_view.addTab("About", null);
    try window.addComponent(&tab_view.component);
}

fn onPrimaryClick(button: *zigui.Button) void {
    _ = button;
    std.log.info("Primary button clicked!");
}

fn onSecondaryClick(button: *zigui.Button) void {
    _ = button;
    std.log.info("Secondary button clicked!");
}