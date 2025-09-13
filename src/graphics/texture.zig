const std = @import("std");
const Img = @import("img.zig");

pub const Texture = struct {
    width: u32,
    height: u32,
    pixels: []u8, // RGBA CPU copy

    /// Make a texture directly from an Image (takes ownership of pixel buffer).
    pub fn fromImage(img: *Img.Image) Texture {
        const tex = Texture{
            .width = img.width,
            .height = img.height,
            .pixels = img.pixels,
        };
        // hand over ownership so img doesn’t free it
        img.pixels = &[_]u8{};
        return tex;
    }

    pub fn deinit(self: *Texture, allocator: std.mem.Allocator) void {
        allocator.free(self.pixels);
    }
};
