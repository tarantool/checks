#!/usr/bin/env tarantool

local t = require('luatest')

local json = require('json')
local checks = require('checks')

local g = t.group('checks')

------------------------------------------------------------------------------
local current_file = debug.getinfo(1, 'S').short_src

------------------------------------------------------------------------------
local checkers = rawget(_G, 'checkers')
function checkers.positive_number(n)
    return type(n) == 'number' and n > 0
end

local testdata = {}

local _l_number_optstring = 2 + debug.getinfo(1).currentline
function testdata.fn_number_optstring(arg1, arg2) -- luacheck: no unused args
    checks('number', '?string')
end

local _l_number_or_string = 2 + debug.getinfo(1).currentline
function testdata.fn_number_or_string(arg1) -- luacheck: no unused args
    checks('number|string')
end

local _l_positive_number = 2 + debug.getinfo(1).currentline
function testdata.fn_positive_number(arg1) -- luacheck: no unused args
    checks('positive_number')
end

function testdata.fn_anytype(arg1) -- luacheck: no unused args
    checks('?')
end

local _l_nil_or_number_or_string = 2 + debug.getinfo(1).currentline
function testdata.fn_nil_or_number_or_string(arg1) -- luacheck: no unused args
    checks('nil|number|string')
end

local _l_optnumber_or_optstring = 2 + debug.getinfo(1).currentline
function testdata.fn_optnumber_or_optstring(arg1) -- luacheck: no unused args
    checks('?number|?string')
end

local _l_varargs = 2 + debug.getinfo(1).currentline
function testdata.fn_varargs(arg1, ...) -- luacheck: no unused args
    checks('string')
end

local _l_options = 2 + debug.getinfo(1).currentline
function testdata.fn_options(options) -- luacheck: no unused args
    checks({
        mystring = '?string',
        mynumber = '?number',
    })
end

local _l_array = 2 + debug.getinfo(1).currentline
function testdata.fn_array(array) -- luacheck: no unused args
    checks({'number', 'number'})
end

local _l_table = 2 + debug.getinfo(1).currentline
function testdata.fn_table(table) -- luacheck: no unused args
    checks({mykey = 'number'})
end

local _l_inception = 2 + debug.getinfo(1).currentline
function testdata.fn_inception(options) -- luacheck: no unused args
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

local function deepchecks()
    checks(2, 'string')
end

local _l_deepcheck = 2 + debug.getinfo(1).currentline
function testdata.fn_deepcheck(arg1) -- luacheck: no unused args
    deepchecks()
end

local _l_excess_checks = 2 + debug.getinfo(1).currentline
function testdata.fn_excess_checks(arg1) -- luacheck: no unused args
    checks('?number', '?string')
end

local _l_missing_checks = 2 + debug.getinfo(1).currentline
function testdata.fn_missing_checks(arg1, arg2) -- luacheck: no unused args
    checks('?number')
end

local _l_bad_check_type_1 = 2 + debug.getinfo(1).currentline
function testdata.bad_check_type_1(arg1, arg2) -- luacheck: no unused args
    checks("?string", 5)
end

local _l_bad_check_type_2 = 2 + debug.getinfo(1).currentline
function testdata.bad_check_type_2(arg1, arg2) -- luacheck: no unused args
    checks({param = 5})
end

local err_cases = {
    -- fn_number_optstring
    {
        code = 'fn_number_optstring(1)',
    },
    {
        code = 'fn_number_optstring(1, nil)',
    },
    {
        code = 'fn_number_optstring(2, "s")',
    },
    {
        code = 'fn_number_optstring(3, "s", "excess")',
    },
    {
        code = 'fn_number_optstring(4, 0)',
        line = _l_number_optstring,
        error = 'bad argument #2 to fn_number_optstring (?string expected, got number)',
    },
    {
        code = 'fn_number_optstring(5, {})',
        line = _l_number_optstring,
        error = 'bad argument #2 to fn_number_optstring (?string expected, got table)',
    },
    {
        code = 'fn_number_optstring(6, box.NULL)',
    },
    {
        code = 'fn_number_optstring("7")',
        line = _l_number_optstring,
        error = 'bad argument #1 to fn_number_optstring (number expected, got string)',
    },

    -- fn_positive_number
    {
        code = 'fn_positive_number(8)',
    },
    {
        code = 'fn_positive_number(setmetatable({}, {__type = "positive_number"}))',
    },
    {
        code = 'fn_positive_number(0)',
        line = _l_positive_number,
        error = 'bad argument #1 to fn_positive_number (positive_number expected, got number)',
    },

    -- fn_number_or_string
    {
        code = 'fn_number_or_string(100)',
    },
    {
        code = 'fn_number_or_string("s")',
    },
    {
        code = 'fn_number_or_string(nil)',
        line = _l_number_or_string,
        error = 'bad argument #1 to fn_number_or_string (number|string expected, got nil)',
    },
    {
        code = 'fn_number_or_string(box.NULL)',
        line = _l_number_or_string,
        error = 'bad argument #1 to fn_number_or_string (number|string expected, got cdata)',
    },
    {
        code = 'fn_number_or_string(true)',
        line = _l_number_or_string,
        error = 'bad argument #1 to fn_number_or_string (number|string expected, got boolean)',
    },

    -- fn_anytype
    {
        code = 'fn_anytype()',
    },
    {
        code = 'fn_anytype(nil)',
    },
    {
        code = 'fn_anytype(100)',
    },
    {
        code = 'fn_anytype("s")',
    },
    {
        code = 'fn_anytype({0})',
    },
    {
        code = 'fn_anytype(true)',
    },
    {
        code = 'fn_anytype(box.NULL)',
    },

    -- fn_nil_or_number_or_string
    {
        code = 'fn_nil_or_number_or_string()',
    },
    {
        code = 'fn_nil_or_number_or_string(nil)',
    },
    {
        code = 'fn_nil_or_number_or_string(100)',
    },
    {
        code = 'fn_nil_or_number_or_string("s")',
    },
    {
        code = 'fn_nil_or_number_or_string({0})',
        line = _l_nil_or_number_or_string,
        error = 'bad argument #1 to fn_nil_or_number_or_string (nil|number|string expected, got table)',
    },
    {
        code = 'fn_nil_or_number_or_string(box.NULL)',
        line = _l_nil_or_number_or_string,
        error = 'bad argument #1 to fn_nil_or_number_or_string (nil|number|string expected, got cdata)',
    },

    -- fn_optnumber_or_optstring
    {
        code = 'fn_optnumber_or_optstring()',
    },
    {
        code = 'fn_optnumber_or_optstring(nil)',
    },
    {
        code = 'fn_optnumber_or_optstring(100)',
    },
    {
        code = 'fn_optnumber_or_optstring("s")',
    },
    {
        code = 'fn_optnumber_or_optstring({0})',
        line = _l_optnumber_or_optstring,
        error = 'bad argument #1 to fn_optnumber_or_optstring (?number|?string expected, got table)',
    },

    -- fn_varargs
    {
        code = 'fn_varargs(100)',
        line = _l_varargs,
        error = 'bad argument #1 to fn_varargs (string expected, got number)',
    },
    {
        code = 'fn_varargs("s")',
    },
    {
        code = 'fn_varargs("s", 1)',
    },
    {
        code = 'fn_varargs("s", "e", 2)',
    },

    -- fn_options
    {
        code = 'fn_options(1)',
        line = _l_options,
        error = 'bad argument #1 to fn_options (?table expected, got number)',
    },
    {
        code = 'fn_options(false)',
        line = _l_options,
        error = 'bad argument #1 to fn_options (?table expected, got boolean)',
    },
    {
        code = 'fn_options()',
    },
    {
        code = 'fn_options(nil)',
    },
    {
        code = 'fn_options(box.NULL)',
    },
    {
        code = 'fn_options({mystring = "s"})',
    },
    {
        code = 'fn_options({mynumber = 1})',
    },
    {
        code = 'fn_options({mynumber = "bad"})',
        line = _l_options,
        error = 'bad argument options.mynumber to fn_options (?number expected, got string)',
    },
    {
        code = 'fn_options({badfield = "bad"})',
        line = _l_options,
        error = 'unexpected argument options.badfield to fn_options',
    },

    -- fn_array
    {
        code = 'fn_array(1)',
        line = _l_array,
        error = 'bad argument #1 to fn_array (?table expected, got number)',
    },
    {
        code = 'fn_array()',
        line = _l_array,
        error = 'bad argument array[1] to fn_array (number expected, got nil)',
    },
    {
        code = 'fn_array(nil)',
        line = _l_array,
        error = 'bad argument array[1] to fn_array (number expected, got nil)',
    },
    {
        code = 'fn_array(box.NULL)',
        line = _l_array,
        error = 'bad argument array[1] to fn_array (number expected, got nil)',
    },
    {
        code = 'fn_array({})',
        line = _l_array,
        error = 'bad argument array[1] to fn_array (number expected, got nil)',
    },
    {
        code = 'fn_array({"str1"})',
        line = _l_array,
        error = 'bad argument array[1] to fn_array (number expected, got string)',
    },
    {
        code = 'fn_array({1})',
        line = _l_array,
        error = 'bad argument array[2] to fn_array (number expected, got nil)',
    },
    {
        code = 'fn_array({1, 2})',
    },
    {
        code = 'fn_array({1, 2, 3})',
        line = _l_array,
        error = 'unexpected argument array[3] to fn_array',
    },

    -- fn_table
    {
        code = 'fn_table(1)',
        line = _l_table,
        error = 'bad argument #1 to fn_table (?table expected, got number)',
    },
    {
        code = 'fn_table()',
        line = _l_table,
        error = 'bad argument table.mykey to fn_table (number expected, got nil)',
    },
    {
        code = 'fn_table({})',
        line = _l_table,
        error = 'bad argument table.mykey to fn_table (number expected, got nil)',
    },
    {
        code = 'fn_table({mykey = "str"})',
        line = _l_table,
        error = 'bad argument table.mykey to fn_table (number expected, got string)',
    },
    {
        code = 'fn_table({mykey = 0})',
    },
    {
        code = 'fn_table({mykey = 0, excess = 1})',
        line = _l_table,
        error = 'unexpected argument table.excess to fn_table',
    },

    -- fn_inception
    {
        code = 'fn_inception()',
    },
    {
        code = 'fn_inception({})',
    },
    {
        code = 'fn_inception({we = false})',
        line = _l_inception,
        error = 'bad argument options.we to fn_inception (?table expected, got boolean)',
    },
    {
        code = 'fn_inception({we = {}})',
    },
    {
        code = 'fn_inception({we = {need = {}}})',
    },
    {
        code = 'fn_inception({we = {need = {to = {}}}})',
    },
    {
        code = 'fn_inception({we = {need = {to = {go = {}}}}})',
    },
    {
        code = 'fn_inception({we = {need = {to = {go = {deeper = 0}}}}})',
    },
    {
        code = 'fn_inception({we = {need = {to = {go = {deeper = {}}}}}})',
        line = _l_inception,
        error = 'bad argument options.we.need.to.go.deeper to fn_inception (?number expected, got table)',
    },

    -- fn_deepcheck
    {
        code = 'fn_deepcheck("s")',
    },
    {
        code = 'fn_deepcheck(1)',
        line = _l_deepcheck,
        error = 'bad argument #1 to fn_deepcheck (string expected, got number)',
    },

    -- fn_excess_checks
    {
        code = 'fn_excess_checks()',
        line = _l_excess_checks,
        error = 'checks: excess check, absent argument',
    },
    {
        code = 'fn_missing_checks()',
        line = _l_missing_checks,
        error = 'checks: argument "arg2" is not checked',
    },
    {
        code = 'bad_check_type_1()',
        line = _l_bad_check_type_1,
        error = 'checks: type "number" is not supported',
    },
    {
        code = 'bad_check_type_2()',
        line = _l_bad_check_type_2,
        error = 'checks: type "number" is not supported',
    },
}

for _, case in pairs(err_cases) do
    -- dots in test case name are not expected
    local name = ('test_err_%s'):format(case.code):gsub('%.', '_')

    local _, _, fn_name = case.code:find('(.-)%(')
    assert(#fn_name > 0)

    g.before_test(name, function(_)
        rawset(_G, fn_name, testdata[fn_name])
    end)

    g[name] = function(_)
        local fn = loadstring(case.code)
        local ok, err = pcall(fn)

        if case.error == nil then
            t.assert_equals(ok, true)
            t.assert_equals(err, nil)
        else
            t.assert_equals(ok, false)
            local expected_err = ('%s:%d: %s'):format(current_file, case.line, case.error)
            t.assert_str_contains(err, expected_err)
        end
    end

    g.after_test(name, function(_)
        rawset(_G, fn_name, nil)
    end)
end

------------------------------------------------------------------------------
local options_cases = {
    {
        args = nil,
    },
    {
        args = {},
    },
    {
        args = {a = {}},
    },
    {
        args = {a = {b1 = {}}},
    },
    {
        args = {a = {b2 = {}}},
    },
    {
        args = {a = {b1 = {c = 0}}},
    },
    {
        args = {a = {b2 = {c = 0}}},
    },
    {
        args = {a = {b1 = {c = 0}, b2 = {c = 2}}},
    },
}

local optcopy = nil
local function check_options(options)
    optcopy = table.deepcopy(options)
    checks({
        a = {
            b1 = {
                c = '?',
            },
            b2 = {
                c = '?',
            },
        },
    })
    t.assert_equals(options, optcopy, 'checks does not modify options')
end

for _, case in pairs(options_cases) do
    -- dots in test case name are not expected
    local name = ('test_options_%s'):format(json.encode(case.args)):gsub('%.', '_')

    g[name] = function(_)
        check_options(case.args)
    end
end

------------------------------------------------------------------------------
local options_v2_cases = {
    {
        args = nil,
    },
    {
        args = {},
    },
    {
        args = box.NULL,
    },
    {
        args = {a = {}},
    },
}

local function check_v2_compatibility(options)
    checks({
        a = {
            b1 = {
                c = '?',
            },
            b2 = {
                c = '?',
            },
        },
    })

    t.assert_equals(
        options,
        {
            a = {
                b1 = { c = nil },
                b2 = { c = nil }
            }
        }, 'checks modifies options')
end

for _, case in pairs(options_v2_cases) do
    -- dots in test case name are not expected
    local name = ('test_options_v2_compatibility_%s'):format(json.encode(case.args)):gsub('%.', '_')

    g.before_test(name, function(_)
        rawset(_G, '_checks_v2_compatible', true)
    end)

    g[name] = function(_)
        check_v2_compatibility(case.args)
    end

    g.after_test(name, function(_)
        rawset(_G, '_checks_v2_compatible', false)
    end)
end

------------------------------------------------------------------------------
function testdata.fn_int64(arg) -- luacheck: no unused args
    checks('int64')
end

function testdata.fn_uint64(arg) -- luacheck: no unused args
    checks('uint64')
end

local uuid = require('uuid')
testdata.myid = uuid()

function testdata.fn_uuid(arg) -- luacheck: no unused args
    checks('uuid')
end

function testdata.fn_uuid_str(arg) -- luacheck: no unused args
    checks('uuid_str')
end

function testdata.fn_uuid_bin(arg) -- luacheck: no unused args
    checks('uuid_bin')
end

function testdata.fn_tuple(arg) -- luacheck: no unused args
    checks('tuple')
end

function testdata.fn_decimal(arg) -- luacheck: no unused args
    checks('decimal')
end

local has_decimal, decimal = pcall(require, 'decimal')
if has_decimal then
    testdata.decimal = decimal
end

function testdata.fn_error(arg) -- luacheck: no unused args
    checks('error')
end

local has_error = (box.error ~= nil) and (box.error.new ~= nil)

function testdata.fn_datetime(arg) -- luacheck: no unused args
    checks('datetime')
end

local has_datetime, datetime = pcall(require, 'datetime')
if has_datetime then
    testdata.datetime = datetime
end

function testdata.fn_interval(arg) -- luacheck: no unused args
    checks('interval')
end

local has_interval = has_datetime and datetime.interval ~= nil

local ret_cases = {
    -- fn_int64
    {
        code = 'fn_int64(0)',
        ok = true,
    },
    {
        code = 'fn_int64( 1)',
        ok = true,
    },
    {
        code = 'fn_int64(-1)',
        ok = true,
    },
    {
        code = 'fn_int64( 0.5)',
        ok = false,
    },

    {
        code = 'fn_int64(-2^53)',
        ok = false,
    },
    {
        code = 'fn_int64(-2^53+1)',
        ok = true,
    },
    {
        code = 'fn_int64( 2^53-1)',
        ok = true,
    },
    {
        code = 'fn_int64( 2^53)',
        ok = false,
    },
    {
        code = 'fn_int64( 0/0)', -- NaN
        ok = false,
    },
    {
        code = 'fn_int64( 1/0)', -- +Inf
        ok = false,
    },
    {
        code = 'fn_int64(-1/0)', -- -Inf
        ok = false,
    },

    {
        code = 'fn_int64(-1e16)',
        ok = false,
    },
    {
        code = 'fn_int64(-1e15)',
        ok = true,
    },
    {
        code = 'fn_int64( 1e15)',
        ok = true,
    },
    {
        code = 'fn_int64( 1e16)',
        ok = false,
    },

    {
        code = 'fn_int64(-9223372036854775808LL)', -- LLONG_MIN
        ok = true,
    },
    {
        code = 'fn_int64( 9223372036854775807LL)', -- LLONG_MAX
        ok = true,
    },
    {
        code = 'fn_int64( 9223372036854775808ULL)', -- 2^63
        ok = false,
    },
    {
        code = 'fn_int64(18446744073709551615ULL)', -- ULLONG_MAX
        ok = false,
    },
    {
        code = 'fn_int64(tonumber64( "9223372036854775807"))',
        ok = true,
    },
    {
        code = 'fn_int64(tonumber64( "9223372036854775808"))',
        ok = false,
    },
    {
        code = 'fn_int64(tonumber64("-9223372036854775808"))',
        ok = true,
    },

    -- fn_uint64
    {
        code = 'fn_uint64( 0)',
        ok = true,
    },
    {
        code = 'fn_uint64( 1)',
        ok = true,
    },
    {
        code = 'fn_uint64(-1)',
        ok = false,
    },
    {
        code = 'fn_uint64( 0.5)',
        ok = false,
    },
    {
        code = 'fn_uint64( 2^53-1)',
        ok = true,
    },
    {
        code = 'fn_uint64( 2^53)',
        ok = false,
    },
    {
        code = 'fn_uint64( 2^53+1)',
        ok = false,
    },
    {
        code = 'fn_uint64( 1e15)',
        ok = true,
    },
    {
        code = 'fn_uint64( 1e-1)',
        ok = false,
    },
    {
        code = 'fn_uint64( 1e16)',
        ok = false,
    },
    {
        code = 'fn_uint64( 0/0)', -- NaN
        ok = false,
    },
    {
        code = 'fn_uint64( 1/0)', -- +Inf
        ok = false,
    },
    {
        code = 'fn_uint64(-1/0)', -- -Inf
        ok = false,
    },

    {
        code = 'fn_uint64(-9223372036854775808LL)', -- LLONG_MIN
        ok = false,
    },
    {
        code = 'fn_uint64( 9223372036854775807LL)', -- LLONG_MAX
        ok = true,
    },
    {
        code = 'fn_uint64( 9223372036854775808ULL)', -- 2^63
        ok = true,
    },
    {
        code = 'fn_uint64(18446744073709551615ULL)', -- ULLONG_MAX
        ok = true,
    },
    {
        code = 'fn_uint64(tonumber64( "9223372036854775807"))',
        ok = true,
    },
    {
        code = 'fn_uint64(tonumber64( "9223372036854775808"))',
        ok = true,
    },
    {
        code = 'fn_uint64(tonumber64("-9223372036854775808"))',
        ok = false,
    },

    -- fn_uuid
    {
        code = 'fn_uuid(myid)',
        ok = true,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uuid(myid:str())',
        ok = false,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uuid(myid:bin())',
        ok = false,
        additional_data = {'myid'},
    },

    -- fn_uuid_str
    {
        code = 'fn_uuid_str(myid)',
        ok = false,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uuid_str(myid:str())',
        ok = true,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uuid_str(myid:str():upper())',
        ok = true,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uuid_str("00000000-0000-0000-e000-000000000000")', -- illegal variant
        ok = false,
    },
    {
        code = 'fn_uuid_str("00000000-0000-0000-f000-000000000000")', -- illegal variant
        ok = false,
    },
    {
        code = 'fn_uuid_str("00000000-0000-0000-Z000-000000000000")', -- illegal letter
        ok = false,
    },
    {
        code = 'fn_uuid_str("00000000-0000-0000#0000-000000000000")', -- illegal format
        ok = false,
    },
    {
        code = 'fn_uuid_str("00000000-0000-0000#0000-000000000000")', -- illegal len
        ok = false,
    },
    {
        code = 'fn_uuid_str("00000000-0000-0000-0000-0000000000000")', -- illegal len
        ok = false,
    },
    {
        code = 'fn_uuid_str(myid:bin())',
        ok = false,
        additional_data = {'myid'},
    },

    -- fn_uuid_bin
    {
        code = 'fn_uuid_bin(myid)',
        ok = false,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uuid_bin(myid:str())',
        ok = false,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uuid_bin(myid:bin())',
        ok = true,
        additional_data = {'myid'},
    },

    -- various cdata
    {
        code = 'fn_int64(myid)',
        ok = false,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uint64(myid)',
        ok = false,
        additional_data = {'myid'},
    },
    {
        code = 'fn_uuid(1ULL)',
        ok = false,
    },

    -- fn_tuple
    {
        code = 'fn_tuple(box.tuple.new({1, 2, 3}))',
        ok = true,
    },
    {
        code = 'fn_tuple({1, 2, 3})',
        ok = false,
    },
    {
        code = 'fn_tuple(1ULL)',
        ok = false,
    },
    {
        code = 'fn_tuple(1)',
        ok = false,
    },

    -- fn_decimal
    {
        skip = not has_decimal,
        code = 'fn_decimal(decimal.new(123))',
        ok = true,
        additional_data = {'decimal'},
    },
    {
        skip = not has_decimal,
        code = 'fn_decimal(decimal.new("123"))',
        ok = true,
        additional_data = {'decimal'},
    },
    {
        skip = not has_decimal,
        code = 'fn_decimal(123)',
        ok = false,
    },
    {
        skip = not has_decimal,
        code = 'fn_decimal(1ULL)',
        ok = false,
    },
    {
        skip = not has_decimal,
        code = 'fn_decimal(1)',
        ok = false,
    },

    -- fn_error
    {
        skip = not has_error,
        code = 'fn_error(box.error.new(box.error.UNKNOWN))',
        ok = true,
    },
    {
        skip = not has_error,
        code = 'fn_error(box.error.UNKNOWN)', -- It's an error code, not an error object.
        ok = false,
    },
    {
        skip = not has_error,
        code = 'fn_error(select(2, pcall(error, "my error")))',
        ok = false,
    },
    {
        skip = not has_error,
        code = 'fn_error()',
        ok = false,
    },
    {
        skip = not has_error,
        code = 'fn_error(1)',
        ok = false,
    },

    -- fn_datetime
    {
        skip = not has_datetime,
        code = 'fn_datetime(datetime.new())',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime(datetime.new{year=2023, month=1, day=11})',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime(datetime.new{nsec=1001001})',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime(datetime.new{timestamp=1673439642})',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime(datetime.new{tzoffset=180})',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime(datetime.new{tz="Europe/Moscow"})',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime()',
        ok = false,
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime("1.11.2023")',
        ok = false,
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime(1673439642)',
        ok = false,
    },
    {
        skip = not has_datetime,
        code = 'fn_datetime({year=2023, month=1, day=11})',
        ok = false,
    },

    -- fn_interval
    {
        skip = not has_interval,
        code = 'fn_interval(datetime.interval.new())',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_interval,
        code = 'fn_interval(datetime.interval.new{day=1})',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_interval,
        code = 'fn_interval(datetime.interval.new{month=1, adjust="last"})',
        ok = true,
        additional_data = {'datetime'},
    },
    {
        skip = not has_interval,
        code = 'fn_interval()',
        ok = false,
    },
    {
        skip = not has_interval,
        code = 'fn_interval({month=1, adjust="last"})',
        ok = false,
    },
}

for _, case in pairs(ret_cases) do
    -- dots in test case name are not expected
    local name = ('test_ret_%s'):format(case.code):gsub('%.', '_')

    local _, _, fn_name = case.code:find('(.-)%(')
    assert(#fn_name > 0)

    g.before_test(name, function(_)
        rawset(_G, fn_name, testdata[fn_name])
        if case.additional_data ~= nil then
            for _, v in pairs(case.additional_data) do
                rawset(_G, v, testdata[v])
            end
        end
    end)

    g[name] = function(_)
        t.skip_if(case.skip, "type unsupported")

        local fn = loadstring(case.code)
        local ok, err = pcall(fn)
        t.assert_equals(case.ok, ok, err)
    end

    g.after_test(name, function(_)
        rawset(_G, fn_name, nil)
        if case.additional_data ~= nil then
            for _, v in pairs(case.additional_data) do
                rawset(_G, v, nil)
            end
        end
    end)
end

g.test_version = function()
    t.assert_type(require('checks')._VERSION, 'string')
end
