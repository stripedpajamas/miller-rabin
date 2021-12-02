const std = @import("std");
const testing = std.testing;

// miller rabin algo, with pre-chosen bases that always work for small numbers
// since this fn takes a 32-bit int as input, we only need to check bases 2, 7, 61:
//      if n < 4,759,123,141, it is enough to test a = 2, 7, and 61
// in future, may make this fn allow 32 or 64 bit numbers, and use these bases:
//      a = 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, and 37
export fn isPrime(n: u32) bool {
    std.debug.assert(n >= 2);

    if (n < 3) return true;
    if (n % 2 == 0) return false;

    // step 1: compute r, d such that 2^r * d = n - 1
    var d: u32 = n - 1;
    var r: u32 = 0;
    while (d % 2 == 0) {
        d /= 2;
        r += 1;
    }

    // step 2: for each base b, compute m = b^d % n. if m = 1 or m = n - 1, continue; otherwise, return false

    const bases = [_]u32{ 2, 7, 61 };
    base_check: for (bases) |b| {
        if (b >= n) break;
        var m = pow(b, d, n);
        if (m == 1 or m == n - 1) continue;

        // we're allowed to square m r-1 times before we give up and return composite
        var i: u32 = 0;
        while (i < r) : (i += 1) {
            m = pow(m, 2, n);
            if (m == n - 1) continue :base_check;
        }

        return false;
    }

    return true;
}

// compute x^n mod m
fn pow(x: u32, n: u32, m: u32) u32 {
    if (n == 0) return 1;

    // we are going to be multiplying things together so
    // we need some more bit space to work in
    var _x = @as(u64, x);
    var _n = @as(u64, n);
    var _m = @as(u64, m);
    var y: u64 = 1;

    while (_n > 1) {
        _x = _x % _m; // reduce mod m before doing more mults
        if (_n % 2 == 0) {
            _x = (_x * _x) % _m;
            _n = _n / 2;
        } else {
            y = (_x * (y % _m)) % _m;
            _x = (_x * _x) % _m;
            _n = (_n - 1) / 2;
        }
    }

    return @truncate(u32, (_x * y) % _m);
}

test "basic prime checking" {
    const Case = struct {
        n: u32,
        expected: bool,
    };
    const cases = [_]Case{
        Case{ .n = 2, .expected = true },
        Case{ .n = 3, .expected = true },
        Case{ .n = 13, .expected = true },
        Case{ .n = 14, .expected = false },
        Case{ .n = 8, .expected = false },
        Case{ .n = 100, .expected = false },
        Case{ .n = 303, .expected = false },
        Case{ .n = 909, .expected = false },
        Case{ .n = 111, .expected = false },
        Case{ .n = 37, .expected = true },
        Case{ .n = 271, .expected = true },
        Case{ .n = 2147483647, .expected = true },
        Case{ .n = 524287, .expected = true },
        Case{ .n = 8191, .expected = true },
    };

    for (cases) |case| {
        std.log.warn("checking {}", .{case.n});
        try testing.expectEqual(isPrime(case.n), case.expected);
    }
}
