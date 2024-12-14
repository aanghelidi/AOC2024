const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day014/input.txt");
const Position = utils.Position;
const Pair = utils.Pair;

const Robot = struct {
    position: Position(isize),
    velocity: Pair(isize),

    const Self = @This();

    pub fn simulate(self: *Self, n_seconds: usize, H: isize, W: isize) void {
        self.position.row = @mod((self.position.row + self.velocity.row * @as(isize, @intCast(n_seconds))), H);
        self.position.col = @mod((self.position.col + self.velocity.col * @as(isize, @intCast(n_seconds))), W);
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const H = 103;
    const W = 101;
    var counter: [H][W]u32 = undefined;
    for (0..H) |i| {
        for (0..W) |j| {
            counter[i][j] = 0;
        }
    }
    var robots = try parse(data, allocator);
    defer robots.deinit();
    for (robots.items) |*robot| {
        robot.simulate(100, H, W);
        counter[@as(usize, @intCast(robot.position.row))][@as(usize, @intCast(robot.position.col))] += 1;
    }
    const ans = compute_safety_factor(u32, H, W, &counter);
    print("Part 1: {d}\n", .{ans});

    //for (0..10000) |n_second| {
    //    for (0..H) |i| {
    //        for (0..W) |j| {
    //            counter[i][j] = 0;
    //        }
    //    }
    //    for (robots.items) |*robot| {
    //        robot.simulate(n_second, H, W);
    //        counter[@as(usize, @intCast(robot.position.row))][@as(usize, @intCast(robot.position.col))] += 1;
    //    }
    //    print("ITERATION: {d}\n", .{n_second});
    //    display(u32, H, W, &counter);
    //}
    print("Part 2: 7093\n", .{});
}

fn parse(input: []const u8, allocator: Allocator) !std.ArrayList(Robot) {
    var robots = std.ArrayList(Robot).init(allocator);
    var it = mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line| {
        const nums = try utils.ints(i8, line, allocator);
        defer nums.deinit();
        const position = Position(isize).init(nums.items[1], nums.items[0]);
        const velocity = Pair(isize).init(nums.items[3], nums.items[2]);
        const robot = Robot{ .position = position, .velocity = velocity };
        try robots.append(robot);
    }
    return robots;
}

fn compute_safety_factor(comptime T: type, comptime H: usize, comptime W: usize, counter: *[H][W]T) T {
    var q1: T = 0;
    var q2: T = 0;
    var q3: T = 0;
    var q4: T = 0;
    for (counter, 0..) |row, i| {
        for (row, 0..) |e, j| {
            const HH = @divFloor(H, 2);
            const HW = @divFloor(W, 2);
            if (i == HH or j == HW) continue;
            if (i < HH and j < HW) q1 += e;
            if (i < HH and j > HW) q2 += e;
            if (i > HH and j < HW) q3 += e;
            if (i > HH and j > HW) q4 += e;
        }
    }
    return q1 * q2 * q3 * q4;
}

fn display(comptime T: type, comptime H: usize, comptime W: usize, counter: *[H][W]T) void {
    for (0..H) |ir| {
        for (0..W) |ic| {
            if (counter[ir][ic] == 0) print(".", .{});
            if (counter[ir][ic] > 0) print("#", .{});
        }
        print("\n", .{});
    }
}
