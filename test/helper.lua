-- Clean up built-in checks to run tests with repository module.
local rock_utils = require('test.rock_utils')
rock_utils.remove_builtin('checks')
rock_utils.assert_nonbuiltin('checks')
