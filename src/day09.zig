const std = @import("std");
const Allocator = std.mem.Alloctor;
const ascii = std.ascii;
const mem = std.mem;
const print = std.debug.print;
const data = @embedFile("day09/input.txt");

const Block = struct { file_id: ?u64 = null, start_pos: usize, size: usize };

const DiskMap = struct {
    ids: std.ArrayList(?u64),
    spaces: std.ArrayList(Block),
    files: std.ArrayList(Block),

    const Self = @This();

    pub fn deinit(self: Self) void {
        self.ids.deinit();
        self.spaces.deinit();
        self.files.deinit();
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const disk_map = try parse(data, allocator);
    defer disk_map.deinit();
    var ids = disk_map.ids;
    while (ids.popOrNull()) |el| {
        if (el == null) continue;
        const first = mem.indexOfScalar(?u64, ids.items, null);
        if (first) |value| ids.items[value] = el;
        if (allDigits(ids.items)) break;
    }
    var ans: u64 = 0;
    for (0.., ids.items) |pos, id| {
        ans += @as(u64, @intCast(pos)) * id.?;
    }
    print("Part 1: {d}\n", .{ans});

    const disk_map_2 = try parse(data, allocator);
    defer disk_map_2.deinit();
    const ids2 = disk_map_2.ids;
    const spaces2 = disk_map_2.spaces;
    var files2 = disk_map_2.files;
    while (files2.popOrNull()) |fb| {
        spaces: for (0.., spaces2.items) |i, sb| {
            if (sb.start_pos < fb.start_pos and sb.size >= fb.size) {
                var j: usize = 0;
                while (j < fb.size) : (j += 1) {
                    ids2.items[fb.start_pos + j] = null;
                    ids2.items[sb.start_pos + j] = fb.file_id;
                }
                spaces2.items[i] = Block{ .file_id = null, .start_pos = sb.start_pos + fb.size, .size = sb.size - fb.size };
                break :spaces;
            }
        }
    }
    var ans2: u64 = 0;
    for (0.., ids2.items) |pos, id| {
        if (id) |value| {
            ans2 += @as(u64, @intCast(pos)) * value;
        }
    }
    print("Part 2: {d}\n", .{ans2});
}

fn allDigits(slice: []?u64) bool {
    for (slice) |e| {
        if (e == null) return false;
    }
    return true;
}

fn parse(input: []const u8, allocator: Allocator) !DiskMap {
    const trimmed_input = std.mem.trim(u8, input, &ascii.whitespace);
    var ids = std.ArrayList(?u64).init(allocator);
    var spaces = std.ArrayList(Block).init(allocator);
    var files = std.ArrayList(Block).init(allocator);
    var position: usize = 0;
    for (trimmed_input, 0..) |c, i| {
        const n = @as(usize, @intCast(c - '0'));
        if (@mod(i, 2) == 0) {
            const file_id = @divExact(@as(u64, @intCast(i)), 2);
            try files.append(.{ .start_pos = position, .size = n, .file_id = file_id });
            try ids.appendNTimes(file_id, n);
            position += n;
        } else {
            if (n > 0) try spaces.append(.{ .start_pos = position, .size = n });
            try ids.appendNTimes(null, n);
            position += n;
        }
    }
    return DiskMap{ .ids = ids, .spaces = spaces, .files = files };
}
