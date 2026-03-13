add_executable(hello_window)

target_sources(hello_window PRIVATE hello_window.cpp)

target_link_libraries(hello_window PRIVATE glfw glad::glad)
