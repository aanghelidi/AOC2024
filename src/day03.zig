const std = @import("std");
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const data = @embedFile("day03/input.txt");
const parseInt = std.fmt.parseInt;

pub fn main() void {
    const ans = multiply(data) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    print("Part 1: {d}\n", .{ans});
    const ans2 = multiply2(data) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    print("Part 2: {d}\n", .{ans2});
}

fn multiply(memory: []const u8) !u128 {
    var it = mem.tokenizeScalar(u8, memory, '\n');
    var total: u128 = 0;
    while (it.next()) |line| {
        var line_result: u128 = 0;
        for (0..line.len + 1) |i| {
            if (i + 4 <= line.len - 4 and mem.eql(u8, line[i .. i + 4], "mul(")) {
                const start = i;
                var open_count: usize = 1;
                var j: usize = i + 4;
                while (j < line.len and open_count > 0) : (j += 1) {
                    if (line[j] == '(') open_count += 1;
                    if (line[j] == ')') open_count -= 1;
                }
                if (open_count == 0) {
                    const mul_op = line[start..j];
                    if (mem.count(u8, mul_op, ",") == 1) {
                        const without_mul = mem.trimLeft(u8, mul_op, "mul(");
                        const without_trailing = mem.trimRight(u8, without_mul, ")\n");
                        var it_delimiter = mem.tokenizeScalar(u8, without_trailing, ',');
                        if (it_delimiter.next()) |arg1| {
                            if (allDigits(arg1)) {
                                if (it_delimiter.next()) |arg2| {
                                    if (allDigits(arg2)) {
                                        const n1 = try parseInt(u128, arg1, 10);
                                        const n2 = try parseInt(u128, arg2, 10);
                                        line_result += n1 * n2;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        total += line_result;
    }
    return total;
}

fn multiply2(memory: []const u8) !u128 {
    var it = mem.tokenizeScalar(u8, memory, '\n');
    var total: u128 = 0;
    var enable = true;
    while (it.next()) |line| {
        var line_result: u128 = 0;
        for (0..line.len + 1) |i| {
            if (i + 7 <= line.len and mem.eql(u8, line[i .. i + 7], "don't()")) enable = false;
            if (i + 4 <= line.len and mem.eql(u8, line[i .. i + 4], "do()")) enable = true;
            if (i + 4 <= line.len - 4 and mem.eql(u8, line[i .. i + 4], "mul(")) {
                const start = i;
                var open_count: usize = 1;
                var j: usize = i + 4;
                while (j < line.len and open_count > 0) : (j += 1) {
                    if (line[j] == '(') open_count += 1;
                    if (line[j] == ')') open_count -= 1;
                }
                if (open_count == 0 and enable) {
                    const mul_op = line[start..j];
                    if (mem.count(u8, mul_op, ",") == 1) {
                        const without_mul = mem.trimLeft(u8, mul_op, "mul(");
                        const without_trailing = mem.trimRight(u8, without_mul, ")\n");
                        var it_delimiter = mem.tokenizeScalar(u8, without_trailing, ',');
                        if (it_delimiter.next()) |arg1| {
                            if (allDigits(arg1)) {
                                if (it_delimiter.next()) |arg2| {
                                    if (allDigits(arg2)) {
                                        const n1 = try parseInt(u128, arg1, 10);
                                        const n2 = try parseInt(u128, arg2, 10);
                                        line_result += n1 * n2;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        total += line_result;
    }
    return total;
}

fn allDigits(chars: []const u8) bool {
    for (chars) |char| {
        if (!ascii.isDigit(char)) {
            return false;
        }
    }
    return true;
}

test "day x part 1 2024" {
    const testing_data = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";
    try testing.expectEqual(161, multiply(testing_data));
}

test "day x part 2 2024" {
    const testing_data = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";
    try testing.expectEqual(48, multiply2(testing_data));
}
