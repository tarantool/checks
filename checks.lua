#!/usr/bin/env tarantool

local function argname_fmt(argname, key)
    if type(key) == 'string' then
        return string.format('%s.%s', argname, key)
    elseif type(key) == 'number' then
        return string.format('%s[%s]', argname, key)
    else
        return argname .. '[?]'
    end
end

local function check_type(value, expected_type)
    if type(value) == expected_type then
        return true
    end

    local mt = getmetatable(value)
    local value_metatype = mt and mt.__type
    if value_metatype == expected_type then
        return true
    end

    local checker = _G.checkers[expected_type]
    if type(checker) == 'function' and checker(value) == true then
        return true
    end
end

local function check_value(level, argname, value, expected_type)
    level = level + 1 -- escape the check_value level
    local _expected_type = expected_type

    -- 1. Check optional type.
    if expected_type == '?' then
        return true
    elseif expected_type:startswith('?') then
        if value == nil then
            return true
        end
        expected_type = expected_type:sub(2)
    end

    -- 2. Check exact type match
    if check_type(value, expected_type) then
        return true
    end

    -- 3. Check multiple types.
    for typ in expected_type:gmatch('[^|]+') do
        if check_type(value, typ) then
            return true
        end
    end

    -- 4. Nothing works, throw error
    local info = debug.getinfo(level, 'nl')
    error(string.format(
        'bad argument %s to %s (%s expected, got %s)',
        argname, info.name, _expected_type, type(value)
    ), level)
end

local function check_table(level, argname, tbl, expected_fields)
    level = level + 1 -- escape the check_table level

    for expected_key, expected_type in pairs(expected_fields) do
        if type(expected_type) == 'string' then
            local argname = argname_fmt(argname, expected_key)
            check_value(level, argname, tbl[expected_key], expected_type)
        elseif type(expected_type) == 'table' then
            local argname = argname_fmt(argname, expected_key)
            check_value(level, argname, tbl[expected_key], '?table')
            tbl[expected_key] = tbl[expected_key] or {}
        else
            error(string.format(
                'checks: type %q is not supported',
                type(expected_type)
            ), level)
        end
    end

    for key, value in pairs(tbl) do
        local argname = argname_fmt(argname, key)
        local expected_type = expected_fields[key]
        if not expected_type then
            local info = debug.getinfo(level, 'nl')
            error(string.format(
                'unexpected argument %s to %s',
                argname, info.name
            ), level)
        elseif type(expected_type) == 'string' then
            check_value(level, argname, value, expected_type)
        elseif type(expected_type) == 'table' then
            check_table(level, argname, value, expected_type)
        end
    end
end

local function checks(...)
    local skip = 0

    local level = 1
    if type(...) == 'number' then
        level = ...
        skip = 1
    end
    level = level + 1 -- escape the checks level

    for i = 1, select('#', ...) - skip + 1 do
        local expected_type = select(i + skip, ...)
        local argname, value = debug.getlocal(level, i)

        if expected_type == nil and argname == nil then
            break
        elseif expected_type == nil then
            error(string.format(
                'checks: argument %q is not checked',
                argname
            ), level)
        elseif argname == nil then
            error(string.format(
                'checks: excess check, absent argument'
            ), level)
        elseif type(expected_type) == 'string' then
            check_value(level, string.format('#%d', i), value, expected_type)

        elseif type(expected_type) == 'table' then
            check_value(level, string.format('#%d', i), value, '?table')
            local value = value or {}
            check_table(level, argname, value, expected_type)
            debug.setlocal(level, i, value)
        else
            error(string.format(
                'checks: type %q is not supported',
                type(expected_type)
            ), level)
        end
    end
end

_G.checks = checks
_G.checkers = rawget(_G, 'checkers') or {}

local ffi = require('ffi')
function checkers.uint64(arg)
    if type(arg) == 'number' then
        -- Double floating point format has 52 fraction bits
        -- If we want to keep integer precision,
        -- the number must be less than 2^53
        return (arg >= 0) and (arg < 2^53) and (math.floor(arg) == arg)
    end

    if type(arg) == 'cdata' then
        if ffi.istype('int64_t', arg) then
            return (arg >= 0)
        elseif ffi.istype('uint64_t', arg) then
            return true
        end
    end

    return false
end

function checkers.int64(arg)
    if type(arg) == 'number' then
        return (arg > -2^53) and (arg < 2^53) and (math.floor(arg) == arg)
    end

    if type(arg) == 'cdata' then
        if ffi.istype('int64_t', arg) then
            return true
        elseif ffi.istype('uint64_t', arg) then
            return arg < 2^63
        end
    end

    return false
end

local uuid = require('uuid')
function checkers.uuid(arg)
    if type(arg) == 'cdata' then
        return ffi.istype('struct tt_uuid', arg)
    else
        return false
    end
end

function checkers.uuid_str(arg)
    if type(arg) == 'string' then
        return uuid.fromstr(arg) ~= nil
    else
        return false
    end
end

function checkers.uuid_bin(arg)
    if type(arg) == 'string' then
        return uuid.frombin(arg) ~= nil
    else
        return false
    end
end

return checks
