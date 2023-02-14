-- Clean up built-in checks to run tests with repository module.
package.loaded['checks'] = nil
local checks = require('checks')

local package_source = debug.getinfo(checks).source
assert(package_source:match('^@builtin') == nil, 'Run tests for repository checks package')