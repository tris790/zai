r: u8 = 0,
g: u8 = 0,
b: u8 = 0,
a: u8 = 0,

pub const White: @This() = .{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const Black: @This() = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
pub const LightGrey: @This() = .{ .r = 150, .g = 150, .b = 150, .a = 255 };
pub const DarkGrey: @This() = .{ .r = 33, .g = 33, .b = 33, .a = 255 };
pub const Cyan: @This() = .{ .r = 0, .g = 100, .b = 120, .a = 255 };
