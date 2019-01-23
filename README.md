<a href="https://travis-ci.org/tarantool/checks">
    <img src="https://travis-ci.org/tarantool/checks.png?branch=master"
    align="right">
</a>

# Argument type checking API

This library declares a `checks()` function and a `checkers` table, which
allow to check the parameters passed to a Lua function in a fast and
unobtrusive  way.

---

**COGNIZE THE ESSENCE**

It is NOT designed to validate user input.
It is designed to provide better type checking of function arguments.

It is NOT designed to hide your problems.
It is designed to reveal mistakes in code.

You should think of `checks` as of `assert` on steroids.

---

## Description

Function `checks(type_1, ..., type_n)`,
when called directly inside function `fn`,
checks that `fn`'s 1st argument conforms to `type_1`,
2nd argument conforms to `type_2`, etc.

Type specifiers are strings or tables, and if the arguments passed
to `fn` don't conform to their specification, a proper error message is produced,
pinpointing the call to `fn` as the faulty expression.

## String type qualifiers

### Lua type

The type is simply `type(arg)`, such as `'table'`, `'number'` etc.

```lua
function fn_string(x)
    checks('string')
end
fn_string('foo') -- ok
fn_string(99) -- error:  bad argument #1 to fn_string (string expected, got number)'
```

### Metatable type

An arbitrary name, which is stored in the `__type` field of the argument metatable

```lua
function fn_color(x)
    checks('color')
end
local blue = setmetatable({0, 0, 255}, {__type = 'color'})
fn_color(blue) -- ok
fn_color({}) -- error: bad argument #1 to fn_color (color expected, got table)'
```

### A type-checking function name

The function would be stored in the `checkers` global table.
This function is called with original value passed to `fn`
and must return `true` if the value is valid.

```lua
function fn_positive(x)
    checks('positive')
end
function checkers.positive(p)
  return (type(p) == 'number') and (p > 0)
end
fn_positive(42) -- ok
fn_positive(-1) -- error: bad argument #1 to fn_positive (positive expected, got number)'
```

One can use built-in checkers:

* `checks('uint64')`:

  * Either integer lua number in range from `0` to `2^53-1` (inclusive)
  * or lua cdata `ctype<uint64_t>`
  * or lua cdata `ctype<int64_t>` in range from `0` to `LLONG_MAX`

  After the check it is safe to call `ffi.cast('uint64_t', ...)`

* `checks('int64')`:

  * Either integer lua number in range from `-2^53+1` to `2^53-1` (inclusive)
  * or lua cdata `ctype<uint64_t>` in range from `0` to `LLONG_MAX`
  * or lua cdata `ctype<int64_t>`

  After the check it is safe to call `ffi.cast('int64_t', ...)`

* `checks('uuid')`:

  * lua cdata `ctype<struct tt_uuid>`
    containing `uuid_object` from tarantool built-in
    [module *uuid*](https://tarantool.io/en/doc/reference/reference_lua/uuid.html)

* `checks('uuid_str')`:

  * uuid as a 36-byte hexadecimal string

  After the check it is safe to call `uuid.fromstr()`

* `checks('uuid_bin')`:

  * uuid as a 16-byte binary string

  After the check it is safe to call `uuid.frombin()`


### Optional type and types combination

Moreover, several types can be accepted
if their names are concatenated with a bar `|` between them.
For instance, `'table|number'` accepts tables as well as numbers.

Finally, string type qualifier can be prefixed
with a question mark `?`, which makes them optional.
For instance, `'?table'` accepts tables as well as `nil` values,
`'?table|number'` accepts tables, numbers and nil values.

Question mark is not an equivalent to combination with the `'nil'` type:
`box.NULL` is a valid value for `'?number'`, but not for `'nil|number'` combination.

A `'?'` type alone accepts anything. It is mainly useful as a placeholder
to skip an argument which doesn't need to be checked.

To sum up, the string type qualifier has the following syntax:
either `'[?]type1[|type2[...]]'` or single `'?'`.

## Table type qualifiers

The type qualifier may be a table.
In this case the argument is checked to conform to `'?table'` type, and its content is validated.
Table values are validated against type qualifiers as described above.
Table keys, which are not mentioned in `checks`, are validated against `'nil'` type.
Table type qualifiers may be recursive and use tables too.

```lua
function fn_opts(options)
    checks({
        my_string = '?string',
        my_number = '?number',
    })
end

fn_opts({my_string = 's'}) -- ok
fn_opts({my_number = 101}) -- ok
fn_opts({my_number = 'x'}) -- error: bad argument options.my_number to fn_opts (?number expected, got string)'
fn_opts({bad_field = true}) -- error: unexpected argument options.bad_field to fn_opts
```

Since v3.0 `checks` does not modify any arguments. Be careful when indexing options table:

```lua
function fn_bad(options)
    checks({timeout = '?number'})
    print(options.timeout)
end

fn_bad() -- error: attempt to index local 'options' (a nil value)


function fn_good(options)
    checks({timeout = '?number'})
    local timeout = options and options.timeout or default_value
    print(timeout)
end

fn_good() -- ok, prints default_value
```

To keep backward compatibility you can use the flag `_G._checks_v2_compatible = true`.
This will substitute `nil` arguments with an empty table (as it used to be in v2.1).

```lua
_G._checks_v2_compatible = true
local checks = require('checks')
local json = require('json')

function fn_v2_compatible(options)
    checks({timeout = '?number'})
    print(options.timeout)
end

fn_v2_compatible() -- ok, prints "nil"
```

When an argument inside table type qualifier is specified without question mark
(i.e. not optional), whole table becomes mandatory:

```lua
function fn(options)
    checks({
        req_string = 'string',
    })
end

fn() -- error: bad argument options.req_string to fn (string expected, got nil)'
```

## Variable number of arguments

Functions with variable number of arguments are supported:

```lua
function fn_varargs(arg1, ...)
    checks('string')
end

fn_varargs('s') -- ok
fn_varargs('s', 1) -- ok
fn_varargs('s', {}) -- ok
fn_varargs(42) -- error: bad argument #1 to fn_varargs (string expected, got number)'
```

## Credits

This library was originally a part of
[luasched](https://github.com/SierraWireless/luasched).
Now it is a dependency for luacheck.
