local ffi = require('ffi')

ffi.cdef[[
    int memcmp(const char *mem1, const char *mem2, size_t num);
]]

local err_string_arg = "bad argument #%d to '%s' (%s expected, got %s)"

local c_char_ptr     = ffi.typeof('const char *')

local memcmp  = ffi.C.memcmp

local _qualifiers_cache = {
    -- ['?type1|type2'] = {
    --     [1] = 'type1',
    --     [2] = 'type2',
    --     optional = true,
    -- },
}

--- Check that string (or substring) starts with given string
-- Optionally restricting the matching with the given offsets
-- @function startswith
-- @string    inp     original string
-- @string    head    the substring to check against
-- @int[opt]  _start  start index of matching boundary
-- @int[opt]  _end    end index of matching boundary
-- @returns           boolean
local function startswith(inp, head, _start, _end)
    if type(inp) ~= 'string' then
        error(err_string_arg:format(1, 'string.startswith', 'string',
                                    type(inp)), 2)
    end
    if type(head) ~= 'string' then
        error(err_string_arg:format(2, 'string.startswith', 'string',
                                    type(head)), 2)
    end
    if _start ~= nil and type(_start) ~= 'number' then
        error(err_string_arg:format(3, 'string.startswith', 'integer',
                                    type(_start)), 2)
    end
    if _end ~= nil and type(_end) ~= 'number' then
        error(err_string_arg:format(4, 'string.startswith', 'integer',
                                    type(_end)), 2)
    end
    -- prepare input arguments (move negative values [offset from the end] to
    -- positive ones and/or assign default values)
    local head_len, inp_len = #head, #inp
    if _start == nil then
        _start = 1
    elseif _start < 0 then
        _start = inp_len + _start + 1
        if _start < 0 then _start = 0 end
    end
    if _end == nil or _end > inp_len then
        _end = inp_len
    elseif _end < 0 then
        _end = inp_len + _end + 1
        if _end < 0 then _end = 0 end
    end
    -- check for degenerate case (interval lesser than input)
    if head_len == 0 then
        return true
    elseif _end - _start + 1 < head_len or _start > _end then
        return false
    end
    _start = _start - 1
    return memcmp(c_char_ptr(inp) + _start, c_char_ptr(head), head_len) == 0
end


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
            if startswith(typ, '?') then
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

        local checker = rawget(_G, 'checkers')[typ]
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

            if rawget(_G, '_checks_v2_compatible') and value == nil then
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

            if rawget(_G, '_checks_v2_compatible') and value == nil then
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

rawset(_G, 'checks', checks)

local checkers = rawget(_G, 'checkers') or {}
rawset(_G, 'checkers', checkers)

local _checks_v2_compatible = rawget(_G, '_checks_v2_compatible') or false
rawset(_G, '_checks_v2_compatible', _checks_v2_compatible)

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

local has_box = rawget(_G, 'box') ~= nil
if has_box and box.tuple ~= nil then
    checkers.tuple = box.tuple.is
end

local has_decimal, decimal = pcall(require, 'decimal')
if has_decimal then
    -- There is a decimal.is_decimal check since 2.4, but we
    -- reimplement it here to support older versions which have decimal.
    local cdata_t = ffi.typeof(decimal.new(0))
    checkers.decimal = function(arg)
        return ffi.istype(cdata_t, arg)
    end
end

local function add_ffi_type_checker(checks_type, c_type)
    local has_cdata_t, cdata_t = pcall(ffi.typeof, c_type)
    if has_cdata_t then
        checkers[checks_type] = function(arg)
            return ffi.istype(cdata_t, arg)
        end
    end
end

-- There is a uuid.is_uuid check since 2.6.1, but we
-- reimplement it here to support older versions which have uuid.
-- https://github.com/tarantool/tarantool/blob/7682d34162be34648172d91008e9185301bce8f6/src/lua/uuid.lua#L29
add_ffi_type_checker('uuid', 'struct tt_uuid')

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

add_ffi_type_checker('error', 'struct error')

local has_datetime, datetime = pcall(require, 'datetime')
if has_datetime then
    checkers.datetime = datetime.is_datetime
end

add_ffi_type_checker('interval', 'struct interval')

return setmetatable(
    {
        checks = checks,
        _VERSION = require('checks.version'),
    },
    {
        -- Made export table callable for backward compatibility.
        __call = function(_, ...)
            return checks(...)
        end
    }
)
