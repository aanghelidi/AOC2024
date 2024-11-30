const std = @import("std");
const testing = std.testing;

/// On success, returns the content of the file in a []u8.
/// On error, returns either `std.fs.Dir.StatFileError` or `std.fs.File.ReadError`.
pub fn readFile(filename: []const u8) ![]u8 {
    const stats = try std.fs.cwd().statFile(filename);
    const file_size = stats.size;
    const data = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, file_size);
    return data;
}

/// Simple generic struct containing Position info
pub fn Position(comptime T: type) type {
    return struct {
        const Self = @This();
        x: T,
        y: T,

        pub fn init(x: T, y: T) Self {
            return Self{
                .x = x,
                .y = y,
            };
        }
    };
}
test "Position can init" {
    const pos = Position(u8).init(0, 0);
    try testing.expectEqual(0, pos.x);
    try testing.expectEqual(0, pos.y);
}
