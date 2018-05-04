#!/usr/bin/env tarantool

require('strict').on()
local tap = require('tap')
local test = tap.test('utils')
test:plan(15)

------------------------------------------------------------------------------

local checks = require('checks')
local function fails(func, ...)
    local params = {...}
    local ok = pcall(function()
        func(unpack(params))
    end)
    return not ok
end

checkers.positive_number = function (n)
    return type(n) == 'number' and n > 0
end

local function foo(number, optional_string, positive_number, opt)
    checks('number', '?string', '?positive_number', {
        table = {
            optional_number = '?number',
            string = '?string'
        },
        pos_number_or_string = '?positive_number|string'
    })
end

-- old functionality
test:ok(not fails(foo, 3), 'must not fail')
test:ok(not fails(foo, 5, 'abacaba'), 'must not fail')
test:ok(not fails(foo, 5, 'abacaba', 1), 'must not fail')
test:ok(fails(foo, 'abc'), 'must fail - 1st argument not a number')
test:ok(fails(foo, 3, 5), 'must fail - 2st argument not a string or nil')
test:ok(fails(foo, 3, {}), 'must fail - 2st argument not a string or nil')
test:ok(fails(foo, 3, {}), 'must fail - 2st argument not a string or nil')
test:ok(fails(foo, 5, 'abacaba', 0), 'must fail - 3rd argument not a positive number')
test:ok(not fails(foo, 5, 'abacaba', setmetatable({}, {__type = 'positive_number'})), 'must not fail')

-- new functionality with options
test:ok(
    not fails(
        foo, 5, 'abacaba', 1,
        {
            table = {optional_number = 3},
            pos_number_or_string = 'abacaba'
        }
    ),
    'must not fail'
)

test:ok(
    not fails(
        foo, 5, 'abacaba', nil,
        {
            table = {optional_number = 3},
            pos_number_or_string = 3.14
        }
    ),
    'must not fail'
)

test:ok(
    not fails(
        foo, 5, 'abacaba', 1234.1234,
        {
            pos_number_or_string = 3.14
        }
    ),
    'must not fail'
)

test:ok(
    fails(
        foo, 5, 'abacaba', 66,
        {
            pos_number_or_string = {}
        }
    ),
    'must fail - pos_number_or_string is not table'
)

test:ok(
    fails(
        foo, 5, 'abacaba', 1,
        {
            table = {optional_number = 'somestring'}
        }
    ),
    'must fail - optional_number is not string'
)

test:ok(
    fails(
        foo, 5, 'abacaba', 5,
        {
            unexpected_key = 'ur mom gay',
            another_unexpected_key = 'no you'
        }
    ),
    'must fail - unexpected_key'
)
