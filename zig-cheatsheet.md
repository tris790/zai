# Zig Programming Cheat Sheet

This guide condenses the key ideas from Chapter 1 of the Zig book, emphasizing Zig's syntax, semantics, workflows, and philosophy. It distills nuanced language details, technical rules, compiler constraints, and examples for direct application by AI or technical users.

---

## 1. Zig Philosophy and Paradigm

- Zig is a **low-level, general-purpose, modern programming language** designed for safety, control, and simplicity.
- Major design goal: **Less is more** (removes confusing/unsafe C/C++ behaviors; adds consistency).
- No preprocessor macros. Eliminates hidden, hard-to-debug code generation.
- Default: **Readability, predictability, and clarity** over feature richness or magic behaviors.
- Core workflow: Debug your application, not your language knowledge.

---

## 2. Project Initialization and Structure

### 2.1 Initializing a Project

- `zig init` in a new directory creates:
    - `build.zig`          — Zig-based build script (not Make/CMake).
    - `build.zig.zon`      — JSON-like project/dependency definition.
    - `src/main.zig`       — Main executable entry point.
    - `src/root.zig`       — Library root module (use if exporting a library).

### 2.2 Zig Modules and File Organization

- Each `.zig` file = module.
- `main.zig` → For executables; must contain a `main()` function.
- `root.zig` → For libraries; serves as library interface root.

### 2.3 Build System

- Zig has a *native build system*—build scripts are written in Zig itself.
- No need for external Make, CMake, or Ninja.
- The build system is extensible and integrated (one-stop tooling).
- `build.zig.zon` handles dependency/package management, similar to Node's `package.json` or Rust's `Cargo.toml`.

---

## 3. Fundamentals: Syntax and Semantics

### 3.1 Imports

- Use `@import("modulename")` to bring modules into scope.
- Analogue to `#include` in C/C++ and `import` in Python/JavaScript.

### 3.2 Constants and Variables (Objects / Identifiers)

- Declare immutable: `const name = value;`
- Declare mutable:   `var name: Type = value;`
    - For mutable (`var`), type annotation *mandatory* unless value is immediately assigned.
- Uninitialized: `var name: Type = undefined;` (should be avoided; use only when necessary).
- Every object must be used or explicitly discarded. Otherwise, compile-time error.
    - Discard pattern: `_ = obj;` destroys `obj` for rest of scope.
- All `var` (mutable) objects must be mutated. If not mutated → compile error suggesting to use `const`.
- No unused or "pointless" declarations allowed.

### 3.3 Functions

- Syntax: `fn name(arg1: Type1, arg2: Type2) ReturnType { ... }`
    - Must annotate all parameter and return types.
    - Return type follows parameters and is always explicit.
    - `export` keyword: Expose function in public (library) API.
    - `pub` keyword: Makes function visible to other modules.

#### Example:

```zig
export fn add(a: i32, b: i32) i32 {
    return a + b;
}
```

### 3.4 Error Handling

- Zig does **not** have exceptions; uses error unions:
    - `fn foo() !ReturnType` — function may return a value or an error.
    - `try` keyword: Unwraps a possible error; if error, propagates up and prints stack trace.
- `catch` exists, but not in traditional try/catch sense.

#### Example:

```zig
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, world!\n", .{});
}
```

### 3.5 Compilation & Running

- Build executable: `zig build-exe src/main.zig`
- Build library:     `zig build-lib src/root.zig`
- Build object:      `zig build-obj src/whatever.zig`
- Compile+run:       `zig run src/main.zig`
- Build whole project (using build.zig): `zig build`
    - Output in `zig-out` directory.

**Zig does not require external build tools. Everything is orchestrated via `zig` and Zig-based build scripts.**

---

## 4. Primitive Types

- Unsigned integers: `u8`, `u16`, `u32`, `u64`, `u128`
- Signed integers:   `i8`, `i16`, `i32`, `i64`, `i128`
- Floating point:    `f16`, `f32`, `f64`, `f128`
- Boolean:           `bool`
- Pointer/integer:   `usize`, `isize`
- C ABI types:       `c_char`, `c_int`, etc.
- Type annotations: always with colon (e.g., `name: i32`).

---

## 5. Arrays & Slices

### 5.1 Static Arrays

- Syntax: `[N]Type{...}` — fixed-size array.
    - Example: `const xs = [4]u8{1,2,3,4};`
    - `[ _ ]Type{...}` — compiler infers length.
- Arrays cannot change size after allocation.

### 5.2 Selecting Elements

- Single element: `xs[2]` (zero-based).
- Range/slice: `xs[1..3]` — yields a slice from index 1 up to (not including) 3.
- Full slice: `xs[0..xs.len]` — covers entire array.
- End-inclusive (Python-style): Use `start..` syntax, e.g., `xs[1..]` to slice from 1 to end.

### 5.3 Slices

- Slices `[]Type` = (pointer, length).
- Syntax: `slice = arr[start..end]`
- Slice safety: length is tracked, enabling bounds-checking.
- Property: `slice.len` gives length.

- **Slices with compile-time-known indices** enable pointer operations.
- **Slices with runtime-known range** (e.g., after reading an unknown-length file) do *not* enable pointer operations (no dereference with `.*`).

### 5.4 Array Operators

- Concatenation: `a ++ b` (if both sizes known at compile time).
- Replication:   `a ** n` (repeat array `a`, n times).
    - Only works with statically-sized arrays.

#### Example:

```zig
const a = [_]u8{1,2,3};
const b = [_]u8{4,5};
const c = a ++ b; // [5]u8{1,2,3,4,5}
const d = a ** 2; // [6]u8{1,2,3,1,2,3}
```

---

## 6. Blocks and Scopes

- Block = `{ ... }` ; delimits scope.
- Each block introduces a new scope: objects are local to the block.
- You can nest blocks arbitrarily.
- Block labels with `label: { ... }`
    - Use `break :label value;` to exit the block with value (block as expression).

#### Example:

```zig
const x = add_one: {
    var y: i32 = 123;
    y += 1;
    break :add_one y;
};
// x == 124
```

---

## 7. Strings

### 7.1 Representation

- String literals = null-terminated, fixed-size arrays of `u8` (i.e., C strings but with explicit length in type).
    - Type: `*const [len:0]u8`
- String slices:   `[]const u8`  or  `[]u8`
    - Most std functions accept strings as slices.

### 7.2 Iterating and Inspecting

- To iterate over bytes: `for (str) |byte| { ... }`
- To iterate over *Unicode code points*: Use `std.unicode.Utf8View`.
    - Handles multi-byte UTF-8 encoding (e.g., non-ASCII characters).

#### Example (iterate bytes):

```zig
for (string_object) |byte| {
    // byte is u8; use {X} for hex
}
```

#### Example (iterate Unicode codepoints):

```zig
var utf8 = try std.unicode.Utf8View.init("アメリカ");
var iterator = utf8.iterator();
while (iterator.nextCodepointSlice()) |codepoint| {
    // codepoint is []const u8
}
```

### 7.3 String Utilities

- Compare:             `std.mem.eql(u8, str1, str2)`
- Split by char:       `std.mem.splitScalar(u8, str, delimiter)`
- Split by substring:  `std.mem.splitSequence(u8, str, needle)`
- Starts/ends with:    `std.mem.startsWith(u8, str, prefix)` / `std.mem.endsWith(u8, str, suffix)`
- Trim:                `std.mem.trim(u8, str, chars)`
- Concatenate:         `std.mem.concat(allocator, u8, &[_][]const u8{ ... })`
- Replace:             `std.mem.replace(u8, str, old, new, buffer)`

> **Note:** Many utilities operate on slices, not null-terminated arrays.

### 7.4 Types

- Use `@TypeOf(obj)` to query object's type at compile time.
- Examples:
    - `[4]i32` — array of 4 `i32`.
    - `*const [16:0]u8` — pointer to 16-byte null-terminated array (string literal).
    - `[]const u8` — slice of `u8` (string slice).

---

## 8. Platform Pitfalls

### 8.1 Initialization Timing (Windows Specific)

- All global-scope variables in Zig are **initialized at compile-time**.
- Access to resources available only at runtime (e.g., `std.io.getStdOut()`) cannot be used for global inits—on Windows, causes "unable to evaluate comptime expression" error.
- Solution: Move all such initializations into function bodies—function-scope variables are initialized at runtime.

---

## 9. Memory Safety and General Safety

- Zig is **not** memory-safe by default.
- Provides **tools** for improved safety, but does *not* enforce safe usage:
    - `defer` and `errdefer` for resource cleanup and exception-safe freeing.
    - Non-nullable pointers and objects by default (no implicit nullability).
    - Testing allocators can help catch memory leaks and double-frees.
    - Array and slice bounds are checked.
    - Exhaustive `switch` statements.
    - Forced error handling—compiler checks that all possible errors are handled.

---

## 10. Learning Zig: Resources

- Official Documentation: https://ziglang.org/documentation/master/
- Standard Library Docs:   https://ziglang.org/documentation/master/std/
- Community: Reddit, Ziggit, Discord, Slack (see official repo/wiki).
- Examples:
    - Bun (JS runtime), Mach (game engine), Llama 2 (ML), TigerBeetle (finance DB), zig-clap, capy, zls, libxev (event-loop).
- Exercises:
    - Ziglings (https://github.com/ratfactor/ziglings)
    - Advent of Code solutions on GitHub.

---

## 11. Idiomatic Notes

- Zig encourages **constants by default** (`const`), mutable variables (`var`) only when actual mutation is required.
- Compiler enforces **no unused objects** and **required mutation** for all mutable objects.
- **Explicitness**: Types, lifetimes, and mutability must be clear in code—compiler will error out on ambiguous or potentially unsafe code.
- No hidden allocations: All allocations/z frees are explicit; no standard library functions perform allocations behind your back (as can happen in C++ STL or Python).
- **Imports** are explicit and function-based, not statement-based.
- **Error handling** is not automatic exception-based; it's explicit and propagates in function signatures (`!Type`).
- Avoid `undefined` values unless absolutely necessary; always prefer initializing objects at declaration.

---

## 12. Math and Code Template Examples

### 12.1 Defining Functions

```zig
pub fn sum(a: i32, b: i32) i32 {
    return a + b;
}
```

### 12.2 Mutable vs. Immutable

```zig
const pi = 3.14;      // Immutable; value never changes
var   count: u32 = 0; // Mutable; must be mutated later

// Use (mutate) count at least once; else compiler error
count += 1;
```

### 12.3 Discarding Unused Values

```zig
const unused = 5;
_ = unused; // Discards 'unused'
```

### 12.4 Working with Arrays and Slices

```zig
const data = [5]u8{10, 20, 30, 40, 50};
const slice = data[2..4]; // slice == {30,40}
const full_slice = data[0..data.len]; // all elements
```

### 12.5 Concatenating and Repeating Arrays

```zig
const a = [_]u8{1, 2, 3};
const b = [_]u8{4, 5};
const c = a ++ b; // {1,2,3,4,5}
const d = a ** 2; // {1,2,3,1,2,3}
```

### 12.6 String as Slice Example

```zig
const str: []const u8 = "Hello, Zig!";
_ = str.len; // 11
for (str) |byte| {
    // Processing each byte of string
}
```

### 12.7 Unicode Iteration

```zig
var utf8 = try std.unicode.Utf8View.init("アメリカ");
var iterator = utf8.iterator();
while (iterator.nextCodepointSlice()) |codepoint| {
    // codepoint is []const u8 -- a full UTF-8 character
}
```

---

End of cheat sheet.