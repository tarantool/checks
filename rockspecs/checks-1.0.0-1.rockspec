--*-lua-*-
package = "checks"
version = "1.0.0-1"
source = {
    url = 'git://github.com/tarantool/checks.git',
    tag = "1.0.0",
}

description = {
    summary = "Easy, terse, readable and fast function arguments type checking",
    detailed = [[
            This library declares a `checks()` function and a
            `checkers` table, which allow to check the parameters
            passed to a Lua function in a fast and unobtrusive way.
   ]],
   homepage = "https://github.com/tarantool/checks",
   license = "BSD"
}

dependencies = {
    "lua >= 5.1"
}

build = {
    type = 'cmake';
    variables = {
        CMAKE_BUILD_TYPE="RelWithDebInfo";
        CMAKE_INSTALL_PREFIX = "$(PREFIX)",
        TARANTOOL_INSTALL_LIBDIR = "lib",
        TARANTOOL_INSTALL_LUADIR = "lua",
    };
}
