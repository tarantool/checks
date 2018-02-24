cmake_minimum_required(VERSION 2.8 FATAL_ERROR)

project(checks C)

if (APPLE)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -undefined suppress -flat_namespace")
endif(APPLE)

# Find Tarantool and Lua dependecies
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})
set(TARANTOOL_FIND_REQUIRED ON)
find_package(Tarantool REQUIRED)
include_directories(${TARANTOOL_INCLUDE_DIRS})

# Add C library
add_library(checks SHARED checks.c)

set_target_properties(checks PROPERTIES PREFIX "")

# Install module
install(TARGETS checks LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/${TARANTOOL_INSTALL_LIBDIR})
