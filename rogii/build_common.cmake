if(
    NOT DEFINED ROOT
    OR NOT DEFINED ARCH
)
    message(
        FATAL_ERROR
        "Assert: ROOT = ${ROOT}; ARCH = ${ARCH}"
    )
endif()

set(
    BUILD
    0
)

if(DEFINED ENV{BUILD_NUMBER})
    set(
        BUILD
        $ENV{BUILD_NUMBER}
    )
endif()

set(
    TAG
    ""
)

if(DEFINED ENV{TAG})
    set(
        TAG
        "$ENV{TAG}"
    )
else()
    find_package(
        Git
    )

    if(Git_FOUND)
        execute_process(
            COMMAND
                ${GIT_EXECUTABLE} rev-parse --short HEAD
            OUTPUT_VARIABLE
                TAG
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set(
            TAG
            "_${TAG}"
        )
    endif()
endif()

include(
    "${CMAKE_CURRENT_LIST_DIR}/version.cmake"
)

# default: the plain build; asan: the whole package built with -fsanitize=address,
# which the protobuf meta package hands to consumers whose CMAKE_CXX_FLAGS have it
set(
    VARIANT
    default
)

if(DEFINED ENV{PROTOBUF_VARIANT})
    set(
        VARIANT
        "$ENV{PROTOBUF_VARIANT}"
    )
endif()

set(
    SANITIZER
    ""
)

if(VARIANT STREQUAL "asan")
    if(CMAKE_HOST_WIN32)
        message(
            FATAL_ERROR
            "The asan variant is built with GCC/Clang only"
        )
    endif()

    set(
        SANITIZER
        address
    )
elseif(NOT VARIANT STREQUAL "default")
    message(
        FATAL_ERROR
        "Unknown PROTOBUF_VARIANT '${VARIANT}': expected default or asan"
    )
endif()


set(
    BUILD_PATH
    "${CMAKE_CURRENT_LIST_DIR}/../build"
)

set(
    PACKAGE_NAME
    "protobuf${VARIANT}-${ROGII_PKG_VERSION}-${ARCH}-${BUILD}${TAG}"
)

set(
    CMAKE_INSTALL_PREFIX
    ${ROOT}/${PACKAGE_NAME}
)

set(
    DEBUG_PATH
    "${BUILD_PATH}/debug"
)

set(
    RELEASE_PATH
    "${BUILD_PATH}/release"
)

file(
    MAKE_DIRECTORY
    "${DEBUG_PATH}"
)

file(
    MAKE_DIRECTORY
    "${RELEASE_PATH}"
)

execute_process(
    COMMAND
    ${CMAKE_COMMAND} -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DROGII_SANITIZER=${SANITIZER} ${CMAKE_CURRENT_LIST_DIR}
    WORKING_DIRECTORY
        "${DEBUG_PATH}"
    COMMAND_ERROR_IS_FATAL
        ANY
)

execute_process(
    COMMAND
        "${CMAKE_COMMAND}" --build . --target install
    WORKING_DIRECTORY
        "${DEBUG_PATH}"
    COMMAND_ERROR_IS_FATAL
        ANY
)

# remove debug protoc: the release run below reinstalls bin/protoc at the very
# same path (protoc has no debug postfix), so the CMake export files stay valid
execute_process(
    COMMAND
        ${CMAKE_COMMAND} -E remove_directory ${CMAKE_INSTALL_PREFIX}/bin
)

execute_process(
    COMMAND
    ${CMAKE_COMMAND} -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} -DROGII_SANITIZER=${SANITIZER} ${CMAKE_CURRENT_LIST_DIR}
    WORKING_DIRECTORY
        "${RELEASE_PATH}"
    COMMAND_ERROR_IS_FATAL
        ANY
)

execute_process(
    COMMAND
        "${CMAKE_COMMAND}" --build . --target install
    WORKING_DIRECTORY
        "${RELEASE_PATH}"
    COMMAND_ERROR_IS_FATAL
        ANY
)

file(
    COPY
        "${CMAKE_CURRENT_LIST_DIR}/package.cmake"
    DESTINATION
        "${ROOT}/${PACKAGE_NAME}"
)

file(
    REMOVE_RECURSE
    "${BUILD_PATH}"
)

execute_process(
    COMMAND
        "${CMAKE_COMMAND}" -E tar cf "${PACKAGE_NAME}.7z" --format=7zip -- "${PACKAGE_NAME}"
    WORKING_DIRECTORY
        "${ROOT}"
)
