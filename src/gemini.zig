const std = @import("std");
const web_client = @import("web_client.zig");
const ai = @import("ai.zig");

const GEMINI_API_KEY = "";

const GeminiPart = struct {
    text: []const u8,
};

const GeminiContent = struct {
    parts: []const GeminiPart,
    role: ?[]const u8 = null,
};

const Candidate = struct {
    content: GeminiContent,
    finishReason: []const u8,
    avgLogprobs: f64,
};

const PromptFeedback = struct {};

const UsageMetadata = struct {};

const GeminiResponse = struct {
    candidates: []Candidate,
    usageMetadata: ?UsageMetadata = .{},
    modelVersion: []const u8,
    promptFeedback: ?PromptFeedback = .{},
};

const GeminiRequest = struct {
    contents: []const GeminiContent,
};

pub fn postGemini(allocator: std.mem.Allocator, prompt: []const u8) !ai.AiResponse {
    const url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" ++ GEMINI_API_KEY;

    const payload = GeminiRequest{
        .contents = &[_]GeminiContent{
            GeminiContent{
                .parts = &[_]GeminiPart{
                    GeminiPart{ .text = prompt },
                },
            },
        },
    };

    const stringified_payload = try std.json.stringifyAlloc(allocator, payload, .{});
    defer allocator.free(stringified_payload);

    const response = try web_client.postRequest(allocator, std.Uri.parse(url) catch unreachable, stringified_payload);
    defer allocator.free(response);
    const gemini_response = try std.json.parseFromSlice(GeminiResponse, allocator, response, .{
        .ignore_unknown_fields = true,
    });

    // Todo: Do something with other parts
    return .{
        .text = gemini_response.value.candidates[0].content.parts[0].text,
    };
}
