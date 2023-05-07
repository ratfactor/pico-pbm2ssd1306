const std = @import("std");

pub fn main() !void {
    var nums = [_]u16{
        0,1,2,3,4,5,6,7,8,9,10,
        125,126,127,128,129,130,
        1022,1023,1024,1025,1026,
        2046,2047,2048,2049,2050,
    };

    for(nums)|i|{
        var page=i/1024*1024;
        var n=i-page;
        var col=(n%128)*8;
        var row=n/128;
        std.debug.print("{d: <4} {d: <4} {d: <4} {d: <4} {d: <4}\n", .{
            i,
            page,
            col,
            row,
            page+col+row,
        });
    }
}
