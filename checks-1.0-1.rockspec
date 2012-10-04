--*-lua-*-
package = "checks"
version = "1.0-1"
source = {
    url = "http://..."
}

description = {
    summary = "Easy, terse, readable and fast function arguments type checking",
    detailed = [[
            This library declares a `checks()` function and a `checkers` table, which
            allow to check the parameters passed to a Lua function in a fast and
            unobtrusive way.
   ]],
   homepage = "http://...",
   license = "Eclipse public license"
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = 'builtin',
    modules = {
        checks = 'checks.c'
    }
}
