const std = @import("std");
const Allocator = std.mem.Allocator;
const mem = std.mem;
const print = std.debug.print;
const LinearFifo = std.fifo.LinearFifo;

const utils = @import("utils.zig");

const data = @embedFile("day024/input.txt");

const Op = enum {
    AND,
    XOR,
    OR,

    const Self = @This();

    pub fn fromStr(str: []const u8) !Self {
        if (std.mem.eql(u8, "AND", str)) return Op.AND;
        if (std.mem.eql(u8, "XOR", str)) return Op.XOR;
        if (std.mem.eql(u8, "OR", str)) return Op.OR;
        return error.InvalidOp;
    }
};
const WireGate = struct { w1: []const u8, op: Op, w2: []const u8, out_var: []const u8 };

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it_parts = mem.splitSequence(u8, data, "\n\n");
    const wires = it_parts.next().?;
    const connections = it_parts.next().?;

    var vars = std.StringHashMap(u32).init(allocator);
    defer vars.deinit();
    var it_lines_wires = mem.tokenizeScalar(u8, wires, '\n');
    while (it_lines_wires.next()) |line| {
        var it_wire = mem.splitSequence(u8, line, ": ");
        const key = it_wire.next().?;
        const value = it_wire.next().?;
        const n = try std.fmt.parseInt(u32, value, 10);
        try vars.put(key, n);
    }

    const fifo = LinearFifo(WireGate, .Dynamic);
    var queue: fifo = fifo.init(allocator);
    defer queue.deinit();
    var it_lines_connections = mem.tokenizeScalar(u8, connections, '\n');
    while (it_lines_connections.next()) |line| {
        var it_wire_gate = mem.tokenizeAny(u8, line, " ->");
        const w1 = it_wire_gate.next().?;
        const op_str = it_wire_gate.next().?;
        const op = try Op.fromStr(op_str);
        const w2 = it_wire_gate.next().?;
        const out_var = it_wire_gate.next().?;
        try queue.writeItem(WireGate{ .w1 = w1, .op = op, .w2 = w2, .out_var = out_var });
    }

    while (queue.readItem()) |todo| {
        const w1 = todo.w1;
        const w2 = todo.w2;
        const op = todo.op;
        const out_var = todo.out_var;
        if (!vars.contains(w1) or !vars.contains(w2)) {
            try queue.writeItem(todo);
            continue;
        }
        const n1 = vars.get(w1).?;
        const n2 = vars.get(w2).?;
        const result = switch (op) {
            Op.AND => n1 & n2,
            Op.OR => n1 | n2,
            Op.XOR => n1 ^ n2,
        };
        try vars.put(out_var, result);
    }

    var z_bin = try std.fmt.allocPrint(allocator, "", .{});
    var i: usize = 45;
    while (i > -1) : (i -= 1) {
        const key = try std.fmt.allocPrint(allocator, "z{:0>2}", .{i});
        const bit = vars.get(key).?;
        z_bin = try std.fmt.allocPrint(allocator, "{s}{d}", .{ z_bin, bit });
        if (i == 0) break;
    }
    const ans = try std.fmt.parseInt(u128, z_bin, 2);
    print("Part 1: {d}\n", .{ans});
}
