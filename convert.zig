const std = @import("std");

pub fn main() !void {

    // Static file buffer for the PBM data from STDIN.
    const file_max = 10_000; // My actual PBM files from GIMP are ~8k
    var buffer: [file_max]u8 = undefined;

    // Read it all in. If it doesn't fit, it's probably not right anyway.
    const stdin = std.io.getStdIn().reader();
    _ = try stdin.readAll(&buffer);

    // +----------------------------------------------------------------+
    // |      BEGIN extremely loose and fragile PBM header checker.     |
    // +----------------------------------------------------------------+
    //
    // Must be "P1", meaning: 1-bit PBM ASCII file
    if (buffer[0] != 'P' or buffer[1] != '1') {
        std.debug.print("ERROR: Expected P1 but got {x}{x}.\n", .{ buffer[0], buffer[1] });
        std.os.exit(1);
    }

    // Now start scanning for the size: "128 64"
    const the_one_true_size = "128 64";
    const size_of_size = 6; // hard codin' because it will always be this
    var found = false;
    var in_comment = false;
    var img_start: usize = 0;
    for (buffer[2..], 2..) |b, i| {

        // Handle comments
        if( in_comment ) {
            // scan 'til newline
            if( b == '\n' ){
                in_comment = false;
            }
            continue;
        }
        if( b == '#' ){
            in_comment = true;
            continue;
        }

        // If we found the start of the size...
        if( b == the_one_true_size[0] ) {
            found = true; // hopeful
            for(buffer[i..(i+size_of_size)], the_one_true_size) |bi,o| {
                if(bi!=o){
                    std.debug.print("ERROR: Couldn't match size '{s}' with given '{s}'\n", .{ buffer[i..(i+size_of_size)], the_one_true_size });
                    std.os.exit(1);
                }
            }
            // if we get here, we're good!
            // save the position
            img_start = i+size_of_size+1;
            break;
        }
    }

    if(!found){
	std.debug.print("ERROR: Scanned whole file and never found expected size in header: '{s}'\n", .{ the_one_true_size });
	std.os.exit(1);
    }

    // If we got this far, it looks like this image is going to work. :-)
    //
    // +----------------------------------------------------------------+
    // |       END extremely loose and fragile PBM header checker.      |
    // +----------------------------------------------------------------+
    //
    // Now we translate the "bits" (image pixels) into page/column
    // bit positions (1 byte per page column) for the SSD1306 RAM.
    //
    // NOTE: I originally stored these bits as u1 (1-bit binary numbers).
    //       But Zig aligns these to the nearest byte anyway, so there
    //       was no memory savings and it was actually _less_ convenient
    //       to get them out of the array.
    const bit_count = 128 * 64;
    var bit_buffer: [bit_count]u8 = undefined;

    // Sadly, I do have to keep track of my own counter for the bit
    // buffer because it won't be in sync with the file buffer.
    var input_bit: usize = 0;

    // Now read from file buffer. Store any '1' or '0' found. (We should
    // really just ignore whitespace characters, but ignoring anything
    // that isn't a binary number is easier.)
    for(buffer[img_start..])|b|{

        // We only care about image pixels.
	if(b=='1' or b=='0'){

            // Integer division gives us the start position of
            // this bit's page row (1024 bits per page).
            var page = input_bit / 1024 * 1024;

            // There are 128 columns, 8 bits per column. We
            // write to the low bit of all bytes first, then
            // the second bit and so forth, always jumping
            // by 8 bits get to the next column.
            //
            // See math.zig for how I arrived at this. (Well,
            // that and some paper and a pen and a couch.)
            var n = input_bit - page;
            var pos = ((n % 128) * 8) + (n / 128);
            bit_buffer[page + pos] = if( b=='1') 1 else 0;

            input_bit += 1;
	}
    }

    // Write out the bits in "page/col" order for the SSD1306
    // One byte at a time.
    const stdout = std.io.getStdOut().writer();
    var bit_idx: u16 = 0;
    while (bit_idx < bit_count) : (bit_idx += 8) {

        var my_byte: u8 = bit_buffer[bit_idx];
        my_byte += bit_buffer[bit_idx + 1] << 1;
        my_byte += bit_buffer[bit_idx + 2] << 2;
        my_byte += bit_buffer[bit_idx + 3] << 3;
        my_byte += bit_buffer[bit_idx + 4] << 4;
        my_byte += bit_buffer[bit_idx + 5] << 5;
        my_byte += bit_buffer[bit_idx + 6] << 6;
        my_byte += bit_buffer[bit_idx + 7] << 7;
        try stdout.writeByte(my_byte);
    }
}
