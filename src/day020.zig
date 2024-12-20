const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const Order = math.Order;

const utils = @import("utils.zig");

const data = @embedFile("day020/input.txt");

const Vec2 = @Vector(2, isize);
const n4: [4]Vec2 = .{
    .{ 0, 1 }, // East
    .{ 1, 0 }, // South
    .{ 0, -1 }, // West
    .{ -1, 0 }, // North
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    //const H = 16;
    //const W = 16;
    const H = 142;
    const W = 142;
    const parsed = parse(H, W, data);
    var grid: [H][W]u8 = parsed[0];
    const start_position = parsed[1];
    const end_position = parsed[2];

    var history_cost = try solve(H, W, &grid, start_position, end_position, allocator);
    const ans = try countCheats(H, W, &grid, &history_cost, end_position, 2, 100, allocator);
    const ans2 = try countCheats(H, W, &grid, &history_cost, end_position, 20, 100, allocator);
    print("Part 1: {d}\n", .{ans});
    print("Part 2: {d}\n", .{ans2});
}

fn countCheats(comptime H: usize, comptime W: usize, grid: *[H][W]u8, history_cost: *std.AutoArrayHashMap(Vec2, u32), end_position: Vec2, max_time: usize, threshold: usize, allocator: Allocator) !u32 {
    const T = history_cost.get(end_position).?;
    var cheats_count: u32 = 0;
    var cache = std.AutoHashMap(Vec2, usize).init(allocator);
    defer cache.deinit();
    for (history_cost.keys(), 0..) |pos, t| {
        const t1 = history_cost.keys()[0 .. t + 1].len;
        var possible = std.ArrayList(Vec2).init(allocator);
        defer possible.deinit();
        for (0..H) |i| {
            for (0..W) |j| {
                const candidate = Vec2{ @as(isize, @intCast(i)), @as(isize, @intCast(j)) };
                if (heuristic(pos, candidate) <= max_time and std.simd.countTrues(pos == candidate) != 2 and grid[i][j] != '#') {
                    try possible.append(candidate);
                }
            }
        }
        for (possible.items) |npos| {
            const t2 = @mod(@as(isize, @intCast(heuristic(pos, npos))) - 2, @as(isize, @intCast(history_cost.count())));
            var t3: usize = math.maxInt(usize);
            if (cache.contains(npos)) t3 = cache.get(npos).? else {
                var idx: usize = math.maxInt(usize);
                for (history_cost.keys(), 0..) |k, i| {
                    if (std.simd.countTrues(k == npos) == 2) {
                        idx = i;
                        break;
                    }
                }
                if (idx != math.maxInt(usize)) {
                    t3 = history_cost.keys()[idx..].len;
                    try cache.put(npos, t3);
                }
            }

            if (t3 == math.maxInt(usize)) continue;
            const current_time = @as(isize, @intCast(t1)) + t2 + @as(isize, @intCast(t3));
            if (@as(isize, @intCast(T)) - current_time >= threshold) {
                cheats_count += 1;
            }
        }
    }
    return cheats_count;
}

fn solve(comptime H: usize, comptime W: usize, grid: *[H][W]u8, start_position: Vec2, end_position: Vec2, allocator: Allocator) !std.AutoArrayHashMap(Vec2, u32) {
    const PQ = std.PriorityQueue(struct { Vec2, u32 }, void, lessThanCost);
    var queue = PQ.init(allocator, {});
    defer queue.deinit();
    try queue.add(.{ start_position, 0 });
    var history_cost = std.AutoArrayHashMap(Vec2, u32).init(allocator);
    try history_cost.put(start_position, 0);
    var new_cost: u32 = undefined;
    while (queue.removeOrNull()) |position_cost| {
        const position = position_cost[0];
        if (std.simd.countTrues(position == end_position) == 2) break;
        for (n4) |n| {
            const np = position + n;
            if (!isInside(H, W, np)) continue;
            if (grid[@as(usize, @intCast(np[0]))][@as(usize, @intCast(np[1]))] == '#') continue;
            new_cost = history_cost.get(position).? + 1;
            if (!history_cost.contains(np) or new_cost < history_cost.get(np).?) {
                try history_cost.put(np, new_cost);
                try queue.add(.{ np, new_cost + heuristic(end_position, np) });
            }
        }
    }
    return history_cost;
}

fn heuristic(goal: Vec2, next: Vec2) u32 {
    var diff = goal - next;
    for (0..2) |i| diff[i] = @as(isize, @intCast(@abs(diff[i])));
    return @as(u32, @intCast(@reduce(.Add, diff)));
}

fn isInside(comptime H: usize, comptime W: usize, position: Vec2) bool {
    return position[0] >= 0 and position[0] < H and position[1] >= 0 and position[1] < W;
}

fn lessThanCost(context: void, a: struct { Vec2, u32 }, b: struct { Vec2, u32 }) Order {
    _ = context;
    return std.math.order(a[1], b[1]);
}

fn parse(comptime H: usize, comptime W: usize, input: []const u8) struct { [H][W]u8, Vec2, Vec2 } {
    var it = mem.tokenizeScalar(u8, input, '\n');
    var grid: [H][W]u8 = undefined;
    var start_position: Vec2 = undefined;
    var end_position: Vec2 = undefined;
    var row_idx: isize = 0;
    while (it.next()) |line| {
        var col_idx: isize = 0;
        for (line) |e| {
            grid[@as(usize, @intCast(row_idx))][@as(usize, @intCast(col_idx))] = e;
            if (e == 'S') start_position = Vec2{ row_idx, col_idx };
            if (e == 'E') end_position = Vec2{ row_idx, col_idx };
            col_idx += 1;
        }
        row_idx += 1;
    }
    return .{ grid, start_position, end_position };
}
