const std = @import("std");
const Color = @import("Color.zig");
const Widget = @import("Widget.zig");
const Input = @import("input.zig");
const AiResponse = @import("ai.zig").AiResponse;

const Allocator = std.mem.Allocator;

pub fn createLayout(allocator: Allocator) !Widget {
    var root: Widget = .{
        .name = "root",
        .width = 800,
        .height = 70,
        .background_color = Color.Cyan,
    };

    const text_input: *Widget = try allocator.create(Widget);
    text_input.* = .{ .name = "text_input", .text_color = Color.Black };

    root.children = text_input;
    return root;
}

pub fn updateLayout(allocator: Allocator, layout: *Widget, input: *Input, ai_response: *?AiResponse) !void {
    layout.children.?.text = input.*.textInput.items;

    if (ai_response.*) |ai_text_response| {
        const results: *Widget = try allocator.create(Widget);
        results.* = .{
            .name = "results",
            .text = ai_text_response.text,
            .text_color = Color.Black,
            .background_color = Color.LightGrey,
            .width = 800,
            .height = 600,
            .margin_y = 100,
        };

        // HACK: Should be a child of root not text
        layout.children.?.children = results;
    }
}
