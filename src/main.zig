const std = @import("std");
const Allocator = std.mem.Allocator;

fn postRequest(allocator: Allocator, uri: std.Uri, json_payload: []const u8) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var buf: [1024]u8 = undefined;
    var req = try client.open(.POST, uri, .{ .server_header_buffer = &buf });
    defer req.deinit();

    req.transfer_encoding = .{ .content_length = json_payload.len };
    try req.send();
    var wtr = req.writer();
    try wtr.writeAll(json_payload);
    try req.finish();
    try req.wait();

    var rdr = req.reader();
    const body = try rdr.readAllAlloc(allocator, 1024 * 1024 * 4);
    return body;
}

const GEMINI_API_KEY = "";
fn postGemini(allocator: Allocator, prompt: []const u8) !void {
    _ = prompt;
    const url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" ++ GEMINI_API_KEY;

    const json_payload =
        \\ {
        \\     "contents": [
        \\         {
        \\             "parts": [
        \\                 {
        \\                     "text": "write a joke"
        \\                 }
        \\             ]
        \\         }
        \\     ]
        \\ }
    ;
    defer allocator.free(json_payload);

    const response = try postRequest(allocator, std.Uri.parse(url) catch unreachable, json_payload);
    defer allocator.free(response);

    std.log.info("Response: {s}", .{response});
}

pub fn main() !void {
    std.log.info("Hello, world!", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    try postGemini(allocator, "How does AI work?");
}
