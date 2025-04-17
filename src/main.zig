const std = @import("std");
const ai = @import("ai.zig");
const sdl = @import("sdl.zig");
const Allocator = std.mem.Allocator;

const gemini = @import("gemini.zig");

pub fn main() !void {
    std.log.info("Hello, world!", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    _ = allocator;
    // const response: ai.AiResponse = try gemini.postGemini(allocator, "what day is today?");
    // std.log.info("{s}", .{response.text});
    try sdl.sdl_main();
}
