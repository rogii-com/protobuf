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

set(
    BUILD_PATH
    "${CMAKE_CURRENT_LIST_DIR}/../build"
)

set(
    PACKAGE_NAME
    "protobuf-${ROGII_PKG_VERSION}-${ARCH}-${BUILD}${TAG}"
)

set(
    CMAKE_INSTALL_PREFIX
    ${ROOT}/${PACKAGE_NAME}
)

# Debug and RelWithDebInfo of one variant installed into one prefix
function(rogii_build_variant VARIANT_PREFIX VARIANT_BUILD_PATH SANITIZER)
    set(
        DEBUG_PATH
        "${VARIANT_BUILD_PATH}/debug"
    )

    set(
        RELEASE_PATH
        "${VARIANT_BUILD_PATH}/release"
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
        ${CMAKE_COMMAND} -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=${VARIANT_PREFIX} -DROGII_SANITIZER=${SANITIZER} ${CMAKE_CURRENT_LIST_DIR}
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
            ${CMAKE_COMMAND} -E remove_directory ${VARIANT_PREFIX}/bin
    )

    execute_process(
        COMMAND
        ${CMAKE_COMMAND} -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${VARIANT_PREFIX} -DROGII_SANITIZER=${SANITIZER} ${CMAKE_CURRENT_LIST_DIR}
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
endfunction()

rogii_build_variant(
    "${CMAKE_INSTALL_PREFIX}"
    "${BUILD_PATH}/plain"
    ""
)

# package.cmake switches an ASan consumer to this prefix: inline container
# annotations of protobuf and abseil are active only in instrumented code, so
# an ASan consumer linked with the plain libraries reports false container-overflow
if(NOT CMAKE_HOST_WIN32)
    rogii_build_variant(
        "${CMAKE_INSTALL_PREFIX}/asan"
        "${BUILD_PATH}/asan"
        "address"
    )
endif()

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
