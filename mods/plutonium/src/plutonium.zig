const std = @import("std");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
    @cInclude("epoxy/gl.h");
});

pub const Window = struct {
    handle: *c.GLFWwindow,
    width: u32,
    height: u32,
    pixels: []u8,
    allocator: std.mem.Allocator,

    pub fn init(width: u32, height: u32, title: [*:0]const u8) !*Window {
        if (c.glfwInit() == 0) {
            return error.GLFWInitFailed;
        }

        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
        c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

        const handle = c.glfwCreateWindow(
            @intCast(width),
            @intCast(height),
            title,
            null,
            null,
        ) orelse {
            c.glfwTerminate();
            return error.WindowCreationFailed;
        };

        c.glfwMakeContextCurrent(handle);
        c.glfwSwapInterval(1);

        const allocator = std.heap.page_allocator;
        const pixels = try allocator.alloc(u8, width * height * 4);
        @memset(pixels, 0);

        const self = try allocator.create(Window);
        self.* = .{
            .handle = handle,
            .width = width,
            .height = height,
            .pixels = pixels,
            .allocator = allocator,
        };

        _ = c.glfwSetWindowUserPointer(handle, @ptrCast(self));
        
        return self;
    }

    pub fn deinit(self: *Window) void {
        self.allocator.free(self.pixels);
        self.allocator.destroy(self);
        c.glfwDestroyWindow(self.handle);
        c.glfwTerminate();
    }

    pub fn shouldClose(self: *Window) bool {
        return c.glfwWindowShouldClose(self.handle) != 0;
    }

    pub fn pollEvents() void {
        c.glfwPollEvents();
    }

    pub fn setPixel(self: *Window, x: u32, y: u32, r: u8, g: u8, b: u8) void {
        if (x >= self.width or y >= self.height) return;
        
        const idx = (y * self.width + x) * 4;
        self.pixels[idx] = r;
        self.pixels[idx + 1] = g;
        self.pixels[idx + 2] = b;
        self.pixels[idx + 3] = 255; // Alpha channel
    }

    pub fn clear(self: *Window, r: u8, g: u8, b: u8) void {
        @memset(self.pixels, 0);
        for (0..self.width) |x| {
            for (0..self.height) |y| {
                self.setPixel(@intCast(x), @intCast(y), r, g, b);
            }
        }
    }

    pub fn render(self: *Window) void {
        c.glClear(c.GL_COLOR_BUFFER_BIT);
        
        c.glRasterPos2f(-1, 1);
        c.glPixelZoom(1, -1);
        
        c.glDrawPixels(
            @intCast(self.width),
            @intCast(self.height),
            c.GL_RGBA,
            c.GL_UNSIGNED_BYTE,
            @ptrCast(self.pixels.ptr),
        );
        
        c.glfwSwapBuffers(self.handle);
    }
};

// GL constants
const GL_COLOR_BUFFER_BIT = 0x00004000;
const GL_RGBA = 0x1908;
const GL_UNSIGNED_BYTE = 0x1401;
