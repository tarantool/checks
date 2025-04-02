cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

project(checks NONE)

## Install ####################################################################
###############################################################################

if(NOT DEFINED TARANTOOL_INSTALL_LUADIR)
    set(TARANTOOL_INSTALL_LUADIR "${PROJECT_SOURCE_DIR}/.rocks/share/tarantool")
endif()

install(
  FILES ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.lua
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}
)

install(
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}
)

install(
  FILES ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}.lua
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}/override
)

install(
  DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}
  DESTINATION ${TARANTOOL_INSTALL_LUADIR}/override
)
