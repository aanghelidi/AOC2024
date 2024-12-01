const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");

const Complex = math.complex.Complex;

pub fn main() void {
    const data = utils.readFile("input.txt") catch |err| {
        print("{any}", .{err});
        return;
    };
    print("{s}\n", .{data});
}

test "day x part 1 2024" {}

test "day x part 2 2024" {}
