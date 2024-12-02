const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day02/input.txt");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const ans = countSafe(data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    print("Part 1: {d}\n", .{ans});
    const ans2 = countSafe2(data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    print("Part 2: {d}\n", .{ans2});
}

fn countSafe(input_data: []const u8, allocator: mem.Allocator) !u32 {
    var it = mem.tokenizeScalar(u8, input_data, '\n');
    var safe_reports: u32 = 0;

    re: while (it.next()) |reports| {
        var levelIt = mem.tokenizeAny(u8, reports, &ascii.whitespace);
        var levels = std.ArrayList(i32).init(allocator);
        defer levels.deinit();
        while (levelIt.next()) |report| {
            const n = try std.fmt.parseInt(i32, report, 10);
            try levels.append(n);
        }
        var safe = true;
        var slidingW = std.mem.window(i32, levels.items, 3, 1);
        while (slidingW.next()) |w| {
            const diff = w[0] - w[1];
            const diff2 = w[1] - w[2];

            const isUnsafe = checkIsUnsafe(i32, diff, diff2);

            if (isUnsafe) {
                safe = false;
                continue :re;
            }
        }
        if (safe) safe_reports += 1;
    }
    return safe_reports;
}

fn countSafe2(input_data: []const u8, allocator: mem.Allocator) !u32 {
    var it = mem.tokenizeScalar(u8, input_data, '\n');
    var safe_reports: u32 = 0;

    re: while (it.next()) |reports| {
        var levelIt = mem.tokenizeAny(u8, reports, &std.ascii.whitespace);
        var levels = std.ArrayList(i32).init(allocator);
        defer levels.deinit();
        while (levelIt.next()) |report| {
            const n = try std.fmt.parseInt(i32, report, 10);
            try levels.append(n);
        }
        var safe = true;
        var slidingW = std.mem.window(i32, levels.items, 3, 1);
        var to_check = false;
        var unsafe_count: u8 = 0;
        var previous_diff: i32 = 0;
        slide: while (slidingW.next()) |w| {
            const diff = w[0] - w[1];
            const diff2 = w[1] - w[2];
            const outerdiff = w[0] - w[2];

            if (unsafe_count == 1 and to_check) {
                to_check = false;
                unsafe_count = 0;
                const isUnsafe2 = checkIsUnsafe(i32, previous_diff, diff2);
                if (isUnsafe2) {
                    safe = false;
                    continue :re;
                }
                safe = true;
                break :slide;
            }

            const isUnsafe = checkIsUnsafe(i32, diff, diff2);

            if (isUnsafe) {
                to_check = true;
                if (to_check and unsafe_count == 0) {
                    unsafe_count += 1;
                    previous_diff = outerdiff;
                    safe = false;
                    continue :slide;
                }
                safe = false;
            }
        }
        if (safe) safe_reports += 1;
    }
    return safe_reports;
}

fn checkIsUnsafe(comptime T: type, d1: T, d2: T) bool {
    return (math.sign(d1) != math.sign(d2)) or
        (d1 == 0) or (d2 == 0) or
        (@abs(d1) < 1) or (@abs(d1) > 3) or (@abs(d2) < 1) or (@abs(d2) > 3);
}

test "day x part 1 2024" {
    const testing_data = @embedFile("day02/sample.txt");
    try testing.expectEqual(2, countSafe(testing_data, testing.allocator));
}

test "day x part 2 2024" {
    const testing_data = @embedFile("day02/sample.txt");
    try testing.expectEqual(4, countSafe2(testing_data, testing.allocator));
}
