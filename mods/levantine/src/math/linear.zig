const std = @import("std");
const math = std.math;
const testing = std.testing;
const Allocator = std.mem.Allocator;

pub const Vector = struct {
    data: []f64,
    allocator: Allocator,

    pub fn init(allocator: Allocator, vector_size: usize) !Vector {
        const data = try allocator.alloc(f64, vector_size);
        @memset(data, 0);
        return Vector{ .data = data, .allocator = allocator };
    }

    pub fn fromSlice(allocator: Allocator, slice: []const f64) !Vector {
        const data = try allocator.dupe(f64, slice);
        return Vector{ .data = data, .allocator = allocator };
    }

    pub fn deinit(self: *Vector) void {
        self.allocator.free(self.data);
    }

    pub fn at(self: Vector, index: usize) f64 {
        return self.data[index];
    }

    pub fn set(self: *Vector, index: usize, value: f64) void {
        self.data[index] = value;
    }

    pub fn size(self: Vector) usize {
        return self.data.len;
    }

    pub fn add(self: Vector, other: Vector) !Vector {
        if (self.size() != other.size()) return error.InvalidDimensions;
        
        var result = try Vector.init(self.allocator, self.size());
        for (self.data, 0..) |val, i| {
            result.data[i] = val + other.data[i];
        }
        return result;
    }

    pub fn sub(self: Vector, other: Vector) !Vector {
        if (self.size() != other.size()) return error.InvalidDimensions;
        
        var result = try Vector.init(self.allocator, self.size());
        for (self.data, 0..) |val, i| {
            result.data[i] = val - other.data[i];
        }
        return result;
    }

    pub fn scale(self: Vector, scalar: f64) !Vector {
        var result = try Vector.init(self.allocator, self.size());
        for (self.data, 0..) |val, i| {
            result.data[i] = val * scalar;
        }
        return result;
    }

    pub fn dot(self: Vector, other: Vector) f64 {
        if (self.size() != other.size()) return math.nan(f64);
        
        var sum: f64 = 0;
        for (self.data, 0..) |val, i| {
            sum += val * other.data[i];
        }
        return sum;
    }

    pub fn magnitude(self: Vector) f64 {
        return math.sqrt(self.dot(self));
    }

    pub fn normalize(self: Vector) !Vector {
        const mag = self.magnitude();
        if (mag == 0) return error.ZeroVector;
        return self.scale(1.0 / mag);
    }
};

pub const Matrix = struct {
    rows: usize,
    cols: usize,
    data: []f64,
    allocator: Allocator,

    pub fn init(allocator: Allocator, rows: usize, cols: usize) !Matrix {
        const data = try allocator.alloc(f64, rows * cols);
        @memset(data, 0);
        return Matrix{ .rows = rows, .cols = cols, .data = data, .allocator = allocator };
    }

    pub fn fromSlice(allocator: Allocator, rows: usize, cols: usize, slice: []const f64) !Matrix {
        if (slice.len != rows * cols) return error.InvalidDimensions;
        
        const data = try allocator.dupe(f64, slice);
        return Matrix{ .rows = rows, .cols = cols, .data = data, .allocator = allocator };
    }

    pub fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
    }

    pub fn at(self: Matrix, row: usize, col: usize) f64 {
        return self.data[row * self.cols + col];
    }

    pub fn set(self: *Matrix, row: usize, col: usize, value: f64) void {
        self.data[row * self.cols + col] = value;
    }

    pub fn add(self: Matrix, other: Matrix) !Matrix {
        if (self.rows != other.rows or self.cols != other.cols) return error.InvalidDimensions;
        
        var result = try Matrix.init(self.allocator, self.rows, self.cols);
        for (self.data, 0..) |val, i| {
            result.data[i] = val + other.data[i];
        }
        return result;
    }

    pub fn sub(self: Matrix, other: Matrix) !Matrix {
        if (self.rows != other.rows or self.cols != other.cols) return error.InvalidDimensions;
        
        var result = try Matrix.init(self.allocator, self.rows, self.cols);
        for (self.data, 0..) |val, i| {
            result.data[i] = val - other.data[i];
        }
        return result;
    }

    pub fn mul(self: Matrix, other: Matrix) !Matrix {
        if (self.cols != other.rows) return error.InvalidDimensions;
        
        var result = try Matrix.init(self.allocator, self.rows, other.cols);
        
        for (0..self.rows) |i| {
            for (0..other.cols) |j| {
                var sum: f64 = 0;
                for (0..self.cols) |k| {
                    sum += self.at(i, k) * other.at(k, j);
                }
                result.set(i, j, sum);
            }
        }
        
        return result;
    }

    pub fn scale(self: Matrix, scalar: f64) !Matrix {
        var result = try Matrix.init(self.allocator, self.rows, self.cols);
        for (self.data, 0..) |val, i| {
            result.data[i] = val * scalar;
        }
        return result;
    }

    pub fn transpose(self: Matrix) !Matrix {
        var result = try Matrix.init(self.allocator, self.cols, self.rows);
        
        for (0..self.rows) |i| {
            for (0..self.cols) |j| {
                result.set(j, i, self.at(i, j));
            }
        }
        
        return result;
    }

    pub fn determinant(self: Matrix) f64 {
        if (self.rows != self.cols) return math.nan(f64);
        
        if (self.rows == 1) return self.at(0, 0);
        if (self.rows == 2) {
            return self.at(0, 0) * self.at(1, 1) - self.at(0, 1) * self.at(1, 0);
        }
        
        var det: f64 = 0;
        const temp_allocator = self.allocator;
        
        for (0..self.cols) |i| {
            const sign = if (i % 2 == 0) 1.0 else -1.0;
            const minor = self.getMinor(0, i, temp_allocator) catch return math.nan(f64);
            defer minor.deinit();
            
            det += sign * self.at(0, i) * minor.determinant();
        }
        
        return det;
    }

    fn getMinor(self: Matrix, row: usize, col: usize, allocator: Allocator) !Matrix {
        const minor_dimension = self.rows - 1;
        var minor = try Matrix.init(allocator, minor_dimension, minor_dimension);
        
        var minor_row: usize = 0;
        for (0..self.rows) |i| {
            if (i == row) continue;
            
            var minor_col: usize = 0;
            for (0..self.cols) |j| {
                if (j == col) continue;
                
                minor.set(minor_row, minor_col, self.at(i, j));
                minor_col += 1;
            }
            
            minor_row += 1;
        }
        
        return minor;
    }

    pub fn inverse(self: Matrix) !Matrix {
        const det = self.determinant();
        if (det == 0 or math.isNan(det)) return error.SingularMatrix;
        
        const adj = try self.adjugate();
        defer adj.deinit();
        
        return adj.scale(1.0 / det);
    }

    fn adjugate(self: Matrix) !Matrix {
        if (self.rows != self.cols) return error.NonSquareMatrix;
        
        const n = self.rows;
        var adj = try Matrix.init(self.allocator, n, n);
        
        for (0..n) |i| {
            for (0..n) |j| {
                const sign = if ((i + j) % 2 == 0) 1.0 else -1.0;
                const minor = try self.getMinor(i, j, self.allocator);
                defer minor.deinit();
                
                const cofactor = sign * minor.determinant();
                adj.set(j, i, cofactor); // Transpose happens here
            }
        }
        
        return adj;
    }
};

test "vector operations" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const v1 = try Vector.fromSlice(allocator, &[_]f64{ 1.0, 2.0, 3.0 });
    const v2 = try Vector.fromSlice(allocator, &[_]f64{ 4.0, 5.0, 6.0 });
    
    // Test addition
    const sum = try v1.add(v2);
    defer sum.deinit();
    try testing.expectApproxEqAbs(sum.at(0), 5.0, 0.0001);
    try testing.expectApproxEqAbs(sum.at(1), 7.0, 0.0001);
    try testing.expectApproxEqAbs(sum.at(2), 9.0, 0.0001);
    
    // Test dot product
    const dot = v1.dot(v2);
    try testing.expectApproxEqAbs(dot, 32.0, 0.0001);
    
    // Test magnitude
    const mag = v1.magnitude();
    try testing.expectApproxEqAbs(mag, 3.7416, 0.0001);
}

test "matrix operations" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const m1 = try Matrix.fromSlice(allocator, 2, 2, &[_]f64{ 1.0, 2.0, 3.0, 4.0 });
    const m2 = try Matrix.fromSlice(allocator, 2, 2, &[_]f64{ 5.0, 6.0, 7.0, 8.0 });
    
    // Test matrix multiplication
    const product = try m1.mul(m2);
    defer product.deinit();
    
    try testing.expectApproxEqAbs(product.at(0, 0), 19.0, 0.0001);
    try testing.expectApproxEqAbs(product.at(0, 1), 22.0, 0.0001);
    try testing.expectApproxEqAbs(product.at(1, 0), 43.0, 0.0001);
    try testing.expectApproxEqAbs(product.at(1, 1), 50.0, 0.0001);
    
    // Test determinant
    const det = m1.determinant();
    try testing.expectApproxEqAbs(det, -2.0, 0.0001);
    
    // Test inverse
    const inv = try m1.inverse();
    defer inv.deinit();
    
    try testing.expectApproxEqAbs(inv.at(0, 0), -2.0, 0.0001);
    try testing.expectApproxEqAbs(inv.at(0, 1), 1.0, 0.0001);
    try testing.expectApproxEqAbs(inv.at(1, 0), 1.5, 0.0001);
    try testing.expectApproxEqAbs(inv.at(1, 1), -0.5, 0.0001);
}
