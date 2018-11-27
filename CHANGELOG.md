# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
