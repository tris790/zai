const std = @import("std");
const ai = @import("ai.zig");
const sdl = @import("sdl.zig");
const ui = @import("ui.zig");
const Allocator = std.mem.Allocator;
const Input = @import("input.zig");
const AppState = @import("AppState.zig");

const gemini = @import("gemini.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    const hal = try sdl.sdl_init();
    var window = try hal.sdl_create_window();

    var textInput: std.ArrayList(u8) = .init(allocator);
    var input: Input = .{ .textInput = textInput, .flags = .{ .typed = true } };
    defer textInput.deinit();

    var app_state: AppState = .{ .window = &window };
    var layout = try ui.createLayout(allocator);

    var response: ?ai.AiResponse = null;

    while (!input.flags.exit) {
        try ui.updateLayout(allocator, &layout, &input, &response);
        try window.render(&layout);

        if (input.flags.enter) {
            response = try gemini.postGemini(allocator, input.textInput.items);
        }

        try window.handleInput(&input);
        app_state.updateState(&input);
    }

    hal.cleanup();
}
