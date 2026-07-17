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

# The C++ standard must be set GLOBALLY (not only on the protobuf targets):
# abseil pins its ABI options (ABSL_OPTION_USE_STD_STRING_VIEW etc.) into the
# installed options.h based on configure-time compile tests. Without this the
# tests run with the compiler default (C++14 on MSVC) while the libraries are
# built as C++17, and the package ends up ABI-inconsistent with itself.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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
# libupb must stay enabled: the rust generator inside libprotoc includes
# upb bootstrap headers that are only generated while building libupb
set(protobuf_BUILD_LIBUPB ON)
set(protobuf_WITH_ZLIB OFF)
set(protobuf_MSVC_STATIC_RUNTIME OFF)

# always build abseil from sources so that it is installed into the package
# alongside protobuf (ABSL_ENABLE_INSTALL); set FETCHCONTENT_SOURCE_DIR_ABSL
# to reuse a local abseil checkout instead of downloading it from GitHub
set(protobuf_FORCE_FETCH_DEPENDENCIES ON)

add_subdirectory("${ROGII_FOLDER_PATH}/.." protobuf)
