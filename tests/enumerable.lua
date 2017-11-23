-- General tests

local g_count_pre = util.rawcount(_G)
local make = require('enumerable')

-- Check global variable leaking
assert.equals(util.rawcount(_G), g_count_pre, 'enumerable/_G count')
assert.exists(make, 'enumerable/return')
assert.type(make, 'function', 'enumerable/return type')

-- Helpers

local make_msg = function(tag, name)
    return function(text)
        return text .. ' (' .. tag .. ': ' .. name .. ')'
    end
end
local contains = function(t, v)
    for _, el in pairs(t) do
        if el == v then
            return true
        end
    end

    return false
end
local subset_of = function(t1, t2)
    if _G['x'] then print('iterating...') end
    for _, el in pairs(t1) do
        if _G['x'] then print(_, el) end
        if not contains(t2, el) then
            return false
        end
    end

    return true
end
local same_content = function(t1, t2)
    return subset_of(t1, t2) and subset_of(t2, t1)
end

-- Testing conversions

local test_empty = function(meta, suffix)
    local msg = make_msg('empty', suffix)
    local t = setmetatable({}, meta)

    assert.exists(meta.__index, msg('enumerable/exists __index'))
    assert.exists(meta.__len, msg('enumerable/exists __len'))
    assert.equals(getmetatable(t), meta, msg('enumerable/meta'))

    assert.exists(t.any, msg('enumerable/exists any'))
    assert.exists(t.all, msg('enumerable/exists all'))
    assert.exists(t.count, msg('enumerable/exists count'))
    assert.exists(t.copy, msg('enumerable/exists copy'))
    assert.exists(t.clear, msg('enumerable/exists clear'))
    assert.exists(t.contains, msg('enumerable/exists contains'))
    assert.exists(t.enumerate, msg('enumerable/exists enumerate'))
    assert.exists(t.totable, msg('enumerable/exists totable'))
    assert.exists(t.aggregate, msg('enumerable/exists aggregate'))
    assert.exists(t.select, msg('enumerable/exists select'))
    assert.exists(t.where, msg('enumerable/exists where'))
    assert.exists(t.take, msg('enumerable/exists take'))
    assert.exists(t.skip, msg('enumerable/exists skip'))
    assert.exists(t.first, msg('enumerable/exists first'))
    assert.exists(t.single, msg('enumerable/exists single'))

    assert.equals(#t, 0, msg('enumerable/# 1'))
    assert.equals(t:any(), false, msg('enumerable/any 1'))
    assert.equals(t:all(), true, msg('enumerable/all 1'))
    assert.equals(t:count(), 0, msg('enumerable/count 1'))
    assert.equals(t:contains(1), false, msg('enumerable/contains 1'))
    assert.equals(t:enumerate()(t), nil, msg('enumerable/enumerate 1'))

    local raw_t = t:totable()
    assert.exists(raw_t, msg('enumerable/totable 1'))
    assert.not_exists(getmetatable(raw_t), msg('enumerable/totable 2'))
    assert.equals(util.rawcount(raw_t), t:count(), msg('enumerable/totable 3'))

    assert.is_true(same_content(t:select(function() return 1 end), {}), msg('enumerable/select'))
    assert.is_true(same_content(t:where(function() return true end), {}), msg('enumerable/where'))
    assert.equals(t:aggregate(function() return 'res' end), nil, msg('enumerable/aggregate 1'))
    assert.equals(t:aggregate('res', function() return 'res' end), 'res', msg('enumerable/aggregate 2'))
    assert.equals(t:aggregate(true, function() return 'res' end, tostring), 'true', msg('enumerable/aggregate 3'))
    assert.is_true(same_content(t:take(2), {}), msg('enumerable/take'))
    assert.is_true(same_content(t:skip(2), {}), msg('enumerable/skip'))
    assert.equals(t:first(), nil, msg('enumerable/first 1'))
    assert.equals(t:first(function() return true end), nil, msg('enumerable/first 2'))
    assert.equals(t:single(), nil, msg('enumerable/single 1'))
    assert.equals(t:single(function() return true end), nil, msg('enumerable/single 2'))
end

local test_filled = function(meta, suffix)
    local msg = make_msg('filled', suffix)
    local tt = {}
    local t = setmetatable({
        [2] = false,
        ['a'] = 'b',
        [tt] = tt,
    }, meta)

    assert.equals(#t, 3, msg('enumerable/# 2'))
    assert.equals(t:count(), 3, msg('enumerable/count 2'))
    assert.equals(t:count(function(v) return type(v) == 'table' end), 1, msg('enumerable/count 3'))

    assert.equals(t:any(), true, msg('enumerable/any 2'))
    assert.is_true(t:any(function(v) return type(v) == 'boolean' end), msg('enumerable/any 3'))
    assert.is_false(t:any(function(v) return type(v) == 'userdata' end), msg('enumerable/any 4'))

    assert.is_false(t:all(function(v) return type(v) == 'table' end), msg('enumerable/all 2'))
    assert.is_true(t:all(function(v) return v ~= nil end), msg('enumerable/all 3'))

    assert.is_true(t:contains(false), msg('enumerable/contains 2'))
    assert.is_true(t:contains('b'), msg('enumerable/contains 3'))
    assert.is_false(t:contains('a'), msg('enumerable/contains 5'))
    assert.is_false(t:contains({}), msg('enumerable/contains 6'))

    do -- select
        local mapped = t:select(type)
        assert.exists(mapped, msg('enumerable/select exists'))
        assert.equals(getmetatable(mapped), meta, msg('enumerable/select meta'))
        assert.equals(#mapped, #t, msg('enumerable/select __len'))
        assert.is_true(same_content(mapped, {'string', 'boolean', 'table'}), msg('enumerable/select content 1'))
        assert.is_true(same_content(t:select(function(v) return v end), t), msg('enumerable/select identity'))
        assert.is_true(same_content(t:select(tostring), {'false', 'b', tostring(tt)}), msg('enumerable/select content 2'))
    end

    do -- where
        local filtered = t:where(function(v) return not v end)
        assert.exists(filtered, msg('enumerable/where exists'))
        assert.equals(getmetatable(filtered), meta, msg('enumerable/where meta'))
        assert.equals(#filtered, 1, msg('enumerable/where __len'))
        assert.is_true(same_content({false}, filtered), msg('enumerable/where content 1'))
        assert.is_true(same_content(t:where(function() return true end), {false, 'b', tt}), msg('enumerable/where identity'))
        assert.is_true(same_content(t:where(function(v) return type(v) ~= 'table' end), {false, 'b'}), msg('enumerable/where content 2'))
    end

    do -- aggregate 1
        local reduced = t:aggregate(function(acc, v) return type(acc) .. tostring(type(v)) end)
        assert.exists(reduced, msg('enumerable/aggregate exists 1'))
        assert.equals(type(reduced), 'string', msg('enumerable/aggregate type 1'))
        assert.one_of(reduced, {'stringboolean', 'stringstring', 'stringtable'}, msg('enumerable/aggregate value 1'))
    end

    do -- aggregate 2
        local reduced = t:aggregate(2, function(acc, v) return acc + (type(v) == 'boolean' and 12 or #v) end)
        assert.exists(reduced, msg('enumerable/aggregate exists 2'))
        assert.equals(type(reduced), 'number', msg('enumerable/aggregate type 2'))
        assert.equals(reduced, 15, msg('enumerable/aggregate value 2'))
    end

    do -- aggregate 3
        local reduced = t:aggregate(2, function(acc, v) return acc + (type(v) == 'boolean' and 12 or #v) end, tostring)
        assert.exists(reduced, msg('enumerable/aggregate exists 3'))
        assert.equals(type(reduced), 'string', msg('enumerable/aggregate type 3'))
        assert.equals(reduced, '15', msg('enumerable/aggregate value 3'))
    end

    do -- taken
        local taken = t:take(2)
        assert.equals(#taken, 2, msg('enumerable/take 1'))
        assert.is_true(subset_of(taken, t), msg('enumerable/take 2'))
        assert.is_true(same_content(t:take(0), {}), msg('enumerable/take 3'))
        assert.is_true(same_content(t:take(5), t), msg('enumerable/take 4'))
    end

    do -- skip
        local skipped = t:skip(2)
        assert.equals(#skipped, 1, msg('enumerable/skip 1'))
        assert.is_true(subset_of(skipped, t), msg('enumerable/skip 2'))
        assert.is_true(same_content(t:skip(0), t), msg('enumerable/skip 3'))
        assert.is_true(same_content(t:skip(5), {}), msg('enumerable/skip 4'))
    end

    do -- copy
        local copy = t:copy()
        assert.exists(copy, msg('enumerable/copy exists'))
        assert.equals(getmetatable(copy), meta, msg('enumerable/copy meta'))
        assert.equals(#copy, #t, msg('enumerable/copy __len'))
        assert.is_true(same_content(copy, t), msg('enumerable/copy content'))
    end

    assert.is_true(contains(t, t:first()), msg('enumerable/first 1'))
    assert.equals(t:first(function(v) return type(v) == 'table' end), tt, msg('enumerable/first 2'))
    assert.equals(t:first(function(v) return type(v) == 'nil' end), nil, msg('enumerable/first 3'))
    assert.error(function() t:first(false) end, msg('enumerable/first 4'))

    assert.equals(t:single(), nil, msg('enumerable/single 1'))
    assert.equals(t:single(function(v) return type(v) == 'table' end), tt, msg('enumerable/single 2'))
    assert.equals(t:single(function(v) return type(v) == 'nil' end), nil, msg('enumerable/single 3'))
    assert.equals(t:single(function(v) return type(v) ~= 'nil' end), nil, msg('enumerable/single 4'))
    assert.error(function() t:single(false) end, msg('enumerable/single 5'))
end

--        assert.(, msg('enumerable/'))

local test_enumerable = function(meta, tag)
    local result = make(meta)
    assert.exists(result, 'enumerable/result ' .. tag)
    assert.equals(util.rawcount(meta), 6, 'enumerable/meta count ' .. tag)

    test_empty(meta, tag)

    return result
end

do -- basic
    local meta = {}

    local constructor = test_enumerable(meta, 'basic')

    test_filled(meta, 'basic')
end

do -- add append
    local meta
    meta = {
        __create = function()
            return setmetatable({}, meta)
        end,
        __add_element = function(t, v)
            t[#t] = v
        end
    }

    local constructor = test_enumerable(meta, 'add append')

    test_filled(meta, 'add append')
end

do -- remove
    local meta
    meta = {
        __create = function()
            return setmetatable({}, meta)
        end,
        __remove_key = function(t, k)
            t[k] = nil
        end
    }

    local constructor = test_enumerable(meta, 'remove')

    test_filled(meta, 'remove')
end

assert.equals(util.rawcount(_G), g_count_pre, 'enumerable/_G count')

