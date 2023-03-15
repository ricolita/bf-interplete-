const std = @import("std");
const print = std.debug.print;

const Cpu = struct {
    pc: u16 = 0,
    memory: [1000]u8,
    code: []const u8,

    pub fn read_tokens(self: *Cpu, ) BfErros!void {
        var last_brakets: [10]u16 = undefined;
        var num: u8 = 0;
        var opcode: u16 = 0;
        while (opcode < self.code.len) : (opcode += 1) switch (self.code[opcode]) {
            '+' => self.memory[self.pc] +%= 1,
            '-' => self.memory[self.pc] -%= 1,
            '.' => print("{c}", .{self.memory[self.pc]}),
            '[' => {
                last_brakets[num] = opcode;
                num += 1;
            },
            ']' => {
                if(num == 0) { 
                    return BfErros.ExpectedBraketSquare;
                } else if(self.memory[self.pc] != 0) {
                    opcode = last_brakets[num - 1];
                } else {
                    num -= 1;
                }      
            },
            '<' => {
                if(self.pc - 1 < 0) return BfErros.OutOfMemory;
                self.pc -= 1;
            },
            '>' => {
                if(self.pc + 1 > self.memory.len) return BfErros.OutOfMemory;
                self.pc += 1;
            },
            ' ', '\n', '\r' => {},
            else => return BfErros.OpcodeUndefined,
        };
    }
};

const BfErros = error {
    OpcodeUndefined,
    OutOfMemory,
    ExpectedBraketSquare,
};

pub fn main() void {
    var buffer: [2000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();
    
    const commands = std.process.argsAlloc(allocator) catch @panic("invalid arg");
    defer allocator.free(commands);
    
    const file = std.fs.cwd().openFile(commands[1], .{}) catch @panic("file not found");
    defer file.close();

    const bytes_read = file.readAll(&buffer) catch @panic("file not read");

    var bf: Cpu = .{ .memory = .{0} ** 1000, .code = buffer[0..bytes_read]};
    bf.read_tokens() catch |err| switch(err) {
        error.OpcodeUndefined => print("\nerr: opcode undefined", .{}),
        error.OutOfMemory => print("\nerr: out of memory", .{}),
        error.ExpectedBraketSquare => print("\n expected token '[', ']'", .{}),
        else => unreachable,
    };   
}