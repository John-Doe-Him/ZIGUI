const std = @import("std");
const Color = @import("color.zig").Color;

/// Simple RGBA image held in CPU memory.
pub const Image = struct {
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    pixels: []u8, // RGBA bytes

    pub fn initEmpty(allocator: std.mem.Allocator, width: u32, height: u32) !Image {
        const bytes = @as(usize, width) * @as(usize, height) * 4;
        var buf = try allocator.alloc(u8, bytes);
        std.mem.set(u8, buf, 0);
        return Image{ .allocator = allocator, .width = width, .height = height, .pixels = buf };
    }

    pub fn deinit(self: *Image) void {
        self.allocator.free(self.pixels);
    }

    fn offset(self: *const Image, x: u32, y: u32) usize {
        return (@as(usize, y) * @as(usize, self.width) + @as(usize, x)) * 4;
    }

    pub fn setPixel(self: *Image, x: u32, y: u32, r: u8, g: u8, b: u8, a: u8) void {
        const i = self.offset(x, y);
        self.pixels[i..i + 4].* = .{ r, g, b, a };
    }

    pub fn getPixel(self: *const Image, x: u32, y: u32) Color.Color {
        const i = self.offset(x, y);
        const r: u32 = self.pixels[i];
        const g: u32 = self.pixels[i + 1];
        const b: u32 = self.pixels[i + 2];
        const a: u32 = self.pixels[i + 3];
        return Color.Color.initRGBA((r << 24) | (g << 16) | (b << 8) | a);
    }

    /// Load a 24- or 32-bit uncompressed BMP.
    pub fn loadBMP(allocator: std.mem.Allocator, path: []const u8) !Image {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var header: [14]u8 = undefined;
        try file.readAll(&header);
        if (header[0] != 'B' or header[1] != 'M') return error.InvalidFormat;

        const pixel_offset = std.mem.readIntLe(u32, header[10..14]);

        var dib: [40]u8 = undefined;
        try file.readAll(&dib);
        const w = @as(u32, std.mem.readIntLe(i32, dib[4..8]));
        const h_signed = std.mem.readIntLe(i32, dib[8..12]);
        const h = @as(u32, if (h_signed < 0) -h_signed else h_signed);
        const bpp = std.mem.readIntLe(u16, dib[14..16]);
        const compression = std.mem.readIntLe(u32, dib[16..20]);
        if (compression != 0 or (bpp != 24 and bpp != 32)) return error.Unsupported;

        var img = try Image.initEmpty(allocator, w, h);
        try file.seek(@intCast(i64, pixel_offset), .Start);

        const bytes_pp = @as(usize, bpp / 8);
        const row_raw = @as(usize, w) * bytes_pp;
        const pad = (4 - (row_raw % 4)) % 4;

        var row = try allocator.alloc(u8, row_raw);
        defer allocator.free(row);

        const bottom_up = (h_signed > 0);
        for (row_idx in 0..h) {
            const y = if (bottom_up) h - 1 - row_idx else row_idx;
            try file.readAll(row);
            if (pad != 0) { var p: [4]u8 = undefined; try file.readAll(p[0..pad]); }
            for (x in 0..w) {
                const s = x * bytes_pp;
                const b = row[s];
                const g = row[s + 1];
                const r = row[s + 2];
                const a: u8 = if (bytes_pp == 4) row[s + 3] else 0xFF;
                img.setPixel(x, y, r, g, b, a);
            }
        }
        return img;
    }

    pub const error = error{ InvalidFormat, Unsupported };
};
