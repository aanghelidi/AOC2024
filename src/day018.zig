const std = @import("std");
const Allocator = std.mem.Allocator;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day018/input.txt");
const ParseInt = std.fmt.parseInt;
const Position = utils.Position;
const Order = math.Order;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const H = 71;
    const W = 71;
    const position_end = Position(isize).init(H - 1, W - 1);

    var grid: [H][W]u8 = try parse(H, W, data, 1024);
    var costs = try solve(H, W, &grid, allocator);
    defer costs.deinit();
    print("Part 1: {d}\n", .{costs.get(position_end).?});

    var N: usize = 0;
    var it = mem.tokenizeScalar(u8, data, '\n');
    var position_byte = std.AutoHashMap(usize, []const u8).init(allocator);
    defer position_byte.deinit();
    while (it.next()) |line| {
        try position_byte.put(N, line);
        N += 1;
    }

    var byte_position: usize = 0;
    while (true) : (byte_position += 1) {
        grid = try parse(H, W, data, byte_position);
        costs = try solve(H, W, &grid, allocator);
        if (!costs.contains(position_end)) break;
    }
    print("Part 2: {s}\n", .{position_byte.get(byte_position - 1).?});
}

fn solve(comptime H: usize, comptime W: usize, grid: *[H][W]u8, allocator: Allocator) !std.AutoHashMap(Position(isize), u32) {
    const PQ = std.PriorityQueue(struct { Position(isize), u32 }, void, lessThanCost);
    var queue = PQ.init(allocator, {});
    const position_start = Position(isize).init(0, 0);
    const position_end = Position(isize).init(H - 1, W - 1);
    try queue.add(.{ position_start, 0 });
    var costs = std.AutoHashMap(Position(isize), u32).init(allocator);
    try costs.put(position_start, 0);
    var new_cost: u32 = undefined;

    while (queue.removeOrNull()) |position_cost| {
        const position = position_cost[0];
        if (position.row == position_end.row and position.col == position_end.col) {
            break;
        }
        const neighbours = try position.N4(allocator);
        for (neighbours.items) |np| {
            if (!isInside(H, W, np)) continue;
            if (grid[@as(usize, @intCast(np.row))][@as(usize, @intCast(np.col))] == '#') continue;
            new_cost = costs.get(position).? + 1;
            if (!costs.contains(np) or new_cost < costs.get(np).?) {
                try costs.put(np, new_cost);
                try queue.add(.{ np, new_cost + heuristic(position_end, np) });
            }
        }
    }
    return costs;
}

fn heuristic(goal: Position(isize), next: Position(isize)) u32 {
    return @as(u32, @intCast(@abs(goal.row - next.row) + @abs(goal.col - next.col)));
}

fn isInside(comptime H: usize, comptime W: usize, position: Position(isize)) bool {
    return position.row >= 0 and position.row < H and position.col >= 0 and position.col < W;
}
fn lessThanCost(context: void, a: struct { Position(isize), u32 }, b: struct { Position(isize), u32 }) Order {
    _ = context;
    return std.math.order(a[1], b[1]);
}

fn parse(comptime H: usize, comptime W: usize, input: []const u8, byte_stop: usize) ![H][W]u8 {
    var grid: [H][W]u8 = undefined;
    for (0..H) |ri| {
        for (0..W) |ci| {
            grid[ri][ci] = '.';
        }
    }
    var it = mem.tokenizeScalar(u8, input, '\n');
    var bytes: usize = 0;
    while (it.next()) |line| {
        if (bytes == byte_stop) break;
        var it_c = mem.tokenizeScalar(u8, line, ',');
        if (it_c.next()) |col| {
            if (it_c.next()) |row| {
                const ri = try ParseInt(usize, row, 10);
                const ci = try ParseInt(usize, col, 10);
                grid[ri][ci] = '#';
            }
        }
        bytes += 1;
    }
    return grid;
}
