state.sets = {
    g_count_pre = util.rawcount(_G),
}

-- General tests

local S = require('sets')

-- Check global variable leaking
assert.equals(util.rawcount(_G), state.sets.g_count_pre, 'sets/_G count')
assert.exists(S, 'sets/S')

-- Testing constructors

assert.exists(S{}, 'sets/S{}')
assert.exists(S{1, 2, 3}, 'sets/S{...}')
assert.exists(S{1, 1, 1, 2, 2, 2}, 'set/S{mult}')
do
    local t = {1, 2, 3}
    assert.exists(S(t), 'sets/S(t)')
    assert.not_exists(getmetatable(t), 'sets/S(t) metatable')
end

-- Testing operators

assert.equals(S{}, S{}, 'sets/S{}==S{}')
assert.equals(S{1, 2}, S{2, 1}, 'sets/S{1, 2}==S{2, 1}')
assert.equals(S{1, 2, 3, 'a', 'b', 'c'}, S{'b', 'c', 2, 'a', 1, 3}, 'sets/S{...}==S{...}')
assert.equals(S{1, 1, 1, 1, 2, 2, 2}, S{2, 1, 2, 1}, 'sets/S{mult}==S{mult}')
assert.not_equals(S{{}}, S{{}}, 'sets/S{{}}==S{{}}')

assert.equals(#S{}, 0, 'sets/#S{}')
assert.equals(#S{1, 2, 3}, 3, 'sets/#S{1, 2, 3}')
assert.equals(#S{1, 1, 1, 2, 2, 2}, 2, 'sets/#S{mult}')

assert.equals(S{1, 2} + S{}, S{1, 2}, 'sets/union 1')
assert.equals(S{1, 2} + S{3, 4}, S{1, 2, 3, 4}, 'sets/union 2')
assert.equals(S{1, 2} + S{2, 3}, S{1, 2, 3}, 'sets/union 3')
assert.equals(S{1, 2, 3} + S{2, 3}, S{1, 2, 3}, 'sets/union 4')

assert.equals(S{1, 2} * S{}, S{}, 'sets/intersection 1')
assert.equals(S{1, 2} * S{3, 4}, S{}, 'sets/intersection 2')
assert.equals(S{1, 2} * S{2, 3}, S{2}, 'sets/intersection 3')
assert.equals(S{1, 2, 3} * S{2, 3}, S{2, 3}, 'sets/intersection 4')

assert.equals(S{} - S{1, 2, 3}, S{}, 'sets/difference 1')
assert.equals(S{1, 2} - S{1, 2, 3}, S{}, 'sets/difference 2')
assert.equals(S{1, 2, 3} - S{2, 4}, S{1, 3}, 'sets/difference 3')
assert.equals(S{1, 2, 3} - S{}, S{1, 2, 3}, 'sets/difference 4')

assert.equals(S{} ^ S{1, 2, 3}, S{1, 2, 3}, 'sets/symmetric difference 1')
assert.equals(S{1, 2} ^ S{1, 2, 3}, S{3}, 'sets/symmetric difference 2')
assert.equals(S{1, 2, 3} ^ S{2, 4}, S{1, 3, 4}, 'sets/symmetric difference 3')
assert.equals(S{1, 2, 3} ^ S{}, S{1, 2, 3}, 'sets/symmetric difference 4')

assert.is_true(S{} < S{1}, 'sets/strict subset 1')
assert.is_false(S{} < S{}, 'sets/strict subset 2')
assert.is_true(S{1, 2} < S{1, 2, 3, 4}, 'sets/strict subset 3')
assert.is_false(S{1, 2} < S{1, 3, 4}, 'sets/strict subset 4')

assert.is_true(S{} <= S{1}, 'sets/subset 1')
assert.is_true(S{} <= S{}, 'sets/subset 2')
assert.is_true(S{1, 2} <= S{1, 2, 3, 4}, 'sets/subset 3')
assert.is_false(S{1, 2} <= S{1, 3, 4}, 'sets/subset 4')

assert.equals(tostring(S{}), '{}', 'sets/tostring 1')
assert.one_of(tostring(S{1, 2}), {'{1, 2}', '{2, 1}'}, 'sets/tostring 2')
assert.one_of(tostring(S{'a', 'b'}), {'{a, b}', '{b, a}'}, 'sets/tostring 3')

assert.error(function() ipairs(S{}) end, 'sets/ipairs')

-- Testing operator immutability

do
    local original = S{1, 2, 3}
    local compare = S{1, 2, 3}
    local _ = original + S{4}
    assert.equals(original, compare, 'sets/union immutability')
    local _ = original * S{}
    assert.equals(original, compare, 'sets/intersection immutability')
    local _ = original - S{3}
    assert.equals(original, compare, 'sets/difference immutability')
    local _ = original ^ S{2, 3, 4}
    assert.equals(original, compare, 'sets/symmetric difference immutability')
end

-- Testing method mutability

do
    local original = S{1, 2, 3}
    local compare = S{1, 2, 3}
    local _ = original + S{4}
    assert.equals(original, compare, 'sets/union mutability')
    local _ = original * S{}
    assert.equals(original, compare, 'sets/intersection mutability')
    local _ = original - S{3}
    assert.equals(original, compare, 'sets/difference mutability')
    local _ = original ^ S{2, 3, 4}
    assert.equals(original, compare, 'sets/symmetric difference mutability')
end

-- Methods

assert.is_true(S{1}:contains(1), 'sets/contains 1')
assert.is_true(S{1, 2, 3}:contains(3), 'sets/contains 2')
assert.is_false(S{}:contains(1), 'sets/contains 3')

assert.is_false(S{}:any(), 'sets/any 1')
assert.is_true(S{1}:any(), 'sets/any 2')
assert.is_false(S{1, 2, 3}:any(function(v) return v > 3 end), 'sets/any 3')
assert.is_true(S{1, 2, 4, 3}:any(function(v) return v > 3 end), 'sets/any 3')
