const Color = @import("Color.zig");

name: []const u8,
text: []const u8 = undefined,
text_color: Color = .{},
width: u32 = 0,
height: u32 = 0,
background_color: Color = .{},
border_color: Color = .{},
padding: u32 = 0,
margin_x: u32 = 0,
margin_y: u32 = 0,
children: ?*@This() = null,
flags: WidgetFlag = .{},

const WidgetFlag = packed struct {
    rounded_corners: bool = false,
};
