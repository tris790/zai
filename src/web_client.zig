const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn postRequest(allocator: Allocator, uri: std.Uri, json_payload: []const u8) ![]const u8 {
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
