cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "background_runtime_linux")
project(${PROJECT_NAME} LANGUAGES CXX)
cmake_policy(VERSION 3.10...3.25)
set(PLUGIN_NAME "background_runtime_linux_plugin")

list(APPEND PLUGIN_SOURCES
  "background_runtime_linux_plugin.cc"
  "background_runtime_linux_private.h"
)

# Standalone stub: link as a shared library.
# When built inside a Flutter project, flutter's CMake toolchain provides
# the flutter target, the apply_standard_settings function, and GTK via
# PkgConfig.  Here we define what we can inline for CI compilation.
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

# Inline Flutter's apply_standard_settings
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
  CXX_EXTENSIONS NO
  CXX_VISIBILITY_PRESET hidden
)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include")

# In Flutter builds this links against flutter.
# For standalone CI compilation we define a dummy target.
add_library(flutter SHARED IMPORTED)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)

find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
  pkg_check_modules(GTK IMPORTED_TARGET gtk+-3.0)
  if(GTK_FOUND)
    target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
  endif()
endif()

set(background_runtime_linux_bundled_libraries "" PARENT_SCOPE)
