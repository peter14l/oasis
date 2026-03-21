cmake_minimum_required(VERSION 3.10)
project(flutter_secure_storage_windows_stub)

set(BINARY_NAME "flutter_secure_storage_windows_plugin")

add_library(${BINARY_NAME} SHARED
  "flutter_secure_storage_windows_plugin.cpp"
)

apply_standard_settings(${BINARY_NAME})
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${BINARY_NAME} INTERFACE "include")
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_plugin)
