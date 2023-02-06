#!/usr/bin/env tarantool

local t = require('luatest')

local checks = require('checks')
local json = require('json')
local log = require('log')
local uuid = require('uuid')

local g = t.group('checks_performance')

local args = {
    ['nil'] = nil,
    ['string'] = 'str',
    ['number'] = 0,
    ['int64'] = 0LL,
    ['uint64'] = 0ULL,
    ['table'] = {},
    ['meta'] = setmetatable({}, {__type = "meta"}),
    ['uuid'] = uuid(),
    ['uuid_str'] = uuid.str(),
    ['uuid_bin'] = uuid.bin(),
}

local cases = {
    {
        check = '?',
        argtype = 'nil',
    },
    {
        check = '?',
        argtype = 'nil',
    },

    {
        check = 'string',
        argtype = 'string',
    },

    {
        check = '?string',
        argtype = 'nil',
    },
    {
        check = '?string',
        argtype = 'string',
    },

    {
        check = 'number|string',
        argtype = 'string',
    },
    {
        check = 'number|string',
        argtype = 'number',
    },

    {
        check = 'meta',
        argtype = 'meta',
    },
    {
        check = '?string|meta',
        argtype = 'nil',
    },
    {
        check = '?string|meta',
        argtype = 'string',
    },
    {
        check = '?string|meta',
        argtype = 'meta',
    },

    {
        check = 'int64',
        argtype = 'number',
    },
    {
        check = 'int64',
        argtype = 'int64',
    },
    {
        check = 'int64',
        argtype = 'uint64',
    },
    {
        check = 'uint64',
        argtype = 'number',
    },
    {
        check = 'uint64',
        argtype = 'int64',
    },
    {
        check = 'uint64',
        argtype = 'uint64',
    },

    {
        check = 'uuid',
        argtype = 'uuid',
    },
    {
        check = 'uuid_str',
        argtype = 'uuid_str',
    },
    {
        check = 'uuid_bin',
        argtype = 'uuid_bin',
    },

    {
        check = {x='?'},
        argtype = 'table',
    },
    {
        check = {x={y='?'}},
        argtype = 'table',
    },
    {
        check = {x={y={z='?'}}},
        argtype = 'table',
    },
    {
        check = {x={y={z={t='?'}}}},
        argtype = 'table',
    },
    -- TODO checks({timeout = '?number'}) -- table checker
}

for _, case in pairs(cases) do
    -- dots in test case name are not expected
    local name = ('test_%s_%s'):format(json.encode(case.check), case.argtype):gsub('%.', '_')

    g[name] = function(_)
        local fn = function(arg) -- luacheck: no unused args
            checks(case.check)
        end

        local arg = args[case.argtype]

        local cnt = 0
        local batch_size = 1000
        local stop
        local start = os.clock()
        repeat
            for _ = 1, batch_size do
                fn(arg)
            end
            cnt = cnt + batch_size
            batch_size = math.floor(batch_size * 1.2)
            stop = os.clock()
        until stop - start > 1

        local testline = string.format('checks(%s) (%s)', json.encode(case.check), case.argtype)
        log.info("  %-35s: %.2f calls/s", testline, cnt / (stop - start))
    end
end
