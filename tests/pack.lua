-- The pack library needs these and they modify the global namespace, so they are added here to make sure pack doesn't pollute the global namespace
require('string')
require('table')
require('bit')

state.pack = {
    g_count_pre = util.rawcount(_G),
}

-- General tests

require('pack')

-- Check global variable leaking
assert.equals(util.rawcount(_G), state.pack.g_count_pre, 'pack/_G count')
assert.exists(string.pack, 'pack/string.pack')
assert.exists(string.unpack, 'pack/string.unpack')

-- Setup
local nul = string.char(0)

local cache = {}

local assert_pack = function(tag, format, expected, ...)
    if not cache[format] then
        cache[format] = {}
    end

    local packed = string.pack(format, ...)
    local list = cache[format]
    list[#list + 1] =
    {
        values = {...},
        packed = packed,
        tag = tag,
    }

    assert.binary_equals(packed, expected, tag)
end

-- Testing string.pack for integers

do
    local nums =
    {
        0x00,
        0x01,
        0x30,
        0x48,
        0x60,
        0x7F,
        0x80,
        0x81,
        0xFE,
        0xFF,
    }

    local lead_nums =
    {
        0x00,
        0x01,
        0x79,
        0x80,
        0xFF,
    }

    local signed =
    {
        c = true,
        h = true,
        i = true,
    }

    local assert_pack_number = function(format, ...)
        local value = 0
        local size = select('#', ...)
        local adjust = false
        for i = size, 1, -1 do
            value = value * 0x100
            value = value + select(i, ...)

            if i == size and value >= 0x80 and signed[format] then
                adjust = true
            end
        end

        if adjust then
            value = value - 2^(size * 8)
        end

        local tag = 'pack/' .. format .. ' 0x' .. string.format('%0' .. tostring(2 * size) .. 'X', value)
        assert_pack(tag, format, string.char(...), value)
    end

    for _, num in ipairs(nums) do
        assert_pack_number('c', num)
        assert_pack_number('C', num)
    end

    for _, lead in ipairs(lead_nums) do
        for _, num in ipairs(nums) do
            assert_pack_number('h', num, lead)
            assert_pack_number('H', num, lead)
        end
    end

    for _, lead1 in ipairs(lead_nums) do
        for _, lead2 in ipairs(lead_nums) do
            for _, lead3 in ipairs(lead_nums) do
                for _, num in ipairs(nums) do
                    assert_pack_number('i', num, lead3, lead2, lead1)
                    assert_pack_number('I', num, lead3, lead2, lead1)
                end
            end
        end
    end
end

-- Testing string.pack for floating point numbers

do
    local test_values =
    {
        {value = 0, positive = '\x00\x00\x00\x00', negative = '\x00\x00\x00\x80', positive_double = '\x00\x00\x00\x00\x00\x00\x00\x00', negative_double = '\x00\x00\x00\x00\x00\x00\x00\x80'},
        {value = 1.40129846432481707e-45, positive = '\x01\x00\x00\x00', negative = '\x01\x00\x00\x80', positive_double = '\x00\x00\x00\x00\x00\x00\xA0\x36', negative_double = '\x00\x00\x00\x00\x00\x00\xA0\xB6'},
        {value = 0.999999940395355225, positive = '\xFF\xFF\x7F\x3F', negative = '\xFF\xFF\x7F\xBF', positive_double = '\x00\x00\x00\xE0\xFF\xFF\xEF\x3F', negative_double = '\x00\x00\x00\xE0\xFF\xFF\xEF\xBF'},
        {value = 1, positive = '\x00\x00\x80\x3F', negative = '\x00\x00\x80\xBF', positive_double = '\x00\x00\x00\x00\x00\x00\xF0\x3F', negative_double = '\x00\x00\x00\x00\x00\x00\xF0\xBF'},
        {value = 1.00000011920928955, positive = '\x01\x00\x80\x3F', negative = '\x01\x00\x80\xBF', positive_double = '\x00\x00\x00\x20\x00\x00\xF0\x3F', negative_double = '\x00\x00\x00\x20\x00\x00\xF0\xBF'},
        {value = 1.99999988079071045, positive = '\xFF\xFF\xFF\x3F', negative = '\xFF\xFF\xFF\xBF', positive_double = '\x00\x00\x00\xE0\xFF\xFF\xFF\x3F', negative_double = '\x00\x00\x00\xE0\xFF\xFF\xFF\xBF'},
        {value = 2, positive = '\x00\x00\x00\x40', negative = '\x00\x00\x00\xC0', positive_double = '\x00\x00\x00\x00\x00\x00\x00\x40', negative_double = '\x00\x00\x00\x00\x00\x00\x00\xC0'},
        {value = 2.0000002384185791, positive = '\x01\x00\x00\x40', negative = '\x01\x00\x00\xC0', positive_double = '\x00\x00\x00\x20\x00\x00\x00\x40', negative_double = '\x00\x00\x00\x20\x00\x00\x00\xC0'},
        {value = 3.4028234663852886e+38, positive = '\xFF\xFF\x7F\x7F', negative = '\xFF\xFF\x7F\xFF', positive_double = '\x00\x00\x00\xE0\xFF\xFF\xEF\x47', negative_double = '\x00\x00\x00\xE0\xFF\xFF\xEF\xC7'},
        {value = 1/0, positive = '\x00\x00\x80\x7F', negative = '\x00\x00\x80\xFF', positive_double = '\x00\x00\x00\x00\x00\x00\xF0\x7F', negative_double = '\x00\x00\x00\x00\x00\x00\xF0\xFF'},
    }

    for index, test in ipairs(test_values) do
        assert_pack('pack/f 0 >> ' .. tostring(index), 'f', test.positive, test.value)
        assert_pack('pack/f 0 >> -' .. tostring(index), 'f', test.negative, -test.value)
        assert_pack('pack/d 0 >> ' .. tostring(index), 'd', test.positive_double, test.value)
        assert_pack('pack/d 0 >> -' .. tostring(index), 'd', test.negative_double, -test.value)
    end

    assert_pack('pack/d 0 >> dmax', 'd', '\xFF\xFF\xFF\xFF\xFF\xFF\xEF\x7F', 1.79769313486231571e+308)
    assert_pack('pack/d 0 >> -dmax', 'd', '\xFF\xFF\xFF\xFF\xFF\xFF\xEF\xFF', -1.79769313486231571e+308)
end

-- Testing string.pack for booleans

assert_pack('pack/bool false', 'B', string.char(0), false)
assert_pack('pack/bool true', 'B', string.char(1), true)

-- Testing string.pack for strings

assert_pack('pack/string 1', 'S4', 'abc' .. nul, 'abc')
assert_pack('pack/string 2', 'S20', nul:rep(20), '')
assert_pack('pack/string 3', 'S4', 'test', 'test')

assert_pack('pack/string 5', 'z', 'abc' .. nul, 'abc')
assert_pack('pack/string 6', 'z', nul, '')

-- Testing string.pack for binary data

assert_pack('pack/binary 1', 'x3', 'abc', 'abc')
assert_pack('pack/binary 2', 'x4', nul:rep(4), nul:rep(4))
assert_pack('pack/binary 3', 'x8', '\x12\x34\x56\x78\x9A\xBC\xDE\xF0', '\x12\x34\x56\x78\x9A\xBC\xDE\xF0')

-- Error cases for string.pack

assert.no_error(function() string.pack('c', 0) end, 'pack/error: number sanity')
assert.error(function() string.pack('c', false) end, 'pack/error: number<>boolean')
assert.error(function() string.pack('c', '') end, 'pack/error: number<>string')
assert.error(function() string.pack('c', {}) end, 'pack/error: number<>table')

assert.no_error(function() string.pack('B', false) end, 'pack/error: boolean sanity')
assert.error(function() string.pack('B', 0) end, 'pack/error: boolean<>number')
assert.error(function() string.pack('B', '') end, 'pack/error: boolean<>string')
assert.error(function() string.pack('B', {}) end, 'pack/error: boolean<>table')

assert.no_error(function() string.pack('S1', '') end, 'pack/error: string sanity')
assert.error(function() string.pack('S1', 0) end, 'pack/error: string<>number')
assert.error(function() string.pack('S1', false) end, 'pack/error: string<>boolean')
assert.error(function() string.pack('S1', {}) end, 'pack/error: string<>table')
assert.error(function() string.pack('S1', 'xy') end, 'pack/error: string overflow')

assert.error(function() string.pack('S', '') end, 'pack/error: string no length')
assert.error(function() string.pack('b', 0) end, 'pack/error: bit no length')
assert.error(function() string.pack('x', '\x00') end, 'pack/error: binary no length')

assert.error(function() string.pack('i') end, 'pack/error: too few params')
assert.error(function() string.pack('i', 0, 0) end, 'pack/error: too many params')

assert.error(function() string.pack('z2', '') end, 'pack/error: zstring multiple')
assert.error(function() string.pack('zi', '', 0) end, 'pack/error: zstring not last')
--TODO: size mismatch?

-- Testing string.pack for combinations

local var_size =
{
    S = true,
    b = true,
}

local assert_pack_combined = function(format, ...)
    local res = ''
    local index = 0
    for code, count_str in format:gmatch('(%a)(%d*)') do
        count = tonumber(count_str) or 1

        if var_size[code] then
            index = index + 1
            res = res .. string.pack(code .. count_str, (select(index, ...)))
        else
            while count > 0 do
                index = index + 1
                res = res .. string.pack(code, (select(index, ...)))

                count = count - 1
            end
        end
    end

    assert_pack('pack/combined ' .. format, format, res, ...)
end

assert_pack_combined('ccBIhf', 12, -7, true, 0x87654321, -12345, 2.5)
assert_pack_combined('BB3i', true, false, false, true, 3)
assert_pack_combined('fS10i', -0.875, 'test', 333)

-- Testing string.pack for bits

assert_pack('pack/b 1', 'b3', string.char(3), 3)
assert_pack('pack/b 2', 'b7', string.char(123), 123)
assert_pack('pack/b 3', 'b32', string.char(0x21, 0x43, 0x65, 0x87), 0x87654321)
assert_pack('pack/b 4', 'b3b5', string.char(0x59), 1, 11)
assert_pack('pack/b 5', 'b5b10b1', string.char(0xC3, 0x04), 3, 38, 0)
assert_pack('pack/b 6', 'b6b16b2', string.char(0xDF, 0xFF, 0xBF), 0x1F, 0xFFFF, 0x02)
assert_pack('pack/b 7', 'b6b32b2', string.char(0xDF, 0xFF, 0XFF, 0xFF, 0xBF), 0x1F, 0xFFFFFFFF, 0x02)

assert_pack('pack/q 1', 'q8', string.char(0xCC), false, false, true, true, false, false, true, true)
assert_pack('pack/q 2', 'qq3', string.char(0x0C), false, false, true, true)

assert_pack('pack/bq 1', 'b5b10qi', string.char(0xC3, 0x04, 0x67, 0x45, 0x23, 0x01), 3, 38, false, 0x01234567)
assert_pack('pack/bq 2', 'b5qb10S4', string.char(0x83, 0x09) .. 'meh' .. string.char(0), 3, false, 38, 'meh')

assert_pack('pack/bq 3', 'b5C', string.char(0x1F, 0x44), 0x1F, 0x44)
assert_pack('pack/bq 4', 'q3Cb1H', string.char(0x05, 0xFF, 0x01, 0x34, 0x12), true, false, true, 0xFF, 0x01, 0x1234)

-- -- Testing string.unpack, reverse of string.pack

for format, list in pairs(cache) do
    for _, entry in ipairs(list) do
        -- if format:match('b5qb10S4') then
            assert.sequence_equals({string.unpack(entry.packed, format)}, entry.values, 'un' .. entry.tag)
        -- end
    end
end
