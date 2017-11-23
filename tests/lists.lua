state.lists = {
    g_count_pre = util.rawcount(_G),
}

-- General tests

local L = require('lists')

-- Check global variable leaking
assert.equals(util.rawcount(_G), state.lists.g_count_pre, 'lists/_G count')
assert.exists(L, 'lists/L')

-- Testing constructors

assert.exists(L{}, 'lists/L{}')
assert.exists(L{1, 2, 3}, 'lists/L{...}')
assert.exists(L{1, 1, 1, 2, 2, 2}, 'set/L{mult}')
do
    local t = {1, 2, 3}
    assert.exists(L(t), 'lists/L(t)')
    assert.not_exists(getmetatable(t), 'lists/L(t) metatable')
end

-- Testing operators

assert.equals(L{}, L{}, 'lists/L{}==L{}')
assert.equals(L{1, 2, 'a', 'b', 'c'}, L{1, 2, 'a', 'b', 'c'}, 'lists/L{...}==L{...}')
assert.not_equals(L{1, 2}, L{2, 1}, 'lists/L{1, 2}==L{2, 1}')
assert.not_equals(L{{}}, L{{}}, 'lists/L{{}}==L{{}}')

assert.equals(#L{}, 0, 'lists/#L{}')
assert.equals(#L{1, 2, 3}, 3, 'lists/#L{1, 2, 3}')
assert.equals(#L{1, 1, 2, 'a'}, 4, 'lists/#L{mult}')

assert.equals(L{} .. L{}, L{}, 'lists/extend 1')
assert.equals(L{1, 2} .. L{3, 4}, L{1, 2, 3, 4}, 'lists/extend 2')
assert.equals(L{1, 2} .. L{}, L{1, 2}, 'lists/extend 3')
assert.equals(L{1, 2} .. L{'a', 'b'}, L{1, 2, 'a', 'b'}, 'lists/extend 4')

assert.equals(L{1, 2}[1], 1, 'lists/index 1')
assert.error(function() util.run(L{1, 2}[5]) end, 'lists/index 2')
assert.no_error(function() util.run(L{1, 2}['a']) end, 'lists/index 3')

do
    local l = L{1, 2, 3}
    l[2] = 5
    assert.equals(l[2], 5, 'lists/new index 1')
end
assert.error(function() L{}[1] = 1 end, 'lists/new index 2')
assert.no_error(function() L{1, 2, 3}['a'] = 1 end, 'lists/new index 3')

assert.equals(tostring(L{}), '[]', 'lists/tostring 1')
assert.equals(tostring(L{1, 2, 3}), '[1, 2, 3]', 'lists/tostring 2')
assert.equals(tostring(L{'a', 'b', 'c'}), '[a, b, c]', 'lists/tostring 3')

-- Methods

assert.is_true(L{1}:contains(1), 'lists/contains 1')
assert.is_true(L{1, 2, 3}:contains(3), 'lists/contains 2')
assert.is_false(L{}:contains(1), 'lists/contains 3')

assert.is_false(L{}:any(), 'lists/any1')
assert.is_true(L{1}:any(), 'lists/any2')

do
    local original = L{}
    local returned = original:add(1)
    assert.equals(returned, nil, 'lists/add exists 1')
    assert.equals(original, L{1}, 'lists/add 1')
end
do
    local original = L{1, 2, 3}
    local returned = original:add(4)
    assert.equals(returned, nil, 'lists/add exists 2')
    assert.equals(original, L{1, 2, 3, 4}, 'lists/add 2')
end

do
    local original = L{1, 2, 3}
    local returned = original:insert(3, 4)
    assert.equals(returned, nil, 'lists/insert exists 1')
    assert.equals(original, L{1, 2, 4, 3}, 'lists/insert 1')
end
do
    local original = L{1, 2, 3}
    local returned = original:insert(2, 4)
    assert.equals(returned, nil, 'lists/insert exists 2')
    assert.equals(original, L{1, 4, 2, 3}, 'lists/insert 2')
end
assert.error(function() L{}:insert(1, 1) end, L{1}, 'lists/insert 3')

do
    local original = L{1, 2}
    local returned = original:remove_element(2)
    assert.equals(returned, nil, 'lists/remove element exists 1')
    assert.equals(original, L{1}, 'lists/remove element 1')
end
do
    local original = L{2, 2, 2}
    local returned = original:remove_element(2)
    assert.equals(returned, nil, 'lists/remove element exists 2')
    assert.equals(original, L{2, 2}, 'lists/remove element 2')
end
do
    local original = L{1, 2, 3}
    local returned = original:remove_element(4)
    assert.equals(returned, nil, 'lists/remove element exists 3')
    assert.equals(original, L{1, 2, 3}, 'lists/remove element 3')
end
do
    local original = L{3, 2, 1}
    local returned = original:remove_element(3)
    assert.equals(returned, nil, 'lists/remove element exists 4')
    assert.equals(original, L{2, 1}, 'lists/remove element 4')
end

do
    local l1 = L{1, 3}
    local removed1 = l1:remove(2)
    assert.equals(l1, L{1}, 'lists/remove 1')
    assert.equals(removed1, 3, 'lists/remove 1 (value)')
    local l2 = L{2, 2, 2}
    local removed2 = l2:remove(2)
    assert.equals(l2, L{2, 2}, 'lists/remove 2')
    assert.equals(removed2, 2, 'lists/remove 2 (value)')
    local l3 = L{3, 2, 1}
    local removed3 = l3:remove(3)
    assert.equals(l3, L{3, 2}, 'lists/remove 3')
    assert.equals(removed3, 1, 'lists/remove 3 (value)')
end
assert.error(function() L{1, 2, 3}:remove(4) end, 'lists/remove 4')

do
    local l = L{'a', 'b', 'c'}
    l:remove(2)
    assert.equals(l, L{'a', 'c'}, 'lists/remove 1')
    assert.error(function() L{1, 2, 3}:remove(4) end, 'lists/remove 2')
end

