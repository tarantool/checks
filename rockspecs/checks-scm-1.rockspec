package = "checks"
version = "scm-1"
source = {
    url    = 'git://github.com/tarantool/checks.git',
    branch = "master",
}

description = {
    summary = "Easy, terse, readable and fast function arguments type checking",
    detailed = [[
        This library declares a `checks()` function and a
        `checkers` table, which allow to check the parameters
        passed to a Lua function in a fast and unobtrusive way.
    ]],
    homepage = "https://github.com/tarantool/checks",
    license = "BSD",
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = 'builtin',
    modules = {
        ['checks'] = 'checks.lua',
    }
}

