#!/usr/bin/env tarantool

local _qualifiers_cache = {
    -- ['?type1|type2'] = {
    --     [1] = 'type1',
    --     [2] = 'type2',
    --     optional = true,
    -- },
}

local function check_string_type(value, expected_type)
    -- 1. Check any value.
    if expected_type == '?' then
        return true
    end

    -- 2. Parse type qualifier
    local qualifier = _qualifiers_cache[expected_type]
    if qualifier == nil then
        qualifier = { optional = false }

        for typ in expected_type:gmatch('[^|]+') do
            if typ:startswith('?') then
                qualifier.optional = true
                typ = typ:sub(2)
            end

            table.insert(qualifier, typ)
        end

        _qualifiers_cache[expected_type] = qualifier
    end

    -- 3. Check optional argument
    if qualifier.optional and value == nil then
        return true
    end

    -- 4. Check types
    for _, typ in ipairs(qualifier) do
        if type(value) == typ then
            return true
        end

        local mt = getmetatable(value)
        local value_metatype = mt and mt.__type
        if value_metatype == typ then
            return true
        end

        local checker = _G.checkers[typ]
        if type(checker) == 'function' and checker(value) == true then
            return true
        end
    end

    -- 5. Nothing works, return an error
    return nil, string.format(
        'bad argument %s to %s (%s expected, got %s)',
        -- argname and function name are formatted by the caller
        '%s', '%s', expected_type, type(value)
    )
end

local function keyname_fmt(key)
    if type(key) == 'string' then
        return string.format('.%s', key)
    elseif type(key) == 'number' then
        return string.format('[%s]', key)
    else
        return '[?]'
    end
end

local function check_table_type(tbl, expected_fields)
    if tbl == nil then
        tbl = nil
    end

    for expected_key, expected_type in pairs(expected_fields) do
        local value = tbl and tbl[expected_key]

        if type(expected_type) == 'string' then
            local ok, efmt = check_string_type(value, expected_type)
            if not ok then
                return nil, string.format(efmt, '%s'..keyname_fmt(expected_key), '%s')
            end
        elseif type(expected_type) == 'table' then
            local ok, efmt = check_string_type(value, '?table')
            if not ok then
                return nil, string.format(efmt, '%s'..keyname_fmt(expected_key), '%s')
            end

            if _G._checks_v2_compatible and value == nil then
                value = {}
                tbl[expected_key] = value
            end

            local ok, efmt = check_table_type(value, expected_type)
            if not ok then
                return nil, string.format(efmt, '%s'..keyname_fmt(expected_key), '%s')
            end
        else
            return nil, string.format(
                'checks: type %q is not supported',
                type(expected_type)
            )
        end
    end

    if not tbl then
        return true
    end

    for key, _ in pairs(tbl) do
        if not expected_fields[key] then
            return nil, string.format(
                'unexpected argument %s to %s',
                -- argname and function name
                -- are formatted by the caller
                '%s'..keyname_fmt(key), '%s'
            )
        end
    end

    return true
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
            local err = string.format(
                'checks: argument %q is not checked',
                argname
            )
            error(err, level)
        elseif argname == nil then
            local err = 'checks: excess check, absent argument'
            error(err, level)
        elseif type(expected_type) == 'string' then
            local ok, efmt = check_string_type(value, expected_type)
            if not ok then
                local info = debug.getinfo(level, 'nl')
                local err = string.format(efmt, '#'..tostring(i), info.name)
                error(err, level)
            end

        elseif type(expected_type) == 'table' then
            local ok, efmt = check_string_type(value, '?table')
            if not ok then
                local info = debug.getinfo(level, 'nl')
                local err = string.format(efmt, '#'..tostring(i), info.name)
                error(err, level)
            end

            if _G._checks_v2_compatible and value == nil then
                value = {}
                debug.setlocal(level, i, value)
            end

            local ok, efmt = check_table_type(value, expected_type)
            if not ok then
                local info = debug.getinfo(level, 'nl')
                local err = string.format(efmt, argname, info.name)
                error(err, level)
            end
        else
            local err = string.format(
                'checks: type %q is not supported',
                type(expected_type)
            )
            error(err, level)
        end
    end
end

_G.checks = checks
_G.checkers = rawget(_G, 'checkers') or {}
_G._checks_v2_compatible = rawget(_G, '_checks_v2_compatible') or false

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
local uuid_t = ffi.typeof('struct tt_uuid')
function checkers.uuid(arg)
    if type(arg) == 'cdata' then
        return ffi.istype(uuid_t, arg)
    else
        return false
    end
end

function checkers.uuid_str(arg)
    if type(arg) == 'string' and #arg == 36 then
        local match = arg:match(
            '^'..
            '%x%x%x%x%x%x%x%x%-'..
            '%x%x%x%x%-'..
            '%x%x%x%x%-'..
            '[0-9a-dA-D]%x%x%x%-'..
            '%x%x%x%x%x%x%x%x%x%x%x%x'..
            '$'
        )
        return match ~= nil
    else
        return false
    end
end

function checkers.uuid_bin(arg)
    if type(arg) == 'string' and #arg == 16 then
        return true
    else
        return false
    end
end

return checks
