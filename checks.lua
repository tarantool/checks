local function check_value(level, argname, value, expected_type)
    -- 1. Check for nil if type is optional.
    if expected_type:match('^?') and value == nil then
        return true
    end

    local valid_types = {}
    for typ in expected_type:gmatch('[^|?]+') do
        valid_types[typ] = true
    end

    -- 2. Check real type.
    if valid_types[type(value)] == true then
        return true
    end

    -- 3. Check for type name in metatable.
    local mt = getmetatable(value)
    if mt and valid_types[mt.__type] == true then
        return true
    end

    for typ, _ in pairs(valid_types) do
        local checker = _G.checkers[typ]
        if type(checker) == 'function' and checker(value) == true then
            return true
        end
    end

    -- 4. Nothing works, throw error
    local info = debug.getinfo(level + 1, 'nl')
    return error(string.format(
        'bad argument %s to %s (%s expected, got %s)',
        argname, info.name, expected_type, type(value)
    ), level+2)
end

local function check_table(level, argname, tbl, expected_fields)
    for expected_key, expected_type in pairs(expected_fields) do
        if type(expected_type) == 'string' then
            -- do nothing
        elseif type(expected_type) == 'table' then
            tbl[expected_key] = tbl[expected_key] or {}
        else
            error(string.format(
                'checks: argument type %s is not supported',
                type(expected_type))
            )
        end
    end

    for key, value in pairs(tbl) do
        local argname = string.format('%s.%s', argname, key)
        local expected_type = expected_fields[key]
        if not expected_type then
            local info = debug.getinfo(level + 1, 'nl')
            error(string.format(
                'unexpected argument %s to %s',
                argname, info.name
            ), level+2)
        elseif type(expected_type) == 'string' then
            check_value(level + 1, argname, value, expected_type)
        elseif type(expected_type) == 'table' then
            check_value(level + 1, argname, value, '?table')
            if value then
                check_table(level + 1, argname, value, expected_type)
            end
        end
    end
end

local function checks(...)
    local arg = {...}

    local level = 1
    if type(arg[1]) == 'number' then
        level = arg[1]
        arg:remove(1)
    end
    level = level + 1 -- escape the checks level

    for i = 1, table.maxn(arg) do
        local expected_type = arg[i]
        local argname, value = debug.getlocal(level, i)

        if expected_type == nil then
            -- do not check
        elseif type(expected_type) == 'string' then
            check_value(level, string.format('#%d', i), value, expected_type)

        elseif type(expected_type) == 'table' then
            check_value(level, string.format('#%d', i), value, '?table')
            local value = value or {}
            check_table(level, argname, value, expected_type)
            debug.setlocal(level, i, value)
        else
            error(string.format(
                'checks: argument type %s is not supported',
                type(expected_type))
            )
        end
    end
end

_G.checks = checks
_G.checkers = rawget(_G, 'checkers') or {}
return checks
