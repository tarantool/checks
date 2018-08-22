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

local _l_number_optstring = 2 + debug.getinfo(1).currentline
function fn_number_optstring(arg1, arg2)
    checks('number', '?string')
end

local _l_number_or_string = 2 + debug.getinfo(1).currentline
function fn_number_or_string(arg1)
    checks('number|string')
end

local _l_positive_number = 2 + debug.getinfo(1).currentline
function fn_positive_number(arg1)
    checks('positive_number')
end

local _l_anytype = 2 + debug.getinfo(1).currentline
function fn_anytype(arg1)
    checks('?')
end

local _l_nil_or_number_or_string = 2 + debug.getinfo(1).currentline
function fn_nil_or_number_or_string(arg1)
    checks('nil|number|string')
end

local _l_varargs = 2 + debug.getinfo(1).currentline
function fn_varargs(arg1, ...)
    checks('string')
end

local _l_options = 2 + debug.getinfo(1).currentline
function fn_options(options)
    checks({
        mystring = '?string',
        mynumber = '?number',
    })
end

local _l_array = 2 + debug.getinfo(1).currentline
function fn_array(array)
    checks({'number', 'number'})
end

local _l_table = 2 + debug.getinfo(1).currentline
function fn_table(table)
    checks({mykey = 'number'})
end

local _l_inception = 2 + debug.getinfo(1).currentline
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
    local _ = options.we.need.to.go.deeper
end

------------------------------------------------------------------------------

local function test_err(test, code, expected_file, expected_line, expected_error)
    local fn = loadstring(code)
    local ok, err = pcall(fn)

    if expected_error == nil then
        local testname = code .. ' - nil'
        test:is(err, nil, testname)
    else
        local testname = string.format('%s - %s', code, expected_error:gsub('%%', ''))
        local expected_err = string.format('%s:%d: %s',
            expected_file, expected_line, expected_error)
        test:like(err, expected_err, testname)
    end
    -- body
end

test:plan(122)
test_err(test, 'fn_number_optstring(1)')
test_err(test, 'fn_number_optstring(1, nil)')
test_err(test, 'fn_number_optstring(2, "s")')
test_err(test, 'fn_number_optstring(3, "s", "excess")')
test_err(test, 'fn_number_optstring(4, 0)',
    'tests.lua', _l_number_optstring,
    'bad argument #2 to fn_number_optstring %(%?string expected, got number%)')
test_err(test, 'fn_number_optstring(5, {})',
    'tests.lua', _l_number_optstring,
    'bad argument #2 to fn_number_optstring %(%?string expected, got table%)')
test_err(test, 'fn_number_optstring(6, msgpack.NULL)')
test_err(test, 'fn_number_optstring("7")',
    'tests.lua', _l_number_optstring,
    'bad argument #1 to fn_number_optstring %(number expected, got string%)')

test_err(test, 'fn_positive_number(8)')
test_err(test, 'fn_positive_number(setmetatable({}, {__type = "positive_number"}))')
test_err(test, 'fn_positive_number(0)',
    'tests.lua', _l_positive_number,
    'bad argument #1 to fn_positive_number %(positive_number expected, got number%)')

test_err(test, 'fn_number_or_string(100)')
test_err(test, 'fn_number_or_string("s")')
test_err(test, 'fn_number_or_string(nil)',
    'tests.lua', _l_number_or_string,
    'bad argument #1 to fn_number_or_string %(number|string expected, got nil%)')
test_err(test, 'fn_number_or_string(msgpack.NULL)',
    'tests.lua', _l_number_or_string,
    'bad argument #1 to fn_number_or_string %(number|string expected, got cdata%)')
test_err(test, 'fn_number_or_string(true)',
    'tests.lua', _l_number_or_string,
    'bad argument #1 to fn_number_or_string %(number|string expected, got boolean%)')

test_err(test, 'fn_anytype()')
test_err(test, 'fn_anytype(nil)')
test_err(test, 'fn_anytype(100)')
test_err(test, 'fn_anytype("s")')
test_err(test, 'fn_anytype({0})')
test_err(test, 'fn_anytype(true)')
test_err(test, 'fn_anytype(msgpack.NULL)')

test_err(test, 'fn_nil_or_number_or_string()')
test_err(test, 'fn_nil_or_number_or_string(nil)')
test_err(test, 'fn_nil_or_number_or_string(100)')
test_err(test, 'fn_nil_or_number_or_string("s")')
test_err(test, 'fn_nil_or_number_or_string({0})',
    'tests.lua', _l_nil_or_number_or_string,
    'bad argument #1 to fn_nil_or_number_or_string %(nil|number|string expected, got table%)')
test_err(test, 'fn_nil_or_number_or_string(msgpack.NULL)',
    'tests.lua', _l_nil_or_number_or_string,
    'bad argument #1 to fn_nil_or_number_or_string %(nil|number|string expected, got cdata%)')

test_err(test, 'fn_varargs(100)',
    'tests.lua', _l_varargs,
    'bad argument #1 to fn_varargs %(string expected, got number%)')
test_err(test, 'fn_varargs("s")')
test_err(test, 'fn_varargs("s", 1)')
test_err(test, 'fn_varargs("s", "e", 2)')

test_err(test, 'fn_options(1)',
    'tests.lua', _l_options,
    'bad argument #1 to fn_options %(%?table expected, got number%)')
test_err(test, 'fn_options(false)',
    'tests.lua', _l_options,
    'bad argument #1 to fn_options %(%?table expected, got boolean%)')
test_err(test, 'fn_options({mystring = "s"})')
test_err(test, 'fn_options({mynumber = 1})')
test_err(test, 'fn_options({mynumber = "bad"})',
    'tests.lua', _l_options,
    'bad argument options.mynumber to fn_options %(%?number expected, got string%)')
test_err(test, 'fn_options({badfield = "bad"})',
    'tests.lua', _l_options,
    'unexpected argument options.badfield to fn_options')

test_err(test, 'fn_array(1)',
    'tests.lua', _l_array,
    'bad argument #1 to fn_array %(%?table expected, got number%)')
test_err(test, 'fn_array()',
    'tests.lua', _l_array,
    'bad argument array%[1%] to fn_array %(number expected, got nil%)')
test_err(test, 'fn_array({})',
    'tests.lua', _l_array,
    'bad argument array%[1%] to fn_array %(number expected, got nil%)')
test_err(test, 'fn_array({"str1"})',
    'tests.lua', _l_array,
    'bad argument array%[1%] to fn_array %(number expected, got string%)')
test_err(test, 'fn_array({1})',
    'tests.lua', _l_array,
    'bad argument array%[2%] to fn_array %(number expected, got nil%)')
test_err(test, 'fn_array({1, 2})')
test_err(test, 'fn_array({1, 2, 3})',
    'tests.lua', _l_array,
    'unexpected argument array%[3%] to fn_array')

test_err(test, 'fn_table(1)',
    'tests.lua', _l_table,
    'bad argument #1 to fn_table %(%?table expected, got number%)')
test_err(test, 'fn_table()',
    'tests.lua', _l_table,
    'bad argument table.mykey to fn_table %(number expected, got nil%)')
test_err(test, 'fn_table({})',
    'tests.lua', _l_table,
    'bad argument table.mykey to fn_table %(number expected, got nil%)')
test_err(test, 'fn_table({mykey = "str"})',
    'tests.lua', _l_table,
    'bad argument table.mykey to fn_table %(number expected, got string%)')
test_err(test, 'fn_table({mykey = 0})')
test_err(test, 'fn_table({mykey = 0, excess = 1})',
    'tests.lua', _l_table,
    'unexpected argument table.excess to fn_table')

test_err(test, 'fn_inception()', nil)
test_err(test, 'fn_inception({})', nil)
test_err(test, 'fn_inception({we = false})',
    'tests.lua', _l_inception,
    'bad argument options.we to fn_inception %(%?table expected, got boolean%)')
test_err(test, 'fn_inception({we = {}})', nil)
test_err(test, 'fn_inception({we = {need = {}}})', nil)
test_err(test, 'fn_inception({we = {need = {to = {}}}})', nil)
test_err(test, 'fn_inception({we = {need = {to = {go = {}}}}})', nil)
test_err(test, 'fn_inception({we = {need = {to = {go = {deeper = 0}}}}})', nil)
test_err(test, 'fn_inception({we = {need = {to = {go = {deeper = {}}}}}})',
    'tests.lua', _l_inception,
    'bad argument options.we.need.to.go.deeper to fn_inception %(%?number expected, got table%)')


local function deepchecks()
    checks(2, 'string')
end
local _l_deepcheck = 2 + debug.getinfo(1).currentline
function fn_deepcheck(arg1)
    deepchecks()
end

test_err(test, 'fn_deepcheck("s")')
test_err(test, 'fn_deepcheck(1)',
    'tests.lua', _l_deepcheck,
    'bad argument #1 to fn_deepcheck %(string expected, got number%)')

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

local _l_excess_checks = 2 + debug.getinfo(1).currentline
function fn_excess_checks(arg1)
    checks('?number', '?string')
end
test_err(test, 'fn_excess_checks()',
    'tests.lua', _l_excess_checks,
    'checks: excess check, absent argument')

local _l_missing_checks = 2 + debug.getinfo(1).currentline
function fn_missing_checks(arg1, arg2)
    checks('?number')
end
test_err(test, 'fn_missing_checks()',
    'tests.lua', _l_missing_checks,
    'checks: argument "arg2" is not checked')

local _l_bad_check_type_1 = 2 + debug.getinfo(1).currentline
function bad_check_type_1(arg1, arg2)
    checks("?string", 5)
end
test_err(test, 'bad_check_type_1()',
    'tests.lua', _l_bad_check_type_1,
    'checks: type "number" is not supported')

local _l_bad_check_type_2 = 2 + debug.getinfo(1).currentline
function bad_check_type_2(arg1, arg2)
    checks({param = 5})
end
test_err(test, 'bad_check_type_2()',
    'tests.lua', _l_bad_check_type_2,
    'checks: type "number" is not supported')

------------------------------------------------------------------------------

function fn_int64(arg)
    checks('int64')
end

function fn_uint64(arg)
    checks('uint64')
end

local function test_ret(test, code, should_succeed)
    local fn = loadstring(code)
    test:is(pcall(fn), should_succeed, code .. ' - ' .. (should_succeed and 'valid' or 'invalid'))
end

test_ret(test, 'fn_int64(0)', true)
test_ret(test, 'fn_int64( 1)', true)
test_ret(test, 'fn_int64(-1)', true)
test_ret(test, 'fn_int64( 0.5)', false)

test_ret(test, 'fn_int64(-2^53)', false)
test_ret(test, 'fn_int64(-2^53+1)', true)
test_ret(test, 'fn_int64( 2^53-1)', true)
test_ret(test, 'fn_int64( 2^53)', false)
test_ret(test, 'fn_int64( 0/0)', false) -- NaN
test_ret(test, 'fn_int64( 1/0)', false) -- +Inf
test_ret(test, 'fn_int64(-1/0)', false) -- -Inf

test_ret(test, 'fn_int64(-1e16)', false)
test_ret(test, 'fn_int64(-1e15)', true)
test_ret(test, 'fn_int64( 1e15)', true)
test_ret(test, 'fn_int64( 1e16)', false)

test_ret(test, 'fn_int64(-9223372036854775808LL)', true) -- LLONG_MIN
test_ret(test, 'fn_int64( 9223372036854775807LL)', true) -- LLONG_MAX
test_ret(test, 'fn_int64( 9223372036854775808ULL)', false) -- 2^63
test_ret(test, 'fn_int64(18446744073709551615ULL)', false) -- ULLONG_MAX
test_ret(test, 'fn_int64(tonumber64( "9223372036854775807"))', true)
test_ret(test, 'fn_int64(tonumber64( "9223372036854775808"))', false)
test_ret(test, 'fn_int64(tonumber64("-9223372036854775808"))', true)

test_ret(test, 'fn_uint64( 0)', true)
test_ret(test, 'fn_uint64( 1)', true)
test_ret(test, 'fn_uint64(-1)', false)
test_ret(test, 'fn_uint64( 0.5)', false)
test_ret(test, 'fn_uint64( 2^53-1)', true)
test_ret(test, 'fn_uint64( 2^53)', false)
test_ret(test, 'fn_uint64( 2^53+1)', false)
test_ret(test, 'fn_uint64( 1e15)', true)
test_ret(test, 'fn_uint64( 1e-1)', false)
test_ret(test, 'fn_uint64( 1e16)', false)
test_ret(test, 'fn_uint64( 0/0)', false) -- NaN
test_ret(test, 'fn_uint64( 1/0)', false) -- +Inf
test_ret(test, 'fn_uint64(-1/0)', false) -- -Inf

test_ret(test, 'fn_uint64(-9223372036854775808LL)', false) -- LLONG_MIN
test_ret(test, 'fn_uint64( 9223372036854775807LL)', true) -- LLONG_MAX
test_ret(test, 'fn_uint64( 9223372036854775808ULL)', true) -- 2^63
test_ret(test, 'fn_uint64(18446744073709551615ULL)', true) -- ULLONG_MAX
test_ret(test, 'fn_uint64(tonumber64( "9223372036854775807"))', true)
test_ret(test, 'fn_uint64(tonumber64( "9223372036854775808"))', true)
test_ret(test, 'fn_uint64(tonumber64("-9223372036854775808"))', false)

------------------------------------------------------------------------------

uuid = require('uuid')
myid = uuid()

function fn_uuid(arg)
    checks('uuid')
end

function fn_uuid_str(arg)
    checks('uuid_str')
end

function fn_uuid_bin(arg)
    checks('uuid_bin')
end

test_ret(test, 'fn_uuid(myid)', true)
test_ret(test, 'fn_uuid(myid:str())', false)
test_ret(test, 'fn_uuid(myid:bin())', false)

test_ret(test, 'fn_uuid_str(myid)', false)
test_ret(test, 'fn_uuid_str(myid:str())', true)
test_ret(test, 'fn_uuid_str(myid:bin())', false)

test_ret(test, 'fn_uuid_bin(myid)', false)
test_ret(test, 'fn_uuid_bin(myid:str())', false)
test_ret(test, 'fn_uuid_bin(myid:bin())', true)

-- various cdata
test_ret(test, 'fn_int64(myid)', false)
test_ret(test, 'fn_uint64(myid)', false)
test_ret(test, 'fn_uuid(1ULL)', false)

os.exit(test:check())
