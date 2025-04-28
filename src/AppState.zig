const Input = @import("input.zig");
const Window = @import("sdl.zig").Window;

state: State = .OnlyTyping,
window: *Window,

pub fn updateState(self: *@This(), input: *Input) void {
    if (self.state == .OnlyTyping and input.flags.enter) {
        self.state = .ShowingResults;
        self.window.*.setWindowSize(800, 600);
    }
}

const State = enum {
    OnlyTyping,
    ShowingResults,
};
