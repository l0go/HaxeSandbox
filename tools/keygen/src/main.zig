const std = @import("std");
const Chameleon = @import("chameleon").Chameleon;
const base64 = std.base64.standard;
const sha256 = std.crypto.hash.sha2.Sha256;

const length = 24;

pub fn main() !void {
    // Create allocator
    var ally = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer ally.deinit();

    // Initialize stdout
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Generate some random bytes to generate the base64 from
    var bytes: [length]u8 = undefined;
    std.crypto.random.bytes(&bytes);

    // Generate the base64
    var b64 = try ally.allocator().alloc(u8, base64.Encoder.calcSize(length));
    b64 = @constCast(base64.Encoder.encode(b64, &bytes));

    // And the sha256 hash
    var hash: [32]u8 = undefined;
    sha256.hash(b64, &hash, .{});

    // Now print everything to the user
    comptime var cham = Chameleon.init(.Auto);
    try stdout.print(cham.redBright().fmt(
        \\
        \\ _   _                     _____                    _  _                  
        \\| | | |                   /  ___|                  | || |                 
        \\| |_| |  __ _ __  __  ___ \ `--.   __ _  _ __    __| || |__    ___  __  __
        \\|  _  | / _` |\ \/ / / _ \ `--. \ / _` || '_ \  / _` || '_ \  / _ \ \ \/ /
        \\| | | || (_| | >  < |  __//\__/ /| (_| || | | || (_| || |_) || (_) | >  < 
        \\\_| |_/ \__,_|/_/\_\ \___|\____/  \__,_||_| |_| \__,_||_.__/  \___/ /_/\_\
        \\
        \\
        \\
    ), .{});
    try stdout.print(cham.yellow().fmt("Run this command to save the hashed key:\n"), .{});
    try stdout.print(cham.grey().fmt("printf \"{s}\" | podman secret create --replace haxe_authkey -\n\n"), .{std.fmt.fmtSliceHexLower(&hash)});
    try stdout.print(cham.yellow().fmt("The following is the base64 key you should provide to HaxeSandbox during requests. Keep this secret!\n"), .{});
    try stdout.print(cham.grey().fmt("{s}\n"), .{b64});

    try bw.flush();
}
