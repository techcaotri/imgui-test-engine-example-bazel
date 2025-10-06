"""Module extensions for fetching external git repositories - Fixed with proper header propagation."""

load("@bazel_tools//tools/build_defs/repo:git.bzl", "new_git_repository")

def _git_repos_impl(ctx):
    # GLFW - Window management
    new_git_repository(
        name = "glfw",
        remote = "https://github.com/glfw/glfw.git",
        tag = "3.3.8",
        build_file_content = """
cc_library(
    name = "glfw_headers",
    hdrs = glob(["include/GLFW/*.h"]),
    includes = ["include"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "glfw",
    srcs = select({
        "@platforms//os:linux": glob([
            "src/*.c",
            "src/*.h",
            "src/x11*.c",
            "src/posix*.c", 
            "src/linux*.c",
            "src/xkb*.c",
            "src/glx*.c",
            "src/egl*.c",
        ], exclude = [
            "src/win32*.c",
            "src/cocoa*.c",
            "src/cocoa*.m",
            "src/wgl*.c",
            "src/nsgl*.m",
            "src/wl*.c",
            "src/null*.c",
        ]),
        "@platforms//os:macos": glob([
            "src/*.c",
            "src/*.h",
            "src/cocoa*.c",
            "src/cocoa*.m",
            "src/posix*.c",
            "src/nsgl*.m",
            "src/egl*.c",
        ], exclude = [
            "src/win32*.c",
            "src/x11*.c",
            "src/linux*.c",
            "src/wgl*.c",
            "src/glx*.c",
            "src/wl*.c",
            "src/null*.c",
        ]),
        "@platforms//os:windows": glob([
            "src/*.c",
            "src/*.h",
            "src/win32*.c",
            "src/wgl*.c",
            "src/egl*.c",
        ], exclude = [
            "src/x11*.c",
            "src/posix*.c",
            "src/linux*.c",
            "src/cocoa*.c",
            "src/cocoa*.m",
            "src/nsgl*.m",
            "src/glx*.c",
            "src/wl*.c",
            "src/null*.c",
        ]),
    }),
    deps = [":glfw_headers"],
    defines = select({
        "@platforms//os:linux": ["_GLFW_X11"],
        "@platforms//os:windows": ["_GLFW_WIN32"],
        "@platforms//os:macos": ["_GLFW_COCOA"],
    }),
    linkopts = select({
        "@platforms//os:linux": [
            "-lX11",
            "-lXrandr",
            "-lXinerama",
            "-lXcursor",
            "-lXi",
            "-ldl",
            "-lpthread",
        ],
        "@platforms//os:windows": [
            "-lgdi32",
            "-lshell32",
            "-luser32",
        ],
        "@platforms//os:macos": [
            "-framework", "Cocoa",
            "-framework", "IOKit",
            "-framework", "CoreVideo",
        ],
    }),
    visibility = ["//visibility:public"],
)
""",
    )
    
    # Dear ImGui - Export ALL headers including internal ones
    new_git_repository(
        name = "imgui",
        remote = "https://github.com/ocornut/imgui.git",
        branch = "docking",
        build_file_content = """
# Export all headers as a filegroup first
filegroup(
    name = "imgui_headers",
    srcs = glob(["*.h"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "imgui_core",
    srcs = [
        "imgui.cpp",
        "imgui_demo.cpp",
        "imgui_draw.cpp",
        "imgui_tables.cpp",
        "imgui_widgets.cpp",
    ] + glob(["*.h"]),  # Add headers as sources too
    hdrs = glob(["*.h"]),
    includes = ["."],
    defines = ["IMGUI_ENABLE_TEST_ENGINE"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "imgui_backend_glfw",
    srcs = ["backends/imgui_impl_glfw.cpp"],
    hdrs = ["backends/imgui_impl_glfw.h"],
    deps = [
        ":imgui_core",
        "@glfw//:glfw",
    ],
    includes = [".", "backends"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "imgui_backend_opengl3",
    srcs = [
        "backends/imgui_impl_opengl3.cpp",
    ],
    hdrs = [
        "backends/imgui_impl_opengl3.h",
        "backends/imgui_impl_opengl3_loader.h",
    ],
    deps = [
        ":imgui_core",
        "@glfw//:glfw",
    ],
    includes = [".", "backends"],
    defines = [],
    copts = select({
        "@platforms//os:linux": [
            "-I/usr/include/GL",
        ],
        "@platforms//os:macos": [],
        "@platforms//os:windows": [],
        "//conditions:default": [],
    }),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "imgui",
    deps = [
        ":imgui_core",
        ":imgui_backend_glfw",
        ":imgui_backend_opengl3",
    ],
    visibility = ["//visibility:public"],
)
""",
    )
    
    # ImGui Test Engine - Add copts to ensure imgui directory is in path
    new_git_repository(
        name = "imgui_test_engine",
        remote = "https://github.com/ocornut/imgui_test_engine.git",
        branch = "main",
        build_file_content = """
cc_library(
    name = "test_engine",
    srcs = glob([
        "imgui_test_engine/*.cpp",
    ], exclude = [
        "imgui_test_engine/imgui_te_imconfig.cpp",
        "imgui_test_engine/imgui_capture_tool_cli.cpp",
    ]),
    hdrs = glob([
        "imgui_test_engine/*.h",
    ]) + glob([
        "imgui_test_engine/thirdparty/**/*.h",
    ]),
    includes = [
        ".",
        "imgui_test_engine",
    ],
    deps = [
        "@imgui//:imgui_core",
    ],
    defines = [
        "IMGUI_TEST_ENGINE_ENABLE_COROUTINE_STDTHREAD_IMPL=1",
        "IMGUI_TEST_ENGINE_ENABLE_CAPTURE=1",
        "IMGUI_TEST_ENGINE_ENABLE_STD_FUNCTION=1",
    ],
    copts = [
        "-std=c++17",
        "-Wno-unused-parameter",
        "-Wno-missing-field-initializers",
        "-Wno-format-security",
    ],
    visibility = ["//visibility:public"],
)
""",
    )

git_repos_ext = module_extension(
    implementation = _git_repos_impl,
)
