const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("input.txt");

const Complex = math.complex.Complex;

pub fn main() void {
    print("{s}\n", .{data});
}

test "day x part 1 2024" {
    const testing_data = @embedFile("sample.txt");
    _ = testing_data;
}

test "day x part 2 2024" {}
