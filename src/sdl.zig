const c = @import("c.zig");
const std = @import("std");

pub fn sdl_main() !void {
    // Initialize SDL
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        return error.SDLInitializationError;
    }

    if (!c.TTF_Init()) {
        return error.TTFInitializationError;
    }

    // Create a window
    const window: ?*c.SDL_Window = c.SDL_CreateWindow(
        "SDL3 Simple Example",
        1920,
        1080,
        c.SDL_WINDOW_BORDERLESS | c.SDL_WINDOW_TRANSPARENT,
    );
    if (window == null) {
        c.TTF_Quit();
        c.SDL_Quit();
        return error.RendererCreationFailed;
    }

    // Create a renderer
    const renderer: ?*c.SDL_Renderer = c.SDL_CreateRenderer(window, null);
    if (renderer == null) {
        c.SDL_DestroyWindow(window);
        c.TTF_Quit();
        c.SDL_Quit();
        return error.WindowCreationFailed;
    }

    // Load font
    const font: ?*c.TTF_Font = c.TTF_OpenFont("/usr/share/fonts/TTF/OpenSans-Bold.ttf", 150); // Ensure arial.ttf is in the working directory
    if (font == null) {
        std.debug.print("Font loading failed: {*}\n", .{c.SDL_GetError()});
        c.SDL_DestroyRenderer(renderer);
        c.SDL_DestroyWindow(window);
        c.TTF_Quit();
        c.SDL_Quit();
        return error.FontLoadingFailed;
    }

    // Create text surface and texture
    const textColor = c.SDL_Color{ .r = 255, .g = 255, .b = 255, .a = 255 }; // White text
    const text: []const u8 = "Hello, SDL3!";
    const textSurface: ?*c.SDL_Surface = c.TTF_RenderText_Solid(font, @as([*c]const u8, text.ptr), text.len, textColor);
    if (textSurface == null) {
        std.debug.print("Text surface creation failed: {*}\n", .{c.SDL_GetError()});
        c.TTF_CloseFont(font);
        c.SDL_DestroyRenderer(renderer);
        c.SDL_DestroyWindow(window);
        c.TTF_Quit();
        c.SDL_Quit();
        return error.TextSurfaceCreationFailed;
    }

    const textTexture: ?*c.SDL_Texture = c.SDL_CreateTextureFromSurface(renderer, textSurface);
    if (textTexture == null) {
        std.debug.print("Text texture creation failed: {*}\n", .{c.SDL_GetError()});
        c.SDL_DestroySurface(textSurface);
        c.TTF_CloseFont(font);
        c.SDL_DestroyRenderer(renderer);
        c.SDL_DestroyWindow(window);
        c.TTF_Quit();
        c.SDL_Quit();
        return error.TextTextureCreationFailed;
    }
    const textWidth: f32 = @floatFromInt(textSurface.?.w);
    const textHeight: f32 = @floatFromInt(textSurface.?.h);

    // Get text dimensions
    c.SDL_DestroySurface(textSurface);

    // Main loop
    var running: bool = true;
    var event: c.SDL_Event = undefined;
    while (running) {
        // Handle events
        while (c.SDL_PollEvent(&event)) {
            if (event.type == c.SDL_EVENT_QUIT) {
                running = false;
            } else if (event.type == c.SDL_EVENT_MOUSE_BUTTON_DOWN) {
                // Get window position and size
                var win_x: c_int = 0;
                var win_y: c_int = 0;
                var win_w: c_int = 0;
                var win_h: c_int = 0;
                _ = c.SDL_GetWindowPosition(window, &win_x, &win_y);
                _ = c.SDL_GetWindowSize(window, &win_w, &win_h);

                // Get global mouse position
                var mouse_x: c_int = 0;
                var mouse_y: c_int = 0;
                _ = c.SDL_GetGlobalMouseState(@ptrCast(&mouse_x), @ptrCast(&mouse_y));

                // Check if click is outside window bounds
                if (mouse_x < win_x or mouse_x >= win_x + win_w or
                    mouse_y < win_y or mouse_y >= win_y + win_h)
                {
                    running = false; // Close the window
                }
            }
        }

        // Clear screen with transparent background
        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        _ = c.SDL_RenderClear(renderer);

        // Draw a colored grey background rectangle
        _ = c.SDL_SetRenderDrawColor(renderer, 33, 33, 33, 255);
        var rect: c.SDL_FRect = .{ .x = 0, .y = 0, .w = 900, .h = 300 };
        _ = c.SDL_RenderFillRect(renderer, &rect);

        // Draw text
        var textRect: c.SDL_FRect = .{
            .x = 0,
            .y = 0,
            .w = textWidth,
            .h = textHeight,
        };
        _ = c.SDL_RenderTexture(renderer, textTexture, null, &textRect);

        // Update screen
        _ = c.SDL_RenderPresent(renderer);

        // Small delay to avoid excessive CPU usage
        c.SDL_Delay(10);
    }

    // Cleanup
    c.SDL_DestroyRenderer(renderer);
    c.SDL_DestroyWindow(window);
}
