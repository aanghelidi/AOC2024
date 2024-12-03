const std = @import("std");
const utils = @import("utils.zig");
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const data = @embedFile("day03/input.txt");
const parseInt = std.fmt.parseInt;

pub fn main() void {
    const ans = multiply(u32, data) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    print("Part 1: {d}\n", .{ans[0]});
    print("Part 2: {d}\n", .{ans[1]});
}

fn multiply(comptime T: type, memory: []const u8) !struct { T, T } {
    var total: T = 0;
    var total2: T = 0;
    var enable = true;
    for (0..memory.len + 1) |i| {
        if (i + 7 <= memory.len and mem.eql(u8, memory[i .. i + 7], "don't()")) enable = false;
        if (i + 4 <= memory.len and mem.eql(u8, memory[i .. i + 4], "do()")) enable = true;
        if (i + 4 <= memory.len - 4 and mem.eql(u8, memory[i .. i + 4], "mul(")) {
            const start = i;
            var open_count: usize = 1;
            var j: usize = i + 4;
            while (j < memory.len and open_count > 0) : (j += 1) {
                if (memory[j] == '(') open_count += 1;
                if (memory[j] == ')') open_count -= 1;
            }
            if (open_count == 0) {
                const mul_op = memory[start..j];
                if (mem.count(u8, mul_op, ",") == 1) {
                    const without_mul = mem.trimLeft(u8, mul_op, "mul(");
                    const without_trailing = mem.trimRight(u8, without_mul, ")\n");
                    var it_delimiter = mem.tokenizeScalar(u8, without_trailing, ',');
                    if (it_delimiter.next()) |arg1| {
                        if (utils.allDigits(arg1)) {
                            if (it_delimiter.next()) |arg2| {
                                if (utils.allDigits(arg2)) {
                                    const n1 = try parseInt(T, arg1, 10);
                                    const n2 = try parseInt(T, arg2, 10);
                                    total += n1 * n2;
                                    if (enable) total2 += n1 * n2;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return .{ total, total2 };
}

test "day x part 1 2024" {
    const testing_data = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    const ans = multiply(u8, testing_data) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    try testing.expectEqual(161, ans[0]);
}

test "day x part 2 2024" {
    const testing_data = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    const ans = multiply(u8, testing_data) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    try testing.expectEqual(48, ans[1]);
}
