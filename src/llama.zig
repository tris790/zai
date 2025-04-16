const std = @import("std");
const Allocator = std.mem.Allocator;

const BASE_URL = "http://localhost:11434";

const headers_max_size = 1024;
const body_max_size = 65536;

pub fn main() !void {
    std.debug.print("Ai.\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    // const prompt: GenerateModel = .{
    //     .model = "qwen2.5-coder",
    //     .prompt = "what color is the sky?",
    //     .stream = false,
    // };
    // try generate(allocator, prompt);

    var enums = [3][]const u8{ "hex", "rgb", "hsl" };
    var required = [2][]const u8{ "location", "format" };
    var tools: [2]ToolModel = .{
        .{
            .type = "function",
            .function = .{
                .name = "get_color",
                .description = "Get the color of an object",
                .parameters = .{
                    .type = "object",
                    .properties = .{
                        .location = .{
                            .type = "string",
                            .description = "The location of the object",
                        },
                        .format = .{
                            .type = "string",
                            .description = "The format of the color",
                            .@"enum" = &enums,
                        },
                    },
                    .required = &required,
                },
            },
        },
        .{
            .type = "function",
            .function = .{
                .name = "get_object_size",
                .description = "Get the size of an object",
                .parameters = .{
                    .type = "object",
                    .properties = .{
                        .location = .{
                            .type = "string",
                            .description = "The location of the object",
                        },
                        .format = .{
                            .type = "string",
                            .description = "The format of the color",
                            .@"enum" = &enums,
                        },
                    },
                    .required = &required,
                },
            },
        },
    };
    const tools_available_prompt = try tools_adapter(allocator, &tools);
    var chat_messages: [2]ChatMessageModel = .{
        .{ .role = "system", .content = tools_available_prompt },
        .{ .role = "user", .content = "what color is the sky" },
    };
    const chat_prompt: ChatModel = .{
        .model = "olmo2:13b",
        .messages = &chat_messages,
        .stream = false,
        // .tools = &tools,
    };
    try chat(allocator, chat_prompt);
}

fn tools_adapter(allocator: Allocator, tools: []ToolModel) ![]const u8 {
    _ = allocator;
    _ = tools;
    const message =
        \\At each turn, if you decide to invoke any of the function(s), it should be wrapped with ```tool_code```. The python methods described below are imported and available, you can only use defined methods. The generated code should be readable and efficient. The response to a method will be wrapped in ```tool_output``` use it to call more tools or generate a helpful, friendly response. When using a ```tool_call``` think step by step why and how it should be used.
        \\
        \\The following Python methods are available:
        \\
        \\```python
        \\def convert(amount: float, currency: str, new_currency: str) -> float:
        \\    """Convert the currency with the latest exchange rate
        \\
        \\    Args:
        \\      amount: The amount of currency to convert
        \\      currency: The currency to convert from
        \\      new_currency: The currency to convert to
        \\    """
        \\
        \\def get_exchange_rate(currency: str, new_currency: str) -> float:
        \\    """Get the latest exchange rate for the currency pair
        \\
        \\    Args:
        \\      currency: The currency to convert from
        \\      new_currency: The currency to convert to
        \\    """
        \\```
        \\
        \\User: \{user_message\}
    ;
    return message;
}

// fn create_tool_template(allocator: Allocator, prompt: ToolModel) !void {
//     var tool_template = std.ArrayList(u8).init(allocator);
//     var writer = tool_template.writer();
//     // format looks like this:
//     // def function_name(amount: float, currency: str, new_currency: str) -> str:
//     writer.write("def ");
//     writer.write(prompt.function.name);
//     writer.write("(");
//     for (prompt.function.parameters.properties) |arg| {
//         writer.write(arg.name);
//         writer.write(": ");
//         writer.write(arg.type);
//         writer.write(", ");
//     }
//     writer.write(") -> str:\n");
//     writer.write("    \"\"\"");
//     writer.write(prompt.function.description);
//     writer.write("\n\n");
//     writer.write("    Args:");

//     for (prompt.function.parameters.properties) |arg| {
//         writer.write("      ");
//         writer.write(arg.name);
//         writer.write(": ");
//         writer.write(arg);
//         writer.write(", ");
//     }
// }

fn generate(allocator: Allocator, prompt: GenerateModel) !void {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(BASE_URL ++ "/api/generate");
    const json_prompt_payload = try std.json.stringifyAlloc(allocator, prompt, .{});
    const body = try postRequest(allocator, uri, json_prompt_payload);
    defer allocator.free(body);

    // try std.json.parseFromSlice(GenerateResponseModel, allocator, body, .{});
}

fn chat(allocator: Allocator, prompt: ChatModel) !void {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(BASE_URL ++ "/api/chat");
    const json_prompt_payload = try std.json.stringifyAlloc(allocator, prompt, .{});
    const body = try postRequest(allocator, uri, json_prompt_payload);
    defer allocator.free(body);

    std.log.info("Response: {s}", .{body});
    const response = try std.json.parseFromSlice(ChatResponseModel, allocator, body, .{});
    defer response.deinit();
    const chat_response = response.value;

    if (chat_response.message.tool_calls) |tools_to_call| {
        for (tools_to_call) |tool| {
            std.log.info("Models wants to call {s}", .{tool.function.name});
        }
    }
}

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

const ChatMessageModel = struct {
    role: []const u8,
    content: []const u8,
};

const ChatModel = struct {
    model: []const u8,
    messages: []ChatMessageModel,
    stream: bool,
    tools: ?[]ToolModel = null,
};

const GenerateModel = struct {
    model: []const u8,
    prompt: []const u8,
    stream: bool,
};

const ToolModel = struct {
    type: []const u8,
    function: FunctionModel,
};

const FunctionModel = struct {
    name: []const u8,
    description: []const u8,
    parameters: ParameterModel,
};

const ParameterModel = struct {
    type: []const u8,
    properties: PropertyModel,
    required: [][]const u8,
};

const PropertyModel = struct {
    location: LocationModel,
    format: FormatModel,
};

const LocationModel = struct {
    type: []const u8,
    description: []const u8,
};

const FormatModel = struct {
    type: []const u8,
    description: []const u8,
    @"enum": [][]const u8,
};

const ArgumentResponseModel = struct {
    format: []const u8,
    location: []const u8,
};

const FunctionResponseModel = struct {
    name: []const u8,
    arguments: ArgumentResponseModel,
};

const ToolResponseModel = struct {
    function: FunctionResponseModel,
};

const MessageResponseModel = struct {
    role: []const u8,
    content: []const u8,
    tool_calls: ?[]ToolResponseModel,
};

const ChatResponseModel = struct {
    model: []const u8,
    created_at: []const u8,
    message: MessageResponseModel,
    done_reason: []const u8,
    done: bool,
    total_duration: u64,
    load_duration: u64,
    prompt_eval_count: u64,
    prompt_eval_duration: u64,
    eval_count: u64,
    eval_duration: u64,
};

const ChatRes = ChatResponseModel;
