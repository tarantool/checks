#!/usr/bin/env tarantool

require('strict').on()
local tap = require('tap')
local json = require('json')
local uuid = require('uuid')
local checks = require('checks')
local test = tap.test('performance_test')

local total_time = 0
local total_iter = 0

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

local function perftest(check, argtype)
    local fn = function(arg)
        checks(check)
    end

    local arg = args[argtype]

    local cnt = 0
    local batch_size = 1000
    local stop
    local start = os.clock()
    repeat
        for i = 1, batch_size do
            fn(arg)
        end
        cnt = cnt + batch_size
        batch_size = math.floor(batch_size * 1.2)
        stop = os.clock()
    until stop - start > 1

    local testname = string.format('checks(%s) (%s)', json.encode(check), argtype)
    test:diag(string.format("  %-35s: %.2f calls/s", testname, cnt/(stop-start) ))
end

perftest('?', 'nil')
perftest('?', 'string')

perftest('string', 'string')

perftest('?string', 'nil')
perftest('?string', 'string')

perftest('number|string', 'string')
perftest('number|string', 'number')

perftest('meta', 'meta')
perftest('?string|meta', 'nil')
perftest('?string|meta', 'string')
perftest('?string|meta', 'meta')

perftest('int64',  'number')
perftest('int64',  'int64')
perftest('int64',  'uint64')
perftest('uint64', 'number')
perftest('uint64', 'int64')
perftest('uint64', 'uint64')

perftest('uuid', 'uuid')
perftest('uuid_str', 'uuid_str')
perftest('uuid_bin', 'uuid_bin')

perftest({x='?'}, 'table')
perftest({x={y='?'}}, 'table')
perftest({x={y={z='?'}}}, 'table')
perftest({x={y={z={t='?'}}}}, 'table')
-- TODO checks({timeout = '?number'}) -- table checker
