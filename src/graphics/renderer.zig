const std = @import("std");
const Window = @import("../core/window.zig").Window;
const Color = @import("color.zig").Color;
const Texture = @import("texture.zig").Texture;
const Font = @import("font.zig").Font;
const Vec2 = @import("../math/vec2.zig").Vec2;
const Vec3 = @import("../math/vec3.zig").Vec3;
const Mat4 = @import("../math/mat4.zig").Mat4;
const Rect = @import("../math/rect.zig").Rect;
const Platform = @import("../platform/platform.zig").Platform;

pub const BlendMode = enum {
    None,
    Alpha,
    Additive,
    Multiply,
};

pub const Vertex2D = struct {
    position: Vec2,
    uv: Vec2,
    color: Color,
};

pub const Vertex3D = struct {
    position: Vec3,
    normal: Vec3,
    uv: Vec2,
    color: Color,
};

pub const RenderStats = struct {
    draw_calls: u32,
    vertices: u32,
    triangles: u32,
    frame_time: f32,
};

pub const Renderer = struct {
    allocator: std.mem.Allocator,
    
    // OpenGL objects
    vertex_buffer_2d: u32,
    vertex_buffer_3d: u32,
    index_buffer: u32,
    shader_program_2d: u32,
    shader_program_3d: u32,
    
    // Render state
    current_blend_mode: BlendMode,
    current_texture: ?*Texture,
    current_font: ?*Font,
    view_matrix: Mat4,
    projection_matrix: Mat4,
    model_matrix: Mat4,
    
    // Batching
    vertices_2d: std.ArrayList(Vertex2D),
    vertices_3d: std.ArrayList(Vertex3D),
    indices: std.ArrayList(u32),
    batch_size: u32,
    
    // Stats
    stats: RenderStats,

    const Self = @This();
    const MAX_VERTICES = 10000;
    const MAX_INDICES = 15000;

    pub fn init(allocator: std.mem.Allocator) !*Self {
        var renderer = try allocator.create(Self);
        
        renderer.* = Self{
            .allocator = allocator,
            .vertex_buffer_2d = 0,
            .vertex_buffer_3d = 0,
            .index_buffer = 0,
            .shader_program_2d = 0,
            .shader_program_3d = 0,
            .current_blend_mode = .Alpha,
            .current_texture = null,
            .current_font = null,
            .view_matrix = Mat4.identity(),
            .projection_matrix = Mat4.identity(),
            .model_matrix = Mat4.identity(),
            .vertices_2d = std.ArrayList(Vertex2D).init(allocator),
            .vertices_3d = std.ArrayList(Vertex3D).init(allocator),
            .indices = std.ArrayList(u32).init(allocator),
            .batch_size = 0,
            .stats = RenderStats{
                .draw_calls = 0,
                .vertices = 0,
                .triangles = 0,
                .frame_time = 0,
            },
        };

        try renderer.initGL();
        return renderer;
    }

    pub fn deinit(self: *Self) void {
        self.vertices_2d.deinit();
        self.vertices_3d.deinit();
        self.indices.deinit();
        self.cleanupGL();
        self.allocator.destroy(self);
    }

    pub fn beginFrame(self: *Self, window: *Window) !void {
        self.stats.draw_calls = 0;
        self.stats.vertices = 0;
        self.stats.triangles = 0;
        
        // Setup matrices
        self.setupMatrices(window);
        
        // Clear buffers
        self.vertices_2d.clearRetainingCapacity();
        self.vertices_3d.clearRetainingCapacity();
        self.indices.clearRetainingCapacity();
        self.batch_size = 0;
    }

    pub fn endFrame(self: *Self) !void {
        try self.flush();
    }

    pub fn clear(self: *Self, color: Color) !void {
        Platform.clearColor(color.r, color.g, color.b, color.a);
        Platform.clear();
    }

    pub fn setViewport(self: *Self, x: i32, y: i32, width: u32, height: u32) !void {
        Platform.setViewport(x, y, width, height);
    }

    pub fn setBlendMode(self: *Self, mode: BlendMode) void {
        if (self.current_blend_mode != mode) {
            self.flush() catch {};
            self.current_blend_mode = mode;
            Platform.setBlendMode(mode);
        }
    }

    pub fn setTexture(self: *Self, texture: ?*Texture) void {
        if (self.current_texture != texture) {
            self.flush() catch {};
            self.current_texture = texture;
            if (texture) |tex| {
                Platform.bindTexture(tex.id);
            } else {
                Platform.unbindTexture();
            }
        }
    }

    pub fn setFont(self: *Self, font: ?*Font) void {
        self.current_font = font;
    }

    // 2D Drawing Functions
    pub fn drawRect(self: *Self, rect: Rect, color: Color) !void {
        try self.drawRectTextured(rect, null, color);
    }

    pub fn drawRectTextured(self: *Self, rect: Rect, texture_rect: ?Rect, color: Color) !void {
        const uv = if (texture_rect) |tr| tr else Rect.init(0, 0, 1, 1);
        
        const vertices = [4]Vertex2D{
            Vertex2D{ .position = Vec2.init(rect.x, rect.y), .uv = Vec2.init(uv.x, uv.y), .color = color },
            Vertex2D{ .position = Vec2.init(rect.x + rect.width, rect.y), .uv = Vec2.init(uv.x + uv.width, uv.y), .color = color },
            Vertex2D{ .position = Vec2.init(rect.x + rect.width, rect.y + rect.height), .uv = Vec2.init(uv.x + uv.width, uv.y + uv.height), .color = color },
            Vertex2D{ .position = Vec2.init(rect.x, rect.y + rect.height), .uv = Vec2.init(uv.x, uv.y + uv.height), .color = color },
        };

        const quad_indices = [6]u32{ 0, 1, 2, 2, 3, 0 };
        
        try self.addVertices2D(&vertices, &quad_indices);
    }

    pub fn drawCircle(self: *Self, center: Vec2, radius: f32, color: Color, segments: u32) !void {
        const seg_count = @max(segments, 8);
        var vertices = try self.allocator.alloc(Vertex2D, seg_count + 1);
        defer self.allocator.free(vertices);
        
        var indices = try self.allocator.alloc(u32, seg_count * 3);
        defer self.allocator.free(indices);

        // Center vertex
        vertices[0] = Vertex2D{
            .position = center,
            .uv = Vec2.init(0.5, 0.5),
            .color = color,
        };

        // Circle vertices
        for (0..seg_count) |i| {
            const angle = @as(f32, @floatFromInt(i)) * (2.0 * std.math.pi) / @as(f32, @floatFromInt(seg_count));
            const cos_a = std.math.cos(angle);
            const sin_a = std.math.sin(angle);
            
            vertices[i + 1] = Vertex2D{
                .position = Vec2.init(center.x + cos_a * radius, center.y + sin_a * radius),
                .uv = Vec2.init(0.5 + cos_a * 0.5, 0.5 + sin_a * 0.5),
                .color = color,
            };
        }

        // Triangle indices
        for (0..seg_count) |i| {
            const next = (i + 1) % seg_count;
            indices[i * 3] = 0;
            indices[i * 3 + 1] = @intCast(i + 1);
            indices[i * 3 + 2] = @intCast(next + 1);
        }

        try self.addVertices2D(vertices, indices);
    }

    pub fn drawLine(self: *Self, start: Vec2, end: Vec2, thickness: f32, color: Color) !void {
        const direction = end.sub(start).normalize();
        const perpendicular = Vec2.init(-direction.y, direction.x).scale(thickness * 0.5);
        
        const vertices = [4]Vertex2D{
            Vertex2D{ .position = start.add(perpendicular), .uv = Vec2.init(0, 0), .color = color },
            Vertex2D{ .position = start.sub(perpendicular), .uv = Vec2.init(0, 1), .color = color },
            Vertex2D{ .position = end.sub(perpendicular), .uv = Vec2.init(1, 1), .color = color },
            Vertex2D{ .position = end.add(perpendicular), .uv = Vec2.init(1, 0), .color = color },
        };

        const line_indices = [6]u32{ 0, 1, 2, 2, 3, 0 };
        
        try self.addVertices2D(&vertices, &line_indices);
    }

    pub fn drawText(self: *Self, text: []const u8, position: Vec2, color: Color) !void {
        if (self.current_font) |font| {
            try font.renderText(self, text, position, color);
        }
    }

    // 3D Drawing Functions
    pub fn drawMesh3D(self: *Self, vertices: []const Vertex3D, indices: []const u32) !void {
        try self.addVertices3D(vertices, indices);
    }

    pub fn drawCube3D(self: *Self, center: Vec3, size: Vec3, color: Color) !void {
        const half_size = size.scale(0.5);
        
        // Cube vertices (8 corners)
        const vertices = [8]Vertex3D{
            // Front face
            Vertex3D{ .position = Vec3.init(center.x - half_size.x, center.y - half_size.y, center.z + half_size.z), .normal = Vec3.init(0, 0, 1), .uv = Vec2.init(0, 0), .color = color },
            Vertex3D{ .position = Vec3.init(center.x + half_size.x, center.y - half_size.y, center.z + half_size.z), .normal = Vec3.init(0, 0, 1), .uv = Vec2.init(1, 0), .color = color },
            Vertex3D{ .position = Vec3.init(center.x + half_size.x, center.y + half_size.y, center.z + half_size.z), .normal = Vec3.init(0, 0, 1), .uv = Vec2.init(1, 1), .color = color },
            Vertex3D{ .position = Vec3.init(center.x - half_size.x, center.y + half_size.y, center.z + half_size.z), .normal = Vec3.init(0, 0, 1), .uv = Vec2.init(0, 1), .color = color },
            // Back face
            Vertex3D{ .position = Vec3.init(center.x - half_size.x, center.y - half_size.y, center.z - half_size.z), .normal = Vec3.init(0, 0, -1), .uv = Vec2.init(1, 0), .color = color },
            Vertex3D{ .position = Vec3.init(center.x + half_size.x, center.y - half_size.y, center.z - half_size.z), .normal = Vec3.init(0, 0, -1), .uv = Vec2.init(0, 0), .color = color },
            Vertex3D{ .position = Vec3.init(center.x + half_size.x, center.y + half_size.y, center.z - half_size.z), .normal = Vec3.init(0, 0, -1), .uv = Vec2.init(0, 1), .color = color },
            Vertex3D{ .position = Vec3.init(center.x - half_size.x, center.y + half_size.y, center.z - half_size.z), .normal = Vec3.init(0, 0, -1), .uv = Vec2.init(1, 1), .color = color },
        };

        // Cube indices (12 triangles)
        const cube_indices = [36]u32{
            // Front face
            0, 1, 2, 2, 3, 0,
            // Back face
            4, 6, 5, 6, 4, 7,
            // Left face
            4, 0, 3, 3, 7, 4,
            // Right face
            1, 5, 6, 6, 2, 1,
            // Top face
            3, 2, 6, 6, 7, 3,
            // Bottom face
            4, 5, 1, 1, 0, 4,
        };

        try self.addVertices3D(&vertices, &cube_indices);
    }

    // Matrix operations
    pub fn setViewMatrix(self: *Self, matrix: Mat4) void {
        self.view_matrix = matrix;
    }

    pub fn setProjectionMatrix(self: *Self, matrix: Mat4) void {
        self.projection_matrix = matrix;
    }

    pub fn setModelMatrix(self: *Self, matrix: Mat4) void {
        self.model_matrix = matrix;
    }

    pub fn handleWindowResize(self: *Self, window: *Window, width: u32, height: u32) !void {
        _ = window;
        try self.setViewport(0, 0, width, height);
        self.setupProjection(width, height);
    }

    // Private methods
    fn initGL(self: *Self) !void {
        // Initialize OpenGL resources
        self.vertex_buffer_2d = Platform.createBuffer();
        self.vertex_buffer_3d = Platform.createBuffer();
        self.index_buffer = Platform.createBuffer();
        
        self.shader_program_2d = try Platform.createShaderProgram(vertex_shader_2d, fragment_shader_2d);
        self.shader_program_3d = try Platform.createShaderProgram(vertex_shader_3d, fragment_shader_3d);
        
        // Reserve space for batching
        try self.vertices_2d.ensureTotalCapacity(MAX_VERTICES);
        try self.vertices_3d.ensureTotalCapacity(MAX_VERTICES);
        try self.indices.ensureTotalCapacity(MAX_INDICES);
    }

    fn cleanupGL(self: *Self) void {
        Platform.deleteBuffer(self.vertex_buffer_2d);
        Platform.deleteBuffer(self.vertex_buffer_3d);
        Platform.deleteBuffer(self.index_buffer);
        Platform.deleteShaderProgram(self.shader_program_2d);
        Platform.deleteShaderProgram(self.shader_program_3d);
    }

    fn setupMatrices(self: *Self, window: *Window) void {
        // Setup 2D orthographic projection
        self.projection_matrix = Mat4.orthographic(
            0, @floatFromInt(window.width),
            @floatFromInt(window.height), 0,
            -1, 1
        );
        self.view_matrix = Mat4.identity();
        self.model_matrix = Mat4.identity();
    }

    fn setupProjection(self: *Self, width: u32, height: u32) void {
        self.projection_matrix = Mat4.orthographic(
            0, @floatFromInt(width),
            @floatFromInt(height), 0,
            -1, 1
        );
    }

    fn addVertices2D(self: *Self, vertices: []const Vertex2D, indices: []const u32) !void {
        if (self.vertices_2d.items.len + vertices.len > MAX_VERTICES or 
            self.indices.items.len + indices.len > MAX_INDICES) {
            try self.flush();
        }

        const vertex_offset: u32 = @intCast(self.vertices_2d.items.len);
        try self.vertices_2d.appendSlice(vertices);
        
        for (indices) |index| {
            try self.indices.append(index + vertex_offset);
        }
        
        self.batch_size += 1;
    }

    fn addVertices3D(self: *Self, vertices: []const Vertex3D, indices: []const u32) !void {
        if (self.vertices_3d.items.len + vertices.len > MAX_VERTICES or 
            self.indices.items.len + indices.len > MAX_INDICES) {
            try self.flush();
        }

        const vertex_offset: u32 = @intCast(self.vertices_3d.items.len);
        try self.vertices_3d.appendSlice(vertices);
        
        for (indices) |index| {
            try self.indices.append(index + vertex_offset);
        }
        
        self.batch_size += 1;
    }

    fn flush(self: *Self) !void {
        if (self.vertices_2d.items.len > 0) {
            try self.flush2D();
        }
        if (self.vertices_3d.items.len > 0) {
            try self.flush3D();
        }
    }

    fn flush2D(self: *Self) !void {
        if (self.vertices_2d.items.len == 0) return;

        Platform.useShaderProgram(self.shader_program_2d);
        Platform.setUniformMatrix4fv("u_mvp", self.projection_matrix.mul(self.view_matrix).mul(self.model_matrix));
        
        Platform.bindBuffer(Platform.ARRAY_BUFFER, self.vertex_buffer_2d);
        Platform.bufferData(Platform.ARRAY_BUFFER, @ptrCast(self.vertices_2d.items.ptr), self.vertices_2d.items.len * @sizeOf(Vertex2D));
        
        Platform.bindBuffer(Platform.ELEMENT_ARRAY_BUFFER, self.index_buffer);
        Platform.bufferData(Platform.ELEMENT_ARRAY_BUFFER, @ptrCast(self.indices.items.ptr), self.indices.items.len * @sizeOf(u32));
        
        Platform.enableVertexAttrib(0);
        Platform.enableVertexAttrib(1);
        Platform.enableVertexAttrib(2);
        
        Platform.vertexAttribPointer(0, 2, Platform.FLOAT, false, @sizeOf(Vertex2D), 0);
        Platform.vertexAttribPointer(1, 2, Platform.FLOAT, false, @sizeOf(Vertex2D), @offsetOf(Vertex2D, "uv"));
        Platform.vertexAttribPointer(2, 4, Platform.FLOAT, false, @sizeOf(Vertex2D), @offsetOf(Vertex2D, "color"));
        
        Platform.drawElements(Platform.TRIANGLES, @intCast(self.indices.items.len), Platform.UNSIGNED_INT, null);
        
        self.stats.draw_calls += 1;
        self.stats.vertices += @intCast(self.vertices_2d.items.len);
        self.stats.triangles += @intCast(self.indices.items.len / 3);
        
        self.vertices_2d.clearRetainingCapacity();
        self.indices.clearRetainingCapacity();
        self.batch_size = 0;
    }

    fn flush3D(self: *Self) !void {
        if (self.vertices_3d.items.len == 0) return;

        Platform.useShaderProgram(self.shader_program_3d);
        Platform.setUniformMatrix4fv("u_mvp", self.projection_matrix.mul(self.view_matrix).mul(self.model_matrix));
        Platform.setUniformMatrix4fv("u_model", self.model_matrix);
        Platform.setUniformMatrix4fv("u_view", self.view_matrix);
        Platform.setUniformMatrix4fv("u_projection", self.projection_matrix);
        
        Platform.bindBuffer(Platform.ARRAY_BUFFER, self.vertex_buffer_3d);
        Platform.bufferData(Platform.ARRAY_BUFFER, @ptrCast(self.vertices_3d.items.ptr), self.vertices_3d.items.len * @sizeOf(Vertex3D));
        
        Platform.bindBuffer(Platform.ELEMENT_ARRAY_BUFFER, self.index_buffer);
        Platform.bufferData(Platform.ELEMENT_ARRAY_BUFFER, @ptrCast(self.indices.items.ptr), self.indices.items.len * @sizeOf(u32));
        
        Platform.enableVertexAttrib(0);
        Platform.enableVertexAttrib(1);
        Platform.enableVertexAttrib(2);
        Platform.enableVertexAttrib(3);
        
        Platform.vertexAttribPointer(0, 3, Platform.FLOAT, false, @sizeOf(Vertex3D), 0);
        Platform.vertexAttribPointer(1, 3, Platform.FLOAT, false, @sizeOf(Vertex3D), @offsetOf(Vertex3D, "normal"));
        Platform.vertexAttribPointer(2, 2, Platform.FLOAT, false, @sizeOf(Vertex3D), @offsetOf(Vertex3D, "uv"));
        Platform.vertexAttribPointer(3, 4, Platform.FLOAT, false, @sizeOf(Vertex3D), @offsetOf(Vertex3D, "color"));
        
        Platform.drawElements(Platform.TRIANGLES, @intCast(self.indices.items.len), Platform.UNSIGNED_INT, null);
        
        self.stats.draw_calls += 1;
        self.stats.vertices += @intCast(self.vertices_3d.items.len);
        self.stats.triangles += @intCast(self.indices.items.len / 3);
        
        self.vertices_3d.clearRetainingCapacity();
        self.indices.clearRetainingCapacity();
        self.batch_size = 0;
    }

    // Shader sources
    const vertex_shader_2d =
        \\#version 330 core
        \\layout (location = 0) in vec2 a_position;
        \\layout (location = 1) in vec2 a_uv;
        \\layout (location = 2) in vec4 a_color;
        \\
        \\uniform mat4 u_mvp;
        \\
        \\out vec2 v_uv;
        \\out vec4 v_color;
        \\
        \\void main() {
        \\    gl_Position = u_mvp * vec4(a_position, 0.0, 1.0);
        \\    v_uv = a_uv;
        \\    v_color = a_color;
        \\}
    ;

    const fragment_shader_2d =
        \\#version 330 core
        \\in vec2 v_uv;
        \\in vec4 v_color;
        \\
        \\uniform sampler2D u_texture;
        \\uniform bool u_has_texture;
        \\
        \\out vec4 FragColor;
        \\
        \\void main() {
        \\    if (u_has_texture) {
        \\        FragColor = texture(u_texture, v_uv) * v_color;
        \\    } else {
        \\        FragColor = v_color;
        \\    }
        \\}
    ;

    const vertex_shader_3d =
        \\#version 330 core
        \\layout (location = 0) in vec3 a_position;
        \\layout (location = 1) in vec3 a_normal;
        \\layout (location = 2) in vec2 a_uv;
        \\layout (location = 3) in vec4 a_color;
        \\
        \\uniform mat4 u_model;
        \\uniform mat4 u_view;
        \\uniform mat4 u_projection;
        \\uniform mat4 u_mvp;
        \\
        \\out vec3 v_position;
        \\out vec3 v_normal;
        \\out vec2 v_uv;
        \\out vec4 v_color;
        \\
        \\void main() {
        \\    v_position = vec3(u_model * vec4(a_position, 1.0));
        \\    v_normal = mat3(transpose(inverse(u_model))) * a_normal;
        \\    v_uv = a_uv;
        \\    v_color = a_color;
        \\    
        \\    gl_Position = u_mvp * vec4(a_position, 1.0);
        \\}
    ;

    const fragment_shader_3d =
        \\#version 330 core
        \\in vec3 v_position;
        \\in vec3 v_normal;
        \\in vec2 v_uv;
        \\in vec4 v_color;
        \\
        \\uniform sampler2D u_texture;
        \\uniform bool u_has_texture;
        \\uniform vec3 u_light_pos;
        \\uniform vec3 u_view_pos;
        \\uniform vec3 u_light_color;
        \\
        \\out vec4 FragColor;
        \\
        \\void main() {
        \\    vec3 color = v_color.rgb;
        \\    if (u_has_texture) {
        \\        color *= texture(u_texture, v_uv).rgb;
        \\    }
        \\    
        \\    // Basic Phong lighting
        \\    vec3 ambient = 0.15 * color;
        \\    
        \\    vec3 norm = normalize(v_normal);
        \\    vec3 light_dir = normalize(u_light_pos - v_position);
        \\    float diff = max(dot(norm, light_dir), 0.0);
        \\    vec3 diffuse = diff * u_light_color * color;
        \\    
        \\    vec3 view_dir = normalize(u_view_pos - v_position);
        \\    vec3 reflect_dir = reflect(-light_dir, norm);
        \\    float spec = pow(max(dot(view_dir, reflect_dir), 0.0), 64.0);
        \\    vec3 specular = spec * u_light_color;
        \\    
        \\    vec3 result = ambient + diffuse + specular;
        \\    FragColor = vec4(result, v_color.a);
        \\}
    ;
};