cmake_minimum_required(VERSION 3.16)
project(ProtobufCmakeNPMWrapper C CXX)

set(
    ROGII_FOLDER_PATH
    "${CMAKE_CURRENT_LIST_DIR}"
)
include(${ROGII_FOLDER_PATH}/npm/Include.cmake)
include(${ROGII_FOLDER_PATH}/environment.cmake)

CNPM_PREPARE_PACKAGES(
    DEFAULT_REPOSITORY_URLS
    "$ENV{CNPM_URLS}"
)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_definitions(-D_GLIBCXX_USE_CXX11_ABI=1)
endif()

# the static libraries may end up inside consumers' shared libraries
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(MSVC)
    # embed debug info into .obj/.lib (/Z7) instead of vc*.pdb files so that
    # the package stays debuggable without shipping a .pdb per abseil library
    foreach(
        FLAGS_VARIABLE

        CMAKE_C_FLAGS_DEBUG
        CMAKE_CXX_FLAGS_DEBUG
        CMAKE_C_FLAGS_RELWITHDEBINFO
        CMAKE_CXX_FLAGS_RELWITHDEBINFO
    )
        string(REPLACE "/Zi" "/Z7" ${FLAGS_VARIABLE} "${${FLAGS_VARIABLE}}")
    endforeach()
endif()

# protobuf attaches its own 'd' debug postfix to its libraries; this variable
# covers abseil and utf8_range so that the Debug and RelWithDebInfo builds can
# be installed into the same prefix without overwriting each other
set(CMAKE_DEBUG_POSTFIX "d")

set(protobuf_BUILD_TESTS OFF)
set(protobuf_BUILD_LIBPROTOC ON)
set(protobuf_BUILD_LIBUPB OFF)
set(protobuf_WITH_ZLIB OFF)
set(protobuf_MSVC_STATIC_RUNTIME OFF)

# always build abseil from sources so that it is installed into the package
# alongside protobuf (ABSL_ENABLE_INSTALL); set FETCHCONTENT_SOURCE_DIR_ABSL
# to reuse a local abseil checkout instead of downloading it from GitHub
set(protobuf_FORCE_FETCH_DEPENDENCIES ON)

add_subdirectory("${ROGII_FOLDER_PATH}/.." protobuf)
