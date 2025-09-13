const std = @import("std");
const zigui = @import("../src/zigui.zig");

var scene: ?*zigui.Scene3D = null;
var camera: ?*zigui.Camera3D = null;
var rotating_cube: ?*zigui.Mesh3D = null;
var rotation_angle: f32 = 0.0;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try zigui.init(allocator);
    defer zigui.deinit();

    var app = try zigui.Application.init(allocator);
    defer app.deinit();

    const window_config = zigui.Window.WindowConfig{
        .title = "ZigUI 3D Demo",
        .width = 1024,
        .height = 768,
        .resizable = true,
    };
    
    var window = try zigui.Window.init(allocator, window_config);
    defer window.deinit();

    try window.center();
    try window.show();
    try app.addWindow(window);

    // Initialize 3D scene
    try setup3DScene(allocator, window);

    // Create UI controls
    try create3DControls(allocator, window);

    std.log.info("Starting ZigUI 3D Demo...");
    try app.run();
}

fn setup3DScene(allocator: std.mem.Allocator, window: *zigui.Window) !void {
    // Create 3D scene
    scene = try zigui.Scene3D.init(allocator);
    
    // Create camera
    camera = try zigui.Camera3D.init(allocator);
    camera.?.setPosition(zigui.Vec3.init(0, 0, 5));
    camera.?.setTarget(zigui.Vec3.init(0, 0, 0));
    camera.?.setFOV(60.0);
    camera.?.setNearFar(0.1, 100.0);
    
    scene.?.setCamera(camera.?);

    // Create rotating cube mesh
    rotating_cube = try zigui.Mesh3D.createCube(allocator, zigui.Vec3.init(1, 1, 1));
    
    // Set cube material
    var material = try zigui.Material3D.init(allocator);
    material.setDiffuseColor(zigui.Color.initRGB(0.8, 0.2, 0.2));
    material.setSpecularColor(zigui.Color.WHITE);
    material.setShininess(32.0);
    rotating_cube.?.setMaterial(material);
    
    try scene.?.addMesh(rotating_cube.?);

    // Create additional 3D objects
    try createAdditional3DObjects(allocator);

    // Setup lighting
    scene.?.addLight(zigui.Vec3.init(2, 2, 2), zigui.Color.WHITE, 1.0);
    scene.?.setAmbientLight(zigui.Color.initRGB(0.2, 0.2, 0.2));

    // Create 3D canvas component for the window
    var canvas_3d = try create3DCanvas(allocator);
    canvas_3d.component.setBounds(zigui.Rect.init(200, 50, 800, 600));
    try window.addComponent(&canvas_3d.component);
}

fn createAdditional3DObjects(allocator: std.mem.Allocator) !void {
    // Create a sphere
    var sphere = try zigui.Mesh3D.createSphere(allocator, 0.8, 16, 16);
    sphere.setPosition(zigui.Vec3.init(-3, 0, 0));
    
    var sphere_material = try zigui.Material3D.init(allocator);
    sphere_material.setDiffuseColor(zigui.Color.initRGB(0.2, 0.8, 0.2));
    sphere.setMaterial(sphere_material);
    
    try scene.?.addMesh(sphere);

    // Create a pyramid
    var pyramid = try zigui.Mesh3D.createPyramid(allocator, 1.5, 2.0);
    pyramid.setPosition(zigui.Vec3.init(3, 0, 0));
    
    var pyramid_material = try zigui.Material3D.init(allocator);
    pyramid_material.setDiffuseColor(zigui.Color.initRGB(0.2, 0.2, 0.8));
    pyramid.setMaterial(pyramid_material);
    
    try scene.?.addMesh(pyramid);

    // Create a plane for the ground
    var ground = try zigui.Mesh3D.createPlane(allocator, 10, 10);
    ground.setPosition(zigui.Vec3.init(0, -2, 0));
    ground.setRotation(zigui.Vec3.init(90, 0, 0));
    
    var ground_material = try zigui.Material3D.init(allocator);
    ground_material.setDiffuseColor(zigui.Color.initRGB(0.7, 0.7, 0.7));
    ground.setMaterial(ground_material);
    
    try scene.?.addMesh(ground);
}

fn create3DCanvas(allocator: std.mem.Allocator) !*Canvas3D {
    // This would be a custom component that renders the 3D scene
    var canvas = try Canvas3D.init(allocator);
    canvas.setScene(scene.?);
    canvas.setUpdateCallback(update3DScene);
    return canvas;
}

fn create3DControls(allocator: std.mem.Allocator, window: *zigui.Window) !void {
    // Title
    var title_label = try zigui.Label.init(allocator, "3D Scene Controls");
    defer title_label.deinit();
    title_label.component.setBounds(zigui.Rect.init(20, 20, 200, 30));
    try window.addComponent(&title_label.component);

    // Camera controls
    var camera_label = try zigui.Label.init(allocator, "Camera:");
    defer camera_label.deinit();
    camera_label.component.setBounds(zigui.Rect.init(20, 60, 100, 25));
    try window.addComponent(&camera_label.component);

    var reset_camera_btn = try zigui.Button.init(allocator, "Reset Camera");
    defer reset_camera_btn.deinit();
    reset_camera_btn.component.setBounds(zigui.Rect.init(20, 90, 120, 30));
    reset_camera_btn.setOnClick(onResetCamera);
    try window.addComponent(&reset_camera_btn.component);

    // Animation controls
    var animation_label = try zigui.Label.init(allocator, "Animation:");
    defer animation_label.deinit();
    animation_label.component.setBounds(zigui.Rect.init(20, 140, 100, 25));
    try window.addComponent(&animation_label.component);

    var pause_btn = try zigui.Button.init(allocator, "Pause/Play");
    defer pause_btn.deinit();
    pause_btn.component.setBounds(zigui.Rect.init(20, 170, 100, 30));
    pause_btn.setOnClick(onPauseAnimation);
    try window.addComponent(&pause_btn.component);

    // Speed slider
    var speed_label = try zigui.Label.init(allocator, "Speed:");
    defer speed_label.deinit();
    speed_label.component.setBounds(zigui.Rect.init(20, 220, 60, 25));
    try window.addComponent(&speed_label.component);

    var speed_slider = try zigui.Slider.init(allocator, 0.1, 3.0, 1.0);
    defer speed_slider.deinit();
    speed_slider.component.setBounds(zigui.Rect.init(20, 250, 150, 20));
    speed_slider.setOnValueChanged(onSpeedChanged);
    try window.addComponent(&speed_slider.component);

    // Wireframe toggle
    var wireframe_checkbox = try zigui.CheckBox.init(allocator, "Wireframe Mode");
    defer wireframe_checkbox.deinit();
    wireframe_checkbox.component.setBounds(zigui.Rect.init(20, 290, 150, 25));
    wireframe_checkbox.setOnToggle(onWireframeToggle);
    try window.addComponent(&wireframe_checkbox.component);

    // Lighting controls
    var lighting_label = try zigui.Label.init(allocator, "Lighting:");
    defer lighting_label.deinit();
    lighting_label.component.setBounds(zigui.Rect.init(20, 330, 100, 25));
    try window.addComponent(&lighting_label.component);

    var light_intensity_slider = try zigui.Slider.init(allocator, 0.0, 2.0, 1.0);
    defer light_intensity_slider.deinit();
    light_intensity_slider.component.setBounds(zigui.Rect.init(20, 360, 150, 20));
    light_intensity_slider.setOnValueChanged(onLightIntensityChanged);
    try window.addComponent(&light_intensity_slider.component);

    // Material controls
    var material_label = try zigui.Label.init(allocator, "Materials:");
    defer material_label.deinit();
    material_label.component.setBounds(zigui.Rect.init(20, 400, 100, 25));
    try window.addComponent(&material_label.component);

    var red_material_btn = try zigui.Button.init(allocator, "Red");
    defer red_material_btn.deinit();
    red_material_btn.component.setBounds(zigui.Rect.init(20, 430, 50, 30));
    red_material_btn.setOnClick(onRedMaterial);
    try window.addComponent(&red_material_btn.component);

    var green_material_btn = try zigui.Button.init(allocator, "Green");
    defer green_material_btn.deinit();
    green_material_btn.component.setBounds(zigui.Rect.init(80, 430, 50, 30));
    green_material_btn.setOnClick(onGreenMaterial);
    try window.addComponent(&green_material_btn.component);

    var blue_material_btn = try zigui.Button.init(allocator, "Blue");
    defer blue_material_btn.deinit();
    blue_material_btn.component.setBounds(zigui.Rect.init(140, 430, 50, 30));
    blue_material_btn.setOnClick(onBlueMaterial);
    try window.addComponent(&blue_material_btn.component);

    // Performance stats
    var stats_label = try zigui.Label.init(allocator, "Stats: FPS: 60 | Triangles: 1024");
    defer stats_label.deinit();
    stats_label.component.setBounds(zigui.Rect.init(20, 500, 170, 25));
    try window.addComponent(&stats_label.component);
}

fn update3DScene(delta_time: f32) void {
    // Rotate the cube
    rotation_angle += delta_time * 45.0; // 45 degrees per second
    if (rotation_angle > 360.0) rotation_angle -= 360.0;
    
    if (rotating_cube) |cube| {
        cube.setRotation(zigui.Vec3.init(rotation_angle, rotation_angle * 0.7, 0));
    }

    // Update camera for orbit effect
    if (camera) |cam| {
        const orbit_radius: f32 = 5.0;
        const orbit_speed: f32 = 20.0;
        const orbit_angle = rotation_angle * orbit_speed * std.math.pi / 180.0;
        
        const cam_x = std.math.cos(orbit_angle) * orbit_radius;
        const cam_z = std.math.sin(orbit_angle) * orbit_radius;
        
        cam.setPosition(zigui.Vec3.init(cam_x, 2, cam_z));
        cam.setTarget(zigui.Vec3.init(0, 0, 0));
    }
}

// Control callbacks
fn onResetCamera(button: *zigui.Button) void {
    _ = button;
    if (camera) |cam| {
        cam.setPosition(zigui.Vec3.init(0, 0, 5));
        cam.setTarget(zigui.Vec3.init(0, 0, 0));
    }
}

var animation_paused: bool = false;
fn onPauseAnimation(button: *zigui.Button) void {
    _ = button;
    animation_paused = !animation_paused;
}

var animation_speed: f32 = 1.0;
fn onSpeedChanged(slider: *zigui.Slider) void {
    animation_speed = slider.getValue();
}

fn onWireframeToggle(checkbox: *zigui.CheckBox) void {
    if (scene) |s| {
        s.setWireframeMode(checkbox.isChecked());
    }
}

fn onLightIntensityChanged(slider: *zigui.Slider) void {
    if (scene) |s| {
        s.setLightIntensity(0, slider.getValue());
    }
}

fn onRedMaterial(button: *zigui.Button) void {
    _ = button;
    if (rotating_cube) |cube| {
        var material = cube.getMaterial();
        material.setDiffuseColor(zigui.Color.RED);
        cube.setMaterial(material);
    }
}

fn onGreenMaterial(button: *zigui.Button) void {
    _ = button;
    if (rotating_cube) |cube| {
        var material = cube.getMaterial();
        material.setDiffuseColor(zigui.Color.GREEN);
        cube.setMaterial(material);
    }
}

fn onBlueMaterial(button: *zigui.Button) void {
    _ = button;
    if (rotating_cube) |cube| {
        var material = cube.getMaterial();
        material.setDiffuseColor(zigui.Color.BLUE);
        cube.setMaterial(material);
    }
}

// Custom 3D Canvas Component
const Canvas3D = struct {
    component: zigui.UIComponent,
    scene: ?*zigui.Scene3D,
    update_callback: ?*const fn(f32) void,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !*Self {
        var canvas = try allocator.create(Self);
        canvas.* = Self{
            .component = try zigui.UIComponent.init(allocator, .Canvas3D),
            .scene = null,
            .update_callback = null,
        };

        canvas.component.user_data = canvas;
        canvas.component.render_fn = render3DCanvas;
        canvas.component.update_fn = update3DCanvas;

        return canvas;
    }

    pub fn deinit(self: *Self) void {
        self.component.deinit();
        self.component.allocator.destroy(self);
    }

    pub fn setScene(self: *Self, scene: *zigui.Scene3D) void {
        self.scene = scene;
    }

    pub fn setUpdateCallback(self: *Self, callback: *const fn(f32) void) void {
        self.update_callback = callback;
    }

    fn render3DCanvas(component: *zigui.UIComponent, renderer: *zigui.Renderer, delta_time: f32) !void {
        _ = delta_time;
        const self: *Self = @ptrCast(@alignCast(component.user_data));
        
        if (self.scene) |scene| {
            // Set 3D viewport
            const bounds = component.bounds;
            try renderer.setViewport(
                @intFromFloat(bounds.x), 
                @intFromFloat(bounds.y), 
                @intFromFloat(bounds.width), 
                @intFromFloat(bounds.height)
            );
            
            // Render 3D scene
            try scene.render(renderer);
        }
    }

    fn update3DCanvas(component: *zigui.UIComponent, delta_time: f32) !void {
        const self: *Self = @ptrCast(@alignCast(component.user_data));
        
        if (!animation_paused) {
            if (self.update_callback) |callback| {
                callback(delta_time * animation_speed);
            }
            
            if (self.scene) |scene| {
                try scene.update(delta_time * animation_speed);
            }
        }
    }
};