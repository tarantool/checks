# Argument type checking API

This library declares a `checks()` function and a `checkers` table, which
allow to check the parameters passed to a Lua function in a fast and
unobtrusive  way.

`checks (type_1, ..., type_n)`, when called directly inside function
`f`, checks that `f`'s 1st argument conforms to `type_1`, that its 2nd
argument conforms to `type_2`, etc. until `type_n`. Type specifiers
are strings, and if the arguments passed to `f` don't conform to their
specification, a proper error message is produced, pinpointing the
call to `f` as the faulty expression.

Each type description `type_n` must be a string, and can describe:

* the Lua type of an object, such as `"table"`, `"number"` etc.;

* an arbitrary name, which would be stored in the `__type` field of
  the argument's metatable;

* a type-checking function, which would be stored in the `checkers`
  global table. This table uses type names as keys, test functions
  returning Booleans as keys.

Moreover, types can be prefixed with a `"?"`, which makes them
optional. For instance, `"?table"` accepts tables as well as `nil`
values.

A `"?"` alone accepts anything. It is mainly useful as a placeholder,
to skip an argument which doesn't need to be checked.

Finally, several types can be accepted, if their names are
concatenated with a bar `"|"` between them. For instance,
`"table|number"` accepts tables as well as numbers. It can be combined
with the question mark, so `"?table|number"` accepts tables, numbers
and nil values. It is actually equivalent to `"nil|table|number"`.

More formally, let's specify `conform(a, t)`, the property that
argument `a` conforms to the type denoted by `t`. `conform(a,t)` is
true if and only if at least one of the following propositions is
verified:

* `conforms(a, t:match "^(.-)|.*"`

* `t == "?"`

* `t:sub(1, 1) == "?" and (conforms(a, t:sub(2, -1)) or a==nil)`

* `type(a) == t`

* `getmetatable(a) and getmetatable(a).__type == t`

* `checkers[t] and checkers[t](a) is true`

* `conforms(a, t:match "^.-|(.*)")`

The above propositions are listed in the order in which they are tried
by `check`. The higher they appear in the list, the faster `checks`
accepts aconforming argument. For instance, `checks("number")` is
faster than:

```lua
checkers.mynumber=function(x) return type(x)=="number" end; checks("mynumber")
```

## Usage examples

```lua
require 'checks'

-- Custom checker function --
function checkers.port(p)
  return type(p)=='number' and p>0 and p<0x10000
end

-- A new named type --
socket_mt = { __type='socket' }
asocket = setmetatable ({ }, socket_mt)

-- A function that checks its parameters --
function take_socket_then_port_then_maybe_string (sock, port, str)
  checks ('socket', 'port', '?string')
end

take_socket_then_port_then_maybe_string (asocket, 1024, "hello")
take_socket_then_port_then_maybe_string (asocket, 1024)
-- A couple of other parameter-checking options --

function take_number_or_string()
  checks("number|string")
end

function take_number_or_string_or_nil()
  checks("?number|string")
end
function take_anything_followed_by_a_number()
  checks("?", "number")
end
-- Catch some incorrect arguments passed to the function --

function must_fail(...)
  assert (not pcall (take_socket_then_port_then_maybe_string, ...))
end

must_fail ({ }, 1024, "string")      -- 1st argument isn't a socket
must_fail (asocket, -1, "string")   -- port number must be 0-0xffff
must_fail (asocket, 1024, { })    -- 3rd argument cannot be a table
```

## Credits

This library was originally a part of
[[https://github.com/SierraWireless/luasched]]. Now a dependency for
luacheck.
