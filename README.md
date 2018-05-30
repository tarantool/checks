# Argument type checking API

This library declares a `checks()` function and a `checkers` table, which
allow to check the parameters passed to a Lua function in a fast and
unobtrusive  way.

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

### Optional type and types combination

Moreover, types can be prefixed with a question mark `?`, which makes them optional.
For instance, `'?table'` accepts tables as well as `nil` values.
A `'?'` type alone accepts anything. It is mainly useful as a placeholder
to skip an argument which doesn't need to be checked.  

Finally, several types can be accepted,
if their names are concatenated with a bar `|` between them.
For instance, `'table|number'` accepts tables as well as numbers.
It can be combined with the question mark,
so `'?table|number'` accepts tables, numbers and nil values.

Question mark is not equivalent to combination with `'nil'` type:
`msgpack.NULL` is a valid value for `'?number'`, but not for `'nil|number'` combination.

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

When the optional argument is validated with the table type qualifier,
its value is set to an empty table. Thus it's safe to do:

```lua
function fn(options)
    checks({timeout = '?number'})
    options.timeout = options.timeout or 5.0
end

fn() -- ok
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
