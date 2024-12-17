const std = @import("std");
const Allocator = std.mem.Allocator;
const ascii = std.ascii;
const math = std.math;
const mem = std.mem;
const print = std.debug.print;
const testing = std.testing;
const utils = @import("utils.zig");
const data = @embedFile("day017/input.txt");
const EnumArray = std.EnumArray;
const ParseInt = std.fmt.parseInt;

const Register = enum(u2) { A, B, C };
const OpCode = enum(u3) { adv, bxl, bst, jnz, bxc, out, bdv, cdv };
const Operand = enum(u3) { zero, one, two, three, four, five, six, seven };
pub fn Computer(comptime T: type) type {
    return struct {
        const Self = @This();
        registers: EnumArray(Register, T),
        program: std.ArrayList(u3),

        pub fn init(registers: EnumArray(Register, T), program: std.ArrayList(u3)) Self {
            return Self{ .registers = registers, .program = program };
        }
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const T = u128;
    var computer = try parseComputer(T, data, allocator);
    var registers = computer.registers;
    var program = computer.program;
    defer program.deinit();
    const outs = try runProgram(T, &registers, program, allocator);
    defer outs.deinit();
    const out_repr = try formatProgramOrOut(outs, allocator);
    defer allocator.free(out_repr);
    print("Part 1: {s}\n", .{out_repr});

    computer = try parseComputer(T, data, allocator);
    var registers2 = computer.registers;
    var program2 = computer.program;
    defer program2.deinit();
    const program_repr = try formatProgramOrOut(program2, allocator);
    defer allocator.free(program_repr);

    var candidate: T = 0;
    while (true) : (candidate += 1) {
        var register_copy: EnumArray(Register, T) = undefined;
        register_copy.set(Register.A, candidate);
        register_copy.set(Register.B, registers2.get(Register.B));
        register_copy.set(Register.C, registers2.get(Register.C));

        const outs2 = try runProgram(T, &register_copy, program2, allocator);
        defer outs2.deinit();
        const out_repr2 = try formatProgramOrOut(outs2, allocator);
        defer allocator.free(out_repr2);
        if (std.mem.eql(u8, program_repr, out_repr2)) {
            print("Part 2: {d}\n", .{candidate});
            break;
        }
    }
}

fn formatProgramOrOut(program: std.ArrayList(u3), allocator: Allocator) ![]u8 {
    var program_repr = try std.fmt.allocPrint(allocator, "{d}", .{program.items[0]});
    for (program.items, 0..) |e, i| {
        if (i == 0) continue;
        program_repr = try std.fmt.allocPrint(allocator, "{s},{d}", .{ program_repr, e });
    }
    return program_repr;
}

fn runProgram(comptime T: type, registers: *EnumArray(Register, T), program: std.ArrayList(u3), allocator: Allocator) !std.ArrayList(u3) {
    var instruction_pt: usize = 0;
    const end_program = program.items.len;
    var previous: usize = instruction_pt;
    var outs = std.ArrayList(u3).init(allocator);
    while (instruction_pt < end_program) {
        const opcode = @as(OpCode, @enumFromInt(program.items[instruction_pt]));
        const operand = @as(Operand, @enumFromInt(program.items[instruction_pt + 1]));
        try computeInstruction(T, registers, opcode, operand, &instruction_pt, &outs);
        if (opcode != OpCode.jnz) instruction_pt += 2;
        if (previous == instruction_pt) break;
        previous = instruction_pt;
    }
    return outs;
}

fn computeInstruction(comptime T: type, registers: *EnumArray(Register, T), opcode: OpCode, operand: Operand, instruction_pt: *usize, outs: *std.ArrayList(u3)) !void {
    switch (opcode) {
        OpCode.adv => {
            const numerator = registers.get(Register.A);
            const denominator = math.pow(T, 2, comboOperandValue(T, registers, operand));
            const result = @divTrunc(numerator, denominator);
            registers.set(Register.A, result);
        },
        OpCode.bxl => {
            const result = registers.get(Register.B) ^ @as(T, @intCast(@intFromEnum(operand)));
            registers.set(Register.B, result);
        },
        OpCode.bst => {
            const result = @mod(comboOperandValue(T, registers, operand), 8);
            registers.set(Register.B, result);
        },
        OpCode.jnz => {
            switch (registers.get(Register.A)) {
                0 => {},
                else => instruction_pt.* = @as(usize, @intCast(@intFromEnum(operand))),
            }
        },
        OpCode.bxc => {
            const result = registers.get(Register.B) ^ registers.get(Register.C);
            registers.set(Register.B, result);
        },
        OpCode.out => {
            const result = @as(u3, @intCast(@mod(comboOperandValue(T, registers, operand), 8)));
            try outs.append(result);
        },
        OpCode.bdv => {
            const numerator = registers.get(Register.A);
            const denominator = math.pow(T, 2, comboOperandValue(T, registers, operand));
            const result = @divTrunc(numerator, denominator);
            registers.set(Register.B, result);
        },
        OpCode.cdv => {
            const numerator = registers.get(Register.A);
            const denominator = math.pow(T, 2, comboOperandValue(T, registers, operand));
            const result = @divTrunc(numerator, denominator);
            registers.set(Register.C, result);
        },
    }
}

fn comboOperandValue(comptime T: type, registers: *EnumArray(Register, T), operand: Operand) T {
    return switch (operand) {
        Operand.zero => @as(T, @intCast(@intFromEnum(operand))),
        Operand.one => @as(T, @intCast(@intFromEnum(operand))),
        Operand.two => @as(T, @intCast(@intFromEnum(operand))),
        Operand.three => @as(T, @intCast(@intFromEnum(operand))),
        Operand.four => registers.get(Register.A),
        Operand.five => registers.get(Register.B),
        Operand.six => registers.get(Register.C),
        Operand.seven => @as(T, @intCast(@intFromEnum(operand))),
    };
}

fn parseComputer(comptime T: type, input: []const u8, allocator: Allocator) !Computer(T) {
    var registers = EnumArray(Register, T).initUndefined();
    var program = std.ArrayList(u3).init(allocator);
    const computer = Computer(T);

    var it = mem.splitSequence(u8, input, "\n\n");
    var part_id: usize = 0;
    while (it.next()) |part| {
        switch (part_id) {
            0 => {
                var it_lines = mem.tokenizeScalar(u8, part, '\n');
                var reg_id: usize = 0;
                while (it_lines.next()) |line| {
                    var it_register = mem.splitSequence(u8, line, ": ");
                    while (it_register.next()) |reg_part| {
                        if (reg_part[0] == 'R') continue;
                        const register = @as(Register, @enumFromInt(reg_id));
                        const n = try ParseInt(T, reg_part, 10);
                        registers.set(register, n);
                    }
                    reg_id += 1;
                }
            },
            1 => {
                var it_program = mem.splitSequence(u8, part, ": ");
                while (it_program.next()) |program_part| {
                    if (program_part[0] == 'P') continue;
                    const trimmed_part = mem.trim(u8, program_part, &ascii.whitespace);
                    var it_nums = mem.tokenizeScalar(u8, trimmed_part, ',');
                    while (it_nums.next()) |num| {
                        const n = try ParseInt(u3, num, 10);
                        try program.append(n);
                    }
                }
            },
            else => unreachable,
        }
        part_id += 1;
    }
    return computer.init(registers, program);
}

test "day 17 part 1 2024" {
    const testing_data = @embedFile("day017/sample.txt");
    _ = testing_data;
}

test "day 17 part 2 2024" {}
