const std = @import("std");

pub fn main() !void {
    // Total bits as bytes that we'll read from STDIN.
    const size = (128 * 64) / 8;
    var buffer: [size]u8 = undefined;

    // Read it all in - it has to be this exact size
    // or it's not right anyway.
    const stdin = std.io.getStdIn().reader();
    const bytes_read = try stdin.readAll(&buffer);

    if(bytes_read != size){
        std.debug.print("Expected to read {d} bytes, but read {d}.\n", .{ size, bytes_read});
        std.os.exit(1);
    }

    // Loop over every page
    for(0..8)|page|{

        var page_offset = page * 128;
        
        // Each row (bit) per page
        for(0..8)|bit|{

            const shiftby = @intCast(u3, bit);

            // Loop over every column
            for(0..128)|col|{
                
                // shift bits over by the bit number and mask off all but last
                var val = (buffer[page_offset+col] >> shiftby) & 1;

                if(val==1){
                    std.debug.print("@", .{});
                }
                else{
                    std.debug.print(".", .{});
                }
            }

            std.debug.print("\n", .{});

	}
    }
}
