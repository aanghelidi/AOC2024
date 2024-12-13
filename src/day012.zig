const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day012/sample3.txt");
const Position = utils.Position;
const LinearFifo = std.fifo.LinearFifo;

const GardenPlot = struct { position: Position(isize), plant_type: u8, n_adj_in_region: ?usize = null };
const Region = struct {
    const Self = @This();

    id: usize,
    gps: std.ArrayList(GardenPlot),
    n_sides: usize,

    pub fn area(self: Self) usize {
        return self.gps.items.len;
    }

    pub fn perimeter(self: Self) usize {
        var result = self.area() * 4;
        for (self.gps.items) |gp| {
            if (gp.n_adj_in_region) |value| result -= value;
        }
        return result;
    }

    pub fn price(self: Self) usize {
        return self.area() * self.perimeter();
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var map = try parse(data, allocator);
    defer map.deinit();

    var visited = std.ArrayList(std.ArrayList(bool)).init(allocator);
    defer visited.deinit();
    for (map.items) |row| {
        var row_set = std.ArrayList(bool).init(allocator);
        try row_set.appendNTimes(false, row.items.len);
        try visited.append(row_set);
    }

    const fifo = LinearFifo(GardenPlot, .Dynamic);
    var regions = std.ArrayList(Region).init(allocator);
    defer regions.deinit();
    var region_id: usize = 0;
    for (map.items) |row| {
        for (row.items) |garden_plot| {
            if (visited.items[@as(usize, @intCast(garden_plot.position.row))].items[@as(usize, @intCast(garden_plot.position.col))]) continue;
            var queue: fifo = fifo.init(allocator);
            defer queue.deinit();
            try queue.writeItem(garden_plot);
            region_id += 1;
            var gps = std.ArrayList(GardenPlot).init(allocator);
            defer gps.deinit();
            var region = Region{ .id = region_id, .gps = gps, .n_sides = 0 };
            while (queue.readItem()) |gp| {
                if (visited.items[@as(usize, @intCast(gp.position.row))].items[@as(usize, @intCast(gp.position.col))]) continue;
                visited.items[@as(usize, @intCast(gp.position.row))].items[@as(usize, @intCast(gp.position.col))] = true;
                var neighbours = try gp.position.N4(allocator);
                defer neighbours.deinit();
                var np_in_regions: [4]bool = .{ false, false, false, false };
                for (neighbours.items, 0..) |np, nidx| {
                    if (!inGrid(isize, std.ArrayList(GardenPlot), np, &map)) continue;
                    const next_gp = map.items[@as(usize, @intCast(np.row))].items[@as(usize, @intCast(np.col))];
                    if (next_gp.plant_type == gp.plant_type) np_in_regions[nidx] = true;
                    if (visited.items[@as(usize, @intCast(np.row))].items[@as(usize, @intCast(np.col))]) continue;
                    if (next_gp.plant_type == gp.plant_type) {
                        try queue.writeItem(next_gp);
                    }
                }
                var final_gp = gp;
                var count_adj_in_region: usize = 0;
                for (np_in_regions) |in_region| {
                    if (in_region) count_adj_in_region += 1;
                }
                final_gp.n_adj_in_region = count_adj_in_region;
                try region.gps.append(final_gp);
            }
            try regions.append(region);
        }
    }

    var ans: usize = 0;
    for (regions.items) |region| {
        ans += region.price();
    }
    print("Part 1: {d}\n", .{ans});
}

fn parse(input: []const u8, allocator: Allocator) !std.ArrayList(std.ArrayList(GardenPlot)) {
    var grid = std.ArrayList(std.ArrayList(GardenPlot)).init(allocator);
    var it = mem.tokenizeScalar(u8, input, '\n');
    var row: usize = 0;
    while (it.next()) |line| {
        var col: usize = 0;
        var garden_plots = std.ArrayList(GardenPlot).init(allocator);
        for (line) |e| {
            const pos = Position(isize).init(@as(isize, @intCast(row)), @as(isize, @intCast(col)));
            try garden_plots.append(.{ .position = pos, .plant_type = e });
            col += 1;
        }
        try grid.append(garden_plots);
        row += 1;
    }
    return grid;
}

fn inGrid(comptime T: type, comptime GT: type, pos: Position(T), grid: *std.ArrayList(GT)) bool {
    return pos.row >= 0 and pos.row < grid.items.len and pos.col >= 0 and pos.col < grid.items[0].items.len;
}
