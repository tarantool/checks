#!/usr/bin/env tarantool

require('strict').on()
msgpack = require('msgpack')
local tap = require('tap')
local checks = require('checks')
local test = tap.test('checks_test')

------------------------------------------------------------------------------

function checkers.positive_number(n)
    return type(n) == 'number' and n > 0
end

function fn_number_optstring(arg1, arg2)
    checks('number', '?string')
end

function fn_second_number(arg1, arg2)
    checks(nil, 'number')
end

function fn_number_or_string(arg1)
    checks('number|string')
end

function fn_positive_number(arg1)
    checks('positive_number')
end

function fn_options(options)
    checks({
        mystring = '?string',
        mynumber = '?number',
    })
end

function fn_inception(options)
    checks({
        we = {
            need = {
                to = {
                    go = {
                        deeper = "?number",
                    },
                },
            },
        },
    })
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

test:plan(37)
test_err(test, 'fn_number_optstring(1)')
test_err(test, 'fn_number_optstring(1, nil)')
test_err(test, 'fn_number_optstring(2, "s")')
test_err(test, 'fn_number_optstring(3, "s", "excess")')
test_err(test, 'fn_number_optstring(4, 0)',
    'bad argument #2 to fn_number_optstring %(%?string expected, got number%)')
test_err(test, 'fn_number_optstring(5, {})',
    'bad argument #2 to fn_number_optstring %(%?string expected, got table%)')
test_err(test, 'fn_number_optstring(6, msgpack.NULL)')
test_err(test, 'fn_number_optstring("7")',
    'bad argument #1 to fn_number_optstring %(number expected, got string%)')

test_err(test, 'fn_positive_number(8)')
test_err(test, 'fn_positive_number(setmetatable({}, {__type = "positive_number"}))')
test_err(test, 'fn_positive_number(0)',
    'bad argument #1 to fn_positive_number %(positive_number expected, got number%)')

test_err(test, 'fn_number_or_string(100)')
test_err(test, 'fn_number_or_string("s")')
test_err(test, 'fn_number_or_string(nil)',
    'bad argument #1 to fn_number_or_string %(number|string expected, got nil%)')
test_err(test, 'fn_number_or_string(msgpack.NULL)',
    'bad argument #1 to fn_number_or_string %(number|string expected, got cdata%)')
test_err(test, 'fn_number_or_string(true)',
    'bad argument #1 to fn_number_or_string %(number|string expected, got boolean%)')

test_err(test, 'fn_second_number(nil, 5)')
test_err(test, 'fn_second_number("s", 5)')
test_err(test, 'fn_second_number(100, 5)')
test_err(test, 'fn_second_number(true, 5)')
test_err(test, 'fn_second_number(nil, "s")',
    'bad argument #2 to fn_second_number %(number expected, got string%)')

test_err(test, 'fn_options(1)',
    'bad argument #1 to fn_options %(%?table expected, got number%)')
test_err(test, 'fn_options({mystring = "s"})')
test_err(test, 'fn_options({mynumber = 1})')
test_err(test, 'fn_options({mynumber = "bad"})',
    'bad argument options.mynumber to fn_options %(%?number expected, got string%)')
test_err(test, 'fn_options({badfield = "bad"})',
    'unexpected argument options.badfield to fn_options')

test_err(test, 'fn_inception()', nil)
test_err(test, 'fn_inception({})', nil)
test_err(test, 'fn_inception({we = {}})', nil)
test_err(test, 'fn_inception({we = {need = {}}})', nil)
test_err(test, 'fn_inception({we = {need = {to = {}}}})', nil)
test_err(test, 'fn_inception({we = {need = {to = {go = {}}}}})', nil)
test_err(test, 'fn_inception({we = {need = {to = {go = {deeper = 0}}}}})', nil)
test_err(test, 'fn_inception({we = {need = {to = {go = {deeper = {}}}}}})',
    'bad argument options.we.need.to.go.deeper to fn_inception %(%?number expected, got table%)')

local function check_options(options)
    checks({
        a = {
            b = {
                c = '?',
            },
        },
    })
    test:is_deeply(options, {a={b={c=nil}}}, 'options == {a={b={c=nil}}}')
end
check_options()

test_err(test, 'checks("?string", 5)',
    'checks: argument type number is not supported')
test_err(test, 'checks({param = 5})',
    'checks: argument type number is not supported')


os.exit(test:check())