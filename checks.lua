---The `checks` module provides the ability to check the types of arguments
---passed to a Lua function. It is designed to reveal mistakes in code, not to
---validate user input.
---
---The returned module table is callable: `checks(type_1, ...)` is equivalent
---to `checks.checks(type_1, ...)`. It exposes the `checks` function and the
---`_VERSION` string field.
---
---@alias checks.qualifier string|table<any, checks.qualifier>
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

---Check that the given string (or substring) starts with the given string,
---optionally restricting the matching with the given offsets.
---
---@param inp string The original string.
---@param head string The substring to check against.
---@param _start? integer Start index of the matching boundary (default: `1`).
---@param _end? integer End index of the matching boundary (default: `#inp`).
---@return boolean `true` if `inp` starts with `head`, `false` otherwise.
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


---Check that a value conforms to the given string type qualifier.
---
---@param value any The value to check.
---@param expected_type string The string type qualifier, e.g. `'string'`,
---    `'?number|string'`, or `'?'` for any type.
---@return boolean? `true` if the value conforms to the type qualifier.
---@return string? error_message The formatted error message if the check fails.
local function check_string_type(value, expected_type)
    -- 1. Check any value.
    if expected_type == '?' then
        return true
    end

    -- 2. Parse type qualifier
    ---@type { [integer]: string, optional: boolean }?
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

---Format a table key for an error message: `.key` for strings and `[n]`
---for numbers.
---
---@param key any The table key.
---@return string The formatted key name.
local function keyname_fmt(key)
    if type(key) == 'string' then
        return string.format('.%s', key)
    elseif type(key) == 'number' then
        return string.format('[%s]', key)
    else
        return '[?]'
    end
end

---Check that a table conforms to the given table type qualifier.
---
---@param tbl table? The table to check.
---@param expected_fields table<any, checks.qualifier> The table type qualifier.
---@return boolean? `true` if the table conforms to the type qualifier.
---@return string? error_message The formatted error message if the check fails.
local function check_table_type(tbl, expected_fields)
    if tbl == nil then
        tbl = nil
    end

    for expected_key, expected_type in pairs(expected_fields) do
        local value = tbl and tbl[expected_key]

        if type(expected_type) == 'string' then
            local ok, efmt = check_string_type(value, expected_type)
            if not ok then
                ---@cast efmt string
                return nil, string.format(efmt, '%s'..keyname_fmt(expected_key), '%s')
            end
        elseif type(expected_type) == 'table' then
            local ok, efmt = check_string_type(value, '?table')
            if not ok then
                ---@cast efmt string
                return nil, string.format(efmt, '%s'..keyname_fmt(expected_key), '%s')
            end

            if rawget(_G, '_checks_v2_compatible') and value == nil then
                value = {}
                tbl[expected_key] = value
            end

            local ok, efmt = check_table_type(value, expected_type)
            if not ok then
                ---@cast efmt string
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

---Checks that the arguments of the calling function conform to the specified
---types. Must be called at the top of the function being checked; each type
---qualifier corresponds to the argument at the same position.
---
---String qualifiers check Lua types, Tarantool-specific types (`uint64`,
---`int64`, `decimal`, `uuid`, etc.), metatable `__type` values, and custom
---checker names; they can be combined into union types (`'number|string'`) and
---made optional (`'?string'`). Table qualifiers validate the values of a table
---argument.
---
---@param ... checks.qualifier|number Type qualifiers, one per argument to
---    check. The first argument may also be a stack level (used internally).
local function checks(...)
    local skip = 0

    ---@type integer
    local level = 1
    local first = ...
    if type(first) == 'number' then
        ---@cast first integer
        level = first
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
                ---@cast efmt string
                local err = string.format(efmt, '#'..tostring(i), info.name)
                error(err, level)
            end

        elseif type(expected_type) == 'table' then
            local ok, efmt = check_string_type(value, '?table')
            if not ok then
                local info = debug.getinfo(level, 'nl')
                ---@cast efmt string
                local err = string.format(efmt, '#'..tostring(i), info.name)
                error(err, level)
            end

            if rawget(_G, '_checks_v2_compatible') and value == nil then
                value = {}
                -- In emmylua-check 0.22.0 the debug.setlocal index
                -- parameter is mistyped as `string`; it is an integer.
                ---@diagnostic disable-next-line: param-type-mismatch
                debug.setlocal(level, i, value)
            end

            local ok, efmt = check_table_type(value, expected_type)
            if not ok then
                local info = debug.getinfo(level, 'nl')
                ---@cast efmt string
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

---The `checks` function is also available as a global, so it can be used
---without loading the module (Tarantool 2.11.0 and later).
rawset(_G, 'checks', checks)

---The `checkers` global table provides access to checkers for different types.
---It can be extended with custom checkers that perform arbitrary validations.
---
---@class checks.checkers
---@field datetime fun(arg: any): boolean Check that the value is a datetime object.
---@field decimal fun(arg: any): boolean Check that the value has the decimal type.
---@field error fun(arg: any): boolean Check that the value is an error object.
---@field int64 fun(arg: any): boolean Check that the value is an int64 value.
---@field interval fun(arg: any): boolean Check that the value is an interval object.
---@field tuple fun(arg: any): boolean Check that the value is a tuple.
---@field uint64 fun(arg: any): boolean Check that the value is a uint64 value.
---@field uuid fun(arg: any): boolean Check that the value is a uuid object.
---@field uuid_bin fun(arg: any): boolean Check that the value is a uuid as a 16-byte binary string.
---@field uuid_str fun(arg: any): boolean Check that the value is a uuid as a 36-byte hexadecimal string.
local checkers = rawget(_G, 'checkers') or {}
rawset(_G, 'checkers', checkers)

---When set to `true`, substitutes `nil` table arguments with empty tables for
---backward compatibility with v2.1.
---@type boolean
local _checks_v2_compatible = rawget(_G, '_checks_v2_compatible') or false
rawset(_G, '_checks_v2_compatible', _checks_v2_compatible)

---Check whether the specified value is a `uint64` value: an integer Lua number
---in the range from 0 to 2^53-1 (inclusive), a cdata `ctype<uint64_t>`, or a
---cdata `ctype<int64_t>` in the range from 0 to `LLONG_MAX`.
---
---@param arg any The value to check.
---@return boolean `true` if the value is a `uint64` value, `false` otherwise.
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

---Check whether the specified value is an `int64` value: an integer Lua
---number in the range from -2^53+1 to 2^53-1 (inclusive), a cdata
---`ctype<int64_t>`, or a cdata `ctype<uint64_t>` in the range from 0 to
---`LLONG_MAX`.
---
---@param arg any The value to check.
---@return boolean `true` if the value is an `int64` value, `false` otherwise.
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

---Check whether the specified value is a tuple.
local has_box = rawget(_G, 'box') ~= nil
if has_box and box.tuple ~= nil then
    checkers.tuple = box.tuple.is
end

local has_decimal, decimal = pcall(require, 'decimal')
if has_decimal then
    -- There is a decimal.is_decimal check since 2.4, but we
    -- reimplement it here to support older versions which have decimal.
    local cdata_t = ffi.typeof(decimal.new(0))
    ---Check whether the specified value has the decimal type.
    ---
    ---@param arg any The value to check.
    ---@return boolean `true` if the value has the decimal type, `false` otherwise.
    checkers.decimal = function(arg)
        return ffi.istype(cdata_t, arg)
    end
end

---Register a checker for a cdata type checked via FFI.
---
---@param checks_type string The name of the checker to register in `checkers`.
---@param c_type string The C type name, e.g. `'struct tt_uuid'`.
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

---Check whether the specified value is a uuid represented by a 36-byte
---hexadecimal string.
---
---@param arg any The value to check.
---@return boolean `true` if the value is a uuid string, `false` otherwise.
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

---Check whether the specified value is a uuid represented by a 16-byte binary
---string.
---
---@param arg any The value to check.
---@return boolean `true` if the value is a uuid binary string, `false` otherwise.
function checkers.uuid_bin(arg)
    if type(arg) == 'string' and #arg == 16 then
        return true
    else
        return false
    end
end

add_ffi_type_checker('error', 'struct error')

---Check whether the specified value is a datetime object.
local has_datetime, datetime = pcall(require, 'datetime')
if has_datetime then
    checkers.datetime = datetime.is_datetime
end

add_ffi_type_checker('interval', 'struct interval')

local M = setmetatable(
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

return M
