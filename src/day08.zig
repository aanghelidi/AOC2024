const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day08/input.txt");
const Position = utils.Position;

const Antenna = struct {
    frequency: u8,
    position: Position(isize),
};

const AntennaPair = struct { pos1: Position(isize), pos2: Position(isize) };

const Part = enum {
    one,
    two,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var grid = parse(data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer deinitGrid(&grid, allocator);

    var antennas = retrieveAntennas(&grid, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer antennas.deinit(allocator);

    var locations = uniqueAntinodes(&grid, antennas, allocator, Part.one) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer locations.deinit();
    const ans = locations.count();
    print("Part 1: {d}\n", .{ans});

    var locations_2 = uniqueAntinodes(&grid, antennas, allocator, Part.two) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer locations_2.deinit();
    const ans2 = locations_2.count();
    print("Part 2: {d}\n", .{ans2});
}

fn parse(input: []const u8, allocator: Allocator) !std.ArrayList([]u8) {
    var grid = std.ArrayList([]u8).init(allocator);
    var it = mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |row| {
        const mutable_row = try allocator.alloc(u8, row.len);
        @memcpy(mutable_row, row);
        try grid.append(mutable_row);
    }
    return grid;
}

fn deinitGrid(grid: *std.ArrayList([]u8), allocator: Allocator) void {
    for (grid.items) |row| {
        allocator.free(row);
    }
    grid.deinit();
}

fn retrieveAntennas(grid: *std.ArrayList([]u8), allocator: Allocator) !std.MultiArrayList(Antenna) {
    const n = grid.items.len;
    const m = grid.items[0].len;
    var antennas = std.MultiArrayList(Antenna){};
    var row: usize = 0;
    while (row < n) : (row += 1) {
        var col: usize = 0;
        while (col < m) : (col += 1) {
            if (ascii.isAlphanumeric(grid.items[row][col])) {
                const position = Position(isize).init(@as(isize, @intCast(row)), @as(isize, @intCast(col)));
                try antennas.append(allocator, .{ .position = position, .frequency = grid.items[row][col] });
            }
        }
    }
    return antennas;
}

fn uniqueAntinodes(grid: *std.ArrayList([]u8), antennas: std.MultiArrayList(Antenna), allocator: Allocator, part: Part) !std.AutoHashMap(Position(isize), void) {
    var pairs = std.AutoHashMap(AntennaPair, void).init(allocator);
    defer pairs.deinit();
    var locations = std.AutoHashMap(Position(isize), void).init(allocator);
    for (antennas.items(.frequency), antennas.items(.position)) |freq, pos| {
        for (antennas.items(.frequency), antennas.items(.position)) |freq2, pos2| {
            if (freq != freq2) continue;
            if (freq == freq2 and pos.row == pos2.row and pos.col == pos2.col) continue;

            const p1: AntennaPair = .{ .pos1 = pos, .pos2 = pos2 };
            const p2: AntennaPair = .{ .pos1 = pos2, .pos2 = pos };
            switch (part) {
                Part.one => try addLocations(grid, &locations, &pairs, p1, p2),
                Part.two => try addLocations2(grid, &locations, &pairs, p1, p2),
            }
        }
    }
    return locations;
}

fn addLocations(grid: *std.ArrayList([]u8), locations: *std.AutoHashMap(Position(isize), void), pairs: *std.AutoHashMap(AntennaPair, void), p1: AntennaPair, p2: AntennaPair) !void {
    const n = grid.items.len;
    const m = grid.items[0].len;
    if (pairs.contains(p1) or pairs.contains(p2)) return;
    const pos = p1.pos1;
    const pos2 = p1.pos2;
    const distance: Position(isize) = .{ .row = pos.row - pos2.row, .col = pos.col - pos2.col };
    const ant_1: Position(isize) = .{ .row = pos.row + distance.row, .col = pos.col + distance.col };
    const ant_2: Position(isize) = .{ .row = pos2.row - distance.row, .col = pos2.col - distance.col };
    if (ant_1.row >= 0 and ant_1.row < n and ant_1.col >= 0 and ant_1.col < m and !locations.contains(ant_1)) {
        try locations.put(ant_1, {});
    }
    if (ant_2.row >= 0 and ant_2.row < n and ant_2.col >= 0 and ant_2.col < m and !locations.contains(ant_2)) {
        try locations.put(ant_2, {});
    }
    try pairs.put(p1, {});
    try pairs.put(p2, {});
}

fn addLocations2(grid: *std.ArrayList([]u8), locations: *std.AutoHashMap(Position(isize), void), pairs: *std.AutoHashMap(AntennaPair, void), p1: AntennaPair, p2: AntennaPair) !void {
    const n = grid.items.len;
    const m = grid.items[0].len;
    if (pairs.contains(p1) or pairs.contains(p2)) return;
    const pos = p1.pos1;
    const pos2 = p1.pos2;

    const distance: Position(isize) = .{ .row = pos.row - pos2.row, .col = pos.col - pos2.col };

    var p_row = pos.row;
    var p_col = pos.col;
    if (!locations.contains(pos)) try locations.put(pos, {});
    while (p_row >= 0 and p_row < n and p_col >= 0 and p_col < m) {
        p_row += distance.row;
        p_col += distance.col;
        const ant_1: Position(isize) = .{ .row = p_row, .col = p_col };
        if (ant_1.row >= 0 and ant_1.row < n and ant_1.col >= 0 and ant_1.col < m and !locations.contains(ant_1)) {
            try locations.put(ant_1, {});
        }
    }

    var p2_row = pos2.row;
    var p2_col = pos2.col;
    if (!locations.contains(pos2)) try locations.put(pos2, {});
    while (p2_row >= 0 and p2_row < n and p2_col >= 0 and p2_col < m) {
        p2_row -= distance.row;
        p2_col -= distance.col;
        const ant_2: Position(isize) = .{ .row = p2_row, .col = p2_col };
        if (ant_2.row >= 0 and ant_2.row < n and ant_2.col >= 0 and ant_2.col < m and !locations.contains(ant_2)) {
            try locations.put(ant_2, {});
        }
    }

    try pairs.put(p1, {});
    try pairs.put(p2, {});
}

test "day 8 part 1 2024" {
    const testing_data = @embedFile("day08/sample.txt");
    const allocator = std.testing.allocator;
    var grid = parse(testing_data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer deinitGrid(&grid, allocator);

    var antennas = retrieveAntennas(&grid, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer antennas.deinit(allocator);

    var locations = uniqueAntinodes(&grid, antennas, allocator, Part.one) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer locations.deinit();
    const ans = locations.count();
    try testing.expectEqual(14, ans);
}

test "day 8 part 2 (small) 2024" {
    const testing_data = @embedFile("day08/sample2.txt");
    const allocator = std.testing.allocator;
    var grid = parse(testing_data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer deinitGrid(&grid, allocator);

    var antennas = retrieveAntennas(&grid, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer antennas.deinit(allocator);

    var locations = uniqueAntinodes(&grid, antennas, allocator, Part.two) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer locations.deinit();
    const ans = locations.count();
    try testing.expectEqual(9, ans);
}

test "day 8 part 2 2024" {
    const testing_data = @embedFile("day08/sample.txt");
    const allocator = std.testing.allocator;
    var grid = parse(testing_data, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer deinitGrid(&grid, allocator);

    var antennas = retrieveAntennas(&grid, allocator) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer antennas.deinit(allocator);

    var locations = uniqueAntinodes(&grid, antennas, allocator, Part.two) catch |err| {
        print("{any}\n", .{err});
        return;
    };
    defer locations.deinit();
    const ans = locations.count();
    try testing.expectEqual(34, ans);
}
