cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "background_runtime_windows")
project(${PROJECT_NAME} LANGUAGES CXX)
cmake_policy(VERSION 3.14...3.25)
set(PLUGIN_NAME "background_runtime_windows_plugin")

list(APPEND PLUGIN_SOURCES
  "background_runtime_windows_plugin.cpp"
  "background_runtime_windows_plugin.h"
)

# Standalone stub: link as a shared library.
# When built inside a Flutter project, flutter's CMake toolchain provides
# flutter and flutter_wrapper_plugin targets plus the apply_standard_settings
# function.  Here we define them inline so CI can validate compilation.
add_library(${PLUGIN_NAME} SHARED
  "include/background_runtime_windows/background_runtime_windows_c_api.h"
  "background_runtime_windows_c_api.cpp"
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

# In Flutter builds these are linked against flutter and flutter_wrapper_plugin.
# For standalone CI compilation we define dummy stubs.
add_library(flutter SHARED IMPORTED)
add_library(flutter_wrapper_plugin SHARED IMPORTED)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

set(background_runtime_windows_bundled_libraries "" PARENT_SCOPE)
