const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const Complex = std.math.complex.Complex;
const utils = @import("../src/utils.zig");

pub fn main() void {
    const data = utils.readFile("input.txt") catch |err| {
        print("{any}", .{err});
        return;
    };
    print("{s}\n", .{data});
}

test "day x part 1 2024" {}

test "day x part 2 2024" {}
