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

```lua
local function fn(x)
    checks('number')
end
```

When the type qualifier is a string it can describe:

### Lua type

The type is simply `type(arg)`, such as `'table'`, `'number'` etc.

```lua
-- fn: checks('string')
fn('foo') -- ok
```

### Metatable type

An arbitrary name, which is stored in the `__type` field of the argument metatable

```lua
-- fn: checks('color')
local blue = setmetatable({0, 0, 255}, {__type = 'color'})
fn(blue) -- ok
```

### A type-checking function name

The function would be stored in the `checkers` global table.
This function is called with original value passed to `fn`
and must return `true` if the value is valid.  

```lua
-- fn: checkers('positive')
function checkers.positive(p)
  return (type(p) == 'number') and (p > 0)
end
fn(42) -- ok
fn(-1) -- error
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
local function fn(options)
    checks({
        my_string = '?string',
        my_number = '?number',
    })

    options.my_string -- safe
end

fn({my_string = 's'}) -- ok
fn({my_number = 101}) -- ok
fn({my_number = 'x'}) -- error
fn({bad_field = true}) -- error
```

When the optional argument is validated with the table type qualifier,
its value is set to an empty table. Thus it's safe to do:

```lua
local function fn(options)
    checks({timeout = '?number'})
    opts.timeout = opts.timeout or 5.0
end

fn() -- ok
```

## Variable number of arguments

Functions with variable number of arguments are supported:

```lua
local function fn(arg1, ...)
    checks('string')
end

fn('s') -- ok
fn('s', 1) -- ok
fn('s', {}) -- ok
fn(42) -- error
```

## Credits

This library was originally a part of
[[https://github.com/SierraWireless/luasched]]. Now a dependency for
luacheck.
