# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.0.1] - 2019-05-23

### Fixed

- Repair multiple question marks (`checks('?type1|?type2')`) for better compatibility with v2.x,
  which has been accidentally broken in v3.0.0
- Further performance optimization by caching types qualifiers
- Speed up uuid, uuid_str, uuid_bin checkers

### Added

- v2.x compatibility flag `_G._checks_v2_compatible` which makes
  table type qualifiers to substitute nil arguments with an empty table
  (as it used to be in v2.1)

## [3.0.0] - 2018-11-27

### Fixed

- Performance optimization

### Changed

- Checking table type qualifiers does not change any arguments (incompatible change)

## [2.1.1] - 2018-08-22

### Fixed

- Checking required options `checks({required = 'string'})`
- Checking nested tables

## [2.1.0] - 2018-06-19

### Added

- Built-in checkers: `int64`, `uint64`
- Built-in checkers: `uuid`, `uuid_str`, `uuid_bin`

## [2.0.2] - 2018-06-08

### Fixed

- Specifying error level: `checks(2, ...)`

## [2.0.1] - 2018-05-30

### Fixed

- Filename and line number error reporting

## [2.0.0] - 2018-05-30

### Changed

- Rewritten source code to Lua
- msgpack.NULL is valid for optional parameters now (incompatible change)

### Added

- Ability to check "option" parameters following their hierarchical structure.
- Tests

## [1.0.0] - 2018-02-25

### Added

- Imported checks library from luarocks
