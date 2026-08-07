include_files = {'**/*.lua', '*.luacheckrc', '*.rockspec'}
exclude_files = {'.rocks/', 'tmp/', 'build/'}
max_line_length = 120
redefined = false
globals = {
    "box",
}
ignore = {
    -- Accessing an undefined field of a global variable <table>.
    "143/table",
    -- Unused variable with `_` prefix.
    "212/_.*",
}
