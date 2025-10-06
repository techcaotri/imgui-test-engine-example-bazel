# CMakeLists.txt - ImGui Test Engine with Coverage Support
cmake_minimum_required(VERSION 3.14)
project(imgui_test_app VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Options
option(ENABLE_COVERAGE "Enable code coverage" OFF)
option(BUILD_TESTS "Build tests" ON)
option(USE_SYSTEM_GLFW "Use system GLFW instead of bundled" OFF)

# Find packages
find_package(OpenGL REQUIRED)

if(USE_SYSTEM_GLFW)
    find_package(glfw3 3.3 REQUIRED)
else()
    # Add GLFW as submodule or FetchContent
    include(FetchContent)
    FetchContent_Declare(
        glfw
        GIT_REPOSITORY https://github.com/glfw/glfw.git
        GIT_TAG 3.3.8
    )
    FetchContent_MakeAvailable(glfw)
endif()

# Fetch Dear ImGui
include(FetchContent)
FetchContent_Declare(
    imgui
    GIT_REPOSITORY https://github.com/ocornut/imgui.git
    GIT_TAG v1.90.0
)
FetchContent_MakeAvailable(imgui)

# Fetch ImGui Test Engine
FetchContent_Declare(
    imgui_test_engine
    GIT_REPOSITORY https://github.com/ocornut/imgui_test_engine.git
    GIT_TAG main
)
FetchContent_MakeAvailable(imgui_test_engine)

# ImGui library
add_library(imgui STATIC
    ${imgui_SOURCE_DIR}/imgui.cpp
    ${imgui_SOURCE_DIR}/imgui_demo.cpp
    ${imgui_SOURCE_DIR}/imgui_draw.cpp
    ${imgui_SOURCE_DIR}/imgui_tables.cpp
    ${imgui_SOURCE_DIR}/imgui_widgets.cpp
    ${imgui_SOURCE_DIR}/backends/imgui_impl_glfw.cpp
    ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp
)

target_include_directories(imgui PUBLIC
    ${imgui_SOURCE_DIR}
    ${imgui_SOURCE_DIR}/backends
)

target_link_libraries(imgui PUBLIC
    glfw
    OpenGL::GL
)

# ImGui Test Engine library
add_library(imgui_test_engine STATIC
    ${imgui_test_engine_SOURCE_DIR}/imgui_test_engine/imgui_te.cpp
    ${imgui_test_engine_SOURCE_DIR}/imgui_test_engine/imgui_te_context.cpp
    ${imgui_test_engine_SOURCE_DIR}/imgui_test_engine/imgui_te_coroutine.cpp
    ${imgui_test_engine_SOURCE_DIR}/imgui_test_engine/imgui_te_engine.cpp
    ${imgui_test_engine_SOURCE_DIR}/imgui_test_engine/imgui_te_exporters.cpp
    ${imgui_test_engine_SOURCE_DIR}/imgui_test_engine/imgui_te_utils.cpp
    ${imgui_test_engine_SOURCE_DIR}/imgui_test_engine/imgui_te_ui.cpp
    ${imgui_test_engine_SOURCE_DIR}/imgui_test_engine/imgui_capture_tool.cpp
)

target_include_directories(imgui_test_engine PUBLIC
    ${imgui_test_engine_SOURCE_DIR}
    ${imgui_SOURCE_DIR}
)

target_link_libraries(imgui_test_engine PUBLIC
    imgui
)

target_compile_definitions(imgui_test_engine PUBLIC
    IMGUI_TEST_ENGINE_ENABLE_COROUTINE_STDTHREAD_IMPL=1
)

# Main application executable
add_executable(imgui_test_app
    main.cpp
)

target_link_libraries(imgui_test_app PRIVATE
    imgui
    imgui_test_engine
)

# Coverage configuration
if(ENABLE_COVERAGE)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        # Add coverage flags
        set(COVERAGE_FLAGS "--coverage -fprofile-arcs -ftest-coverage")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COVERAGE_FLAGS}")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${COVERAGE_FLAGS}")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${COVERAGE_FLAGS}")
        
        # Find lcov and genhtml
        find_program(LCOV lcov)
        find_program(GENHTML genhtml)
        
        if(LCOV AND GENHTML)
            # Add custom target for coverage
            add_custom_target(coverage
                COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/coverage
                COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/coverage
                
                # Capture initial zero coverage data
                COMMAND ${LCOV} --capture --initial --directory . --output-file ${CMAKE_BINARY_DIR}/coverage/base.info
                
                # Run tests
                COMMAND ${CMAKE_BINARY_DIR}/imgui_test_app --test --headless --report
                
                # Capture coverage data
                COMMAND ${LCOV} --capture --directory . --output-file ${CMAKE_BINARY_DIR}/coverage/test.info
                
                # Add baseline and test coverage data
                COMMAND ${LCOV} -a ${CMAKE_BINARY_DIR}/coverage/base.info -a ${CMAKE_BINARY_DIR}/coverage/test.info --output-file ${CMAKE_BINARY_DIR}/coverage/total.info
                
                # Remove unwanted files from coverage
                COMMAND ${LCOV} --remove ${CMAKE_BINARY_DIR}/coverage/total.info 
                    '/usr/*' '*/test/*' '*/build/*' '*/imgui_demo.cpp' 
                    '*/_deps/*' '*/imgui_test_engine/*'
                    --output-file ${CMAKE_BINARY_DIR}/coverage/filtered.info
                
                # Generate HTML report
                COMMAND ${GENHTML} ${CMAKE_BINARY_DIR}/coverage/filtered.info 
                    --output-directory ${CMAKE_BINARY_DIR}/coverage/html
                    --title "ImGui Test Application Coverage"
                    --legend --show-details --demangle-cpp
                
                # Print summary
                COMMAND ${LCOV} --summary ${CMAKE_BINARY_DIR}/coverage/filtered.info
                
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                DEPENDS imgui_test_app
                COMMENT "Generating code coverage report"
            )
            
            # Clean coverage files
            add_custom_target(coverage-clean
                COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/coverage
                COMMAND find ${CMAKE_BINARY_DIR} -name '*.gcda' -delete
                COMMAND find ${CMAKE_BINARY_DIR} -name '*.gcno' -delete
                COMMAND find ${CMAKE_BINARY_DIR} -name '*.info' -delete
                COMMENT "Cleaning coverage files"
            )
        else()
            message(WARNING "lcov and/or genhtml not found. Coverage report generation disabled.")
        endif()
    else()
        message(WARNING "Coverage is only supported with GCC or Clang compilers")
    endif()
endif()

# Testing support
if(BUILD_TESTS)
    enable_testing()
    
    # Add test executable (same as main app but with test flags)
    add_test(NAME imgui_tests
        COMMAND imgui_test_app --test --headless --report
    )
    
    # Add individual test categories
    add_test(NAME test_widgets
        COMMAND imgui_test_app --test --headless --filter "Widgets"
    )
    
    add_test(NAME test_windows
        COMMAND imgui_test_app --test --headless --filter "Windows"
    )
    
    add_test(NAME test_integration
        COMMAND imgui_test_app --test --headless --filter "Integration"
    )
    
    # Custom target to run tests
    add_custom_target(run-tests
        COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
        DEPENDS imgui_test_app
        COMMENT "Running ImGui tests"
    )
endif()

# Installation
install(TARGETS imgui_test_app
    RUNTIME DESTINATION bin
)

# Print configuration summary
message(STATUS "========================================")
message(STATUS "ImGui Test Application Configuration:")
message(STATUS "  C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "  Coverage Enabled: ${ENABLE_COVERAGE}")
message(STATUS "  Build Tests: ${BUILD_TESTS}")
message(STATUS "  System GLFW: ${USE_SYSTEM_GLFW}")
message(STATUS "========================================")

# Usage instructions
if(ENABLE_COVERAGE)
    message(STATUS "")
    message(STATUS "Coverage Usage:")
    message(STATUS "  1. Build: cmake --build . --target imgui_test_app")
    message(STATUS "  2. Run tests with coverage: cmake --build . --target coverage")
    message(STATUS "  3. View report: open ${CMAKE_BINARY_DIR}/coverage/html/index.html")
    message(STATUS "  4. Clean coverage: cmake --build . --target coverage-clean")
    message(STATUS "")
endif()
