const std = @import("std");
const c = @import("c.zig");
const Widget = @import("Widget.zig");
const Color = @import("Color.zig");
const Input = @import("input.zig");

// Window dimensions
const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 70;

font: *c.TTF_Font,
window: ?Window = null,

pub const Window = struct {
    renderer: *c.SDL_Renderer,
    font: *c.TTF_Font,
    inner: *c.SDL_Window,

    pub fn setWindowSize(self: *Window, width: u32, height: u32) void {
        _ = c.SDL_SetWindowSize(self.inner, @intCast(width), @intCast(height));
    }

    pub fn render(self: *Window, widget_iter: *Widget) !void {
        self.clearBackground();

        var x: f32 = 0;
        var y: f32 = 0;
        var widget: ?*Widget = widget_iter;
        while (widget) |w| {
            const width: f32 = @floatFromInt(w.width);
            const height: f32 = @floatFromInt(w.height);

            x += @floatFromInt(w.margin_x);
            y += @floatFromInt(w.margin_y);

            if (w.background_color.a != 0) {
                // draw background
                self.drawRectangle(x, y, width, height, w.background_color);
            }

            if (w.border_color.a != 0) {
                self.drawBorder(x, y, width, height, w.background_color);
            }

            if (w.text.len > 0) {
                self.drawText(w.text, x, y, w.width, w.text_color);
            }

            // x += width;
            // y += height;
            widget = w.children;
        }
        _ = c.SDL_RenderPresent(self.renderer);
    }

    pub fn handleInput(_: *const Window, input: *Input) !void {
        // Handle events on queue
        var e: c.SDL_Event = undefined;
        input.flags = .{};
        while (c.SDL_PollEvent(&e)) {
            // User requests quit
            if (e.type == c.SDL_EVENT_QUIT) {
                input.flags.exit = true;
            }
            // Handle keydown events
            else if (e.type == c.SDL_EVENT_KEY_DOWN) {
                input.flags.typed = true;
                // In SDL3, keysym is replaced with direct key fields
                if (e.key.key == c.SDLK_ESCAPE) {
                    input.flags.exit = true;
                }
                // Handle backspace
                else if (e.key.key == c.SDLK_BACKSPACE) {
                    if (input.*.textInput.items.len > 0) {
                        _ = input.*.textInput.pop();
                    }
                } else if (e.key.key == c.SDLK_RETURN) {
                    input.flags.enter = true;
                }
            }
            // Handle text input
            else if (e.type == c.SDL_EVENT_TEXT_INPUT) {
                input.flags.typed = true;
                const input_text = std.mem.span(e.text.text);
                try input.*.textInput.appendSlice(input_text);
            } else if (e.type == c.SDL_EVENT_MOUSE_BUTTON_DOWN) {
                input.flags.mouse_down = true;
            } else if (e.type == c.SDL_EVENT_MOUSE_BUTTON_UP) {
                input.flags.mouse_up = true;
            }
        }
    }

    pub fn clearBackground(self: *const Window) void {
        _ = c.SDL_SetRenderDrawColor(self.renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(self.renderer);
    }

    pub fn drawRectangle(self: *const Window, x: f32, y: f32, w: f32, h: f32, border_color: Color) void {
        const rect = c.SDL_FRect{ .x = x, .y = y, .w = w, .h = h };
        _ = c.SDL_SetRenderDrawColor(self.renderer, border_color.r, border_color.g, border_color.b, border_color.a);
        _ = c.SDL_RenderFillRect(self.renderer, &rect);
    }

    pub fn drawBorder(self: *const Window, x: f32, y: f32, w: f32, h: f32, border_color: Color) void {
        const rect = c.SDL_FRect{ .x = x, .y = y, .w = w, .h = h };
        _ = c.SDL_SetRenderDrawColor(self.renderer, border_color.r, border_color.g, border_color.b, border_color.a);
        _ = c.SDL_RenderRect(self.renderer, &rect);
    }

    pub fn drawText(self: *const Window, textInput: []const u8, x: f32, y: f32, max_width: u32, color: Color) void {
        // Render text if there's any input
        const col: c.SDL_Color = .{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };
        if (c.TTF_RenderText_Blended_Wrapped(self.font, textInput.ptr, textInput.len, col, @intCast(max_width))) |textSurface| {
            defer c.SDL_DestroySurface(textSurface);
            // Create texture from surface
            const textTexture = c.SDL_CreateTextureFromSurface(self.renderer, textSurface);
            if (textTexture != null) {
                defer c.SDL_DestroyTexture(textTexture);
                // Set rendering position
                const renderRect = c.SDL_FRect{
                    .x = x, // x position
                    .y = y, // y position
                    .w = @as(f32, @floatFromInt(textSurface.*.w)),
                    .h = @as(f32, @floatFromInt(textSurface.*.h)),
                };

                // Render text
                _ = c.SDL_RenderTexture(self.renderer, textTexture, null, &renderRect);
            }
        }
    }
};

pub fn sdl_init() !@This() {
    // Initialize SDL
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        std.debug.print("SDL could not initialize! SDL_Error: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitializationFailed;
    }

    // Initialize SDL_ttf
    if (!c.TTF_Init()) {
        std.debug.print("SDL_ttf could not initialize! SDL_Error: {s}\n", .{c.SDL_GetError()});
        return error.SDLTTFInitializationFailed;
    }

    // Load font - try different font paths for cross-platform support
    const fontPaths = [_][:0]const u8{
        "C:/Windows/Fonts/arial.ttf", // Windows
        "/Library/Fonts/Arial.ttf", // macOS
        "/usr/share/fonts/truetype/arial.ttf", // Linux
        "/usr/share/fonts/TTF/DejaVuSans.ttf", // Linux alternative
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", // Another Linux alternative
    };

    const font = blk: {
        for (fontPaths) |path| {
            if (c.TTF_OpenFont(path.ptr, 24)) |loaded_font| {
                break :blk loaded_font;
            }
        }
        std.debug.print("Failed to load font! SDL_Error: {s}\n", .{c.SDL_GetError()});
        return error.FontLoadingFailed;
    };

    return .{
        .font = font,
    };
}

pub fn sdl_create_window(self: @This()) !Window {
    // Create window with borderless flag
    const window = c.SDL_CreateWindow("Borderless Text Window", WINDOW_WIDTH, WINDOW_HEIGHT, c.SDL_WINDOW_BORDERLESS) orelse {
        return error.WindowCreationFailed;
    };

    // Enable text input
    _ = c.SDL_StartTextInput(window);

    // Create renderer
    const renderer = c.SDL_CreateRenderer(window, null) orelse {
        std.debug.print("Renderer could not be created! SDL_Error: {s}\n", .{c.SDL_GetError()});
        return error.RendererCreationFailed;
    };

    return .{
        .renderer = renderer,
        .inner = window,
        .font = self.font,
    };
}

pub fn cleanup(self: @This()) void {
    if (self.window) |win| {
        c.SDL_DestroyRenderer(win.renderer);
        _ = c.SDL_StopTextInput(win.inner);
        c.SDL_DestroyWindow(win.inner);
    }
    c.SDL_Quit();
    c.TTF_Quit();
}
