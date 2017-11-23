require('debug')
require('string')
require('table')

print('Initiating test run...')

settings = {
    show_pass = false,
    show_fail = true,
}

current = nil
last_tag = nil
results = {}

util = {
    rawcount = function(t)
        local count = 0

        local key = next(t)
        while key ~= nil do
            count = count + 1
            key = next(t, key)
        end

        return count
    end,
    fail = function(tag, message)
        print('    - ' .. tag .. ': ' .. message)
    end,
    pass = function(tag)
        print('    - ' .. tag)
    end,
    assert = function(condition, tag, message)
        last_tag = tag
        results[current][condition == true and 'pass' or 'fail'][tag] = message
    end,
    run = function(...)
    end,
    hexify = function(str)
        local hex = ''
        for index, byte in ipairs({str:byte(1, #str)}) do
            if index > 1 then
                hex = hex .. ' '
            end
            hex = hex .. string.format('%02X', byte)
        end
        return hex
    end,
    concat = function(t)
        local res = ''
        for index, value in ipairs(t) do
            if index > 1 then
                res = res .. ', '
            end
            res = res .. tostring(value)
        end
        return res
    end
}

assert = {
    equals = function(actual, expected, tag)
        util.assert(actual == expected, tag, 'Expected "' .. tostring(expected) .. '", got "' .. tostring(actual) .. '"')
    end,
    binary_equals = function(actual, expected, tag)
        util.assert(actual == expected, tag, 'Expected "' .. util.hexify(expected) .. '", got "' .. util.hexify(actual) .. '"')
    end,
    sequence_equals = function(actual, expected, tag)
        local success = #actual == #expected
        for index, value in ipairs(actual) do
            success = success and value == expected[index]
        end
        util.assert(success, tag, 'Expected (' .. util.concat(expected) .. '), got (' .. util.concat(actual) .. ')')
    end,
    not_equals = function(actual, not_expected, tag)
        util.assert(actual ~= not_expected, tag, 'Did not expect "' .. tostring(not_expected) .. '"')
    end,
    exists = function(actual, tag)
        util.assert(actual ~= nil, tag, 'Expected value, got ' .. tostring(actual) .. '.')
    end,
    not_exists = function(actual, tag)
        util.assert(actual == nil, tag, 'Expected nil, got ' .. tostring(actual) .. '.')
    end,
    is_true = function(actual, tag)
        util.assert(actual == true, tag, 'Test was false.')
    end,
    is_false = function(actual, tag)
        util.assert(actual == false, tag, 'Test was not false.')
    end,
    error = function(fn, tag)
        util.assert(not pcall(fn), tag, 'No error where expected.')
    end,
    no_error = function(fn, tag)
        util.assert(pcall(fn), tag, 'Error during operation.')
    end,
    one_of = function(actual, options, tag)
        local found = false
        local message = ''
        for key, option in pairs(options) do
            if actual == option then
                found = true
            end
            if message == '' then
                message = tostring(option)
            else
                message = message .. ',' .. tostring(option)
            end
        end
        util.assert(found, tag, 'Expected one of {' .. message .. '}, got ' .. tostring(actual) .. '.')
    end,
    type = function(actual, expected, tag)
        util.assert(type(actual) == expected, tag, 'Expected type "' .. tostring(expected) .. '", got "' .. type(actual) .. '"')
    end,
}

state = {}

test = function(name)
    current = name
    results[current] = {
        pass = {},
        fail = {},
    }

    -- Run test
    print()
    print('Running tests for ' .. current)
    require('tests.' .. current)

    print('Results for ' .. current .. ':')

    print('  - Passed tests: ' .. tostring(util.rawcount(results[current].pass)))
    if settings.show_pass then
        for tag, message in pairs(results[current].pass) do
            util.pass(tag, message)
        end
    end
    print('  - Failed tests: ' .. tostring(util.rawcount(results[current].fail)))
    if settings.show_fail then
        for tag, message in pairs(results[current].fail) do
            util.fail(tag, message)
        end
    end

    current = nil
end

test('pack')
-- test('sets')
-- test('lists')
-- test('enumerable')

print()
print('Finished tests!')

