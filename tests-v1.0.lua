#!/usr/bin/env tarantool

require('strict').on()
msgpack = require('msgpack')
local tap = require('tap')
local checks = require('checks')
local test = tap.test('checks_test')
test:plan(1)

------------------------------------------------------------------------------

checkers.positive_number = function (n)
    return type(n) == 'number' and n > 0
end


function fn_number_optstring(arg1, arg2)
    checks('number', '?string')
end

function fn_positive_number(arg1)
    checks('positive_number')
end

------------------------------------------------------------------------------

local function test_err(test, code, expected_error)
    local fn = loadstring(code)
    local ok, err = pcall(fn)

    if expected_error == nil then
        local testname = code .. ' - nil'
        test:is(err, nil, testname)
    else
        local testname = string.format('%s - %s', code, expected_error:gsub('%%', ''))
        test:like(err, expected_error, testname)
    end
    -- body
end

test:test('v1.0', function(test)
    test:plan(11)
    test_err(test, 'fn_number_optstring(1)')
    test_err(test, 'fn_number_optstring(1, nil)')
    test_err(test, 'fn_number_optstring(2, "s")')
    test_err(test, 'fn_number_optstring(3, "s", "excess")')
    test_err(test, 'fn_number_optstring(4, 0)',
        'bad argument #2 to fn_number_optstring %(string expected, got number%)')
    test_err(test, 'fn_number_optstring(5, {})',
        'bad argument #2 to fn_number_optstring %(string expected, got table%)')
    test_err(test, 'fn_number_optstring(6, msgpack.NULL)',
        'bad argument #2 to fn_number_optstring %(string expected, got cdata%)')
    test_err(test, 'fn_number_optstring("7")',
        'bad argument #1 to fn_number_optstring %(number expected, got string%)')

    test_err(test, 'fn_positive_number(8)')
    test_err(test, 'fn_positive_number(setmetatable({}, {__type = "positive_number"}))')
    test_err(test, 'fn_positive_number(0)',
        'bad argument #1 to fn_positive_number %(positive_number expected, got number%)')
end)

os.exit(test:check())
