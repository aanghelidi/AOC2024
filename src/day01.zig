const std = @import("std");
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("../src/utils.zig");

pub fn main() void {
    const data = utils.readFile("day01/input.txt") catch |err| {
        print("{any}", .{err});
        return;
    };

    const ans = computeDistance(data) catch |err| {
        print("{any}", .{err});
        return;
    };
    print("Part 1: {d}\n", .{ans});

    const ans2 = computeSimilarity(data) catch |err| {
        print("{any}", .{err});
        return;
    };
    print("Part 2: {d}\n", .{ans2});
}

fn computeDistance(data: []const u8) !u32 {
    var it = mem.tokenizeAny(u8, data, " \n");
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var l1 = std.ArrayList(i32).init(allocator);
    defer l1.deinit();

    var l2 = std.ArrayList(i32).init(allocator);
    defer l2.deinit();

    var l_selector: i16 = 0;
    while (it.next()) |loc| {
        const n = try std.fmt.parseInt(i32, loc, 10);
        if (@mod(l_selector, 2) == 0) try l1.append(n);
        if (@mod(l_selector, 2) == 1) try l2.append(n);
        l_selector += 1;
    }

    mem.sort(i32, l1.items, {}, comptime std.sort.asc(i32));
    mem.sort(i32, l2.items, {}, comptime std.sort.asc(i32));

    var total_distance: u32 = 0;
    for (l1.items, l2.items) |e1, e2| {
        const diff: i32 = e2 - e1;
        total_distance += @abs(diff);
    }
    return total_distance;
}

fn computeSimilarity(data: []const u8) !u32 {
    var it = mem.tokenizeAny(u8, data, " \n");
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var l1 = std.ArrayList(u32).init(allocator);
    defer l1.deinit();

    var l2 = std.ArrayList(u32).init(allocator);
    defer l2.deinit();

    var l_selector: i16 = 0;
    while (it.next()) |loc| {
        const n = try std.fmt.parseInt(u32, loc, 10);
        if (@mod(l_selector, 2) == 0) try l1.append(n);
        if (@mod(l_selector, 2) == 1) try l2.append(n);
        l_selector += 1;
    }

    var counter = std.AutoHashMap(u32, u32).init(allocator);
    defer counter.deinit();

    for (l2.items) |e| {
        if (counter.get(e)) |v| {
            try counter.put(e, v + 1);
        } else {
            try counter.put(e, 1);
        }
    }

    var score: u32 = 0;
    for (l1.items) |e| {
        if (counter.get(e)) |v| {
            score += e * v;
        }
    }
    return score;
}

test "day 1 part 1 2024" {
    const testing_data = utils.readFile("day01/sample.txt") catch |err| {
        print("{any}", .{err});
        return;
    };
    try testing.expectEqual(11, computeDistance(testing_data));
}

test "day 1 part 2 2024" {
    const testing_data = utils.readFile("day01/sample.txt") catch |err| {
        print("{any}", .{err});
        return;
    };
    try testing.expectEqual(31, computeSimilarity(testing_data));
}
