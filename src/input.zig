const std = @import("std");

textInput: std.ArrayList(u8),
flags: InputFlags,

pub const InputFlags = packed struct {
    exit: bool = false,
    typed: bool = false,
    mouse_down: bool = false,
    mouse_up: bool = false,
    enter: bool = false,
};
