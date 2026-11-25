# Checks the variant archives in ENV{ENV_INSTALL} the way a consumer meets them: makes the
# protobuf meta package, then configures a project that pins it, builds it and runs it, once
# plain and, when the asan variant is there, once with -fsanitize=address. A control build
# pins the default variant into an ASan consumer and has to report the false container-overflow
# the asan variant exists for, so the probe is known to reach the annotated code.

cmake_minimum_required(VERSION 3.21)

if(NOT DEFINED ENV{ENV_INSTALL})
    message(
        FATAL_ERROR
        "You have to specify the directory of the variant archives via `ENV{ENV_INSTALL}' variable."
    )
endif()

file(
    TO_CMAKE_PATH
    "$ENV{ENV_INSTALL}"
    ROOT
)

include(
    "${CMAKE_CURRENT_LIST_DIR}/version.cmake"
)

set(
    META_BUILD_NUMBER
    0
)

set(
    ENV{BUILD_NUMBER}
    ${META_BUILD_NUMBER}
)

execute_process(
    COMMAND
        ${CMAKE_COMMAND} -P "${CMAKE_CURRENT_LIST_DIR}/build_meta_package.cmake"
    COMMAND_ERROR_IS_FATAL
        ANY
)

set(
    GENERATOR_ARGS
    -G Ninja
)

if(WIN32)
    list(
        APPEND
            GENERATOR_ARGS
            -DCMAKE_CXX_COMPILER=cl
    )
endif()

set(
    ASAN_FLAGS
    "-fsanitize=address -fno-omit-frame-pointer"
)

set(
    BINARY_DIR
    "${ROOT}/test"
)

file(
    REMOVE_RECURSE
    "${BINARY_DIR}"
)

function(configure_and_build NAME BUILD_DIR)
    execute_process(
        COMMAND
            ${CMAKE_COMMAND}
            -S "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/test"
            -B "${BUILD_DIR}"
            ${GENERATOR_ARGS}
            "-DCNPM_ROOT=${ROOT}"
            ${ARGN}
        OUTPUT_VARIABLE
            CONFIGURE_OUTPUT
        ERROR_VARIABLE
            CONFIGURE_OUTPUT
        RESULT_VARIABLE
            CONFIGURE_RESULT
    )

    if(NOT CONFIGURE_RESULT EQUAL 0)
        message(
            FATAL_ERROR
            "${CONFIGURE_OUTPUT}\nConfiguring the ${NAME} test failed."
        )
    endif()

    execute_process(
        COMMAND
            ${CMAKE_COMMAND} --build "${BUILD_DIR}"
        COMMAND_ERROR_IS_FATAL
            ANY
    )

    set(
        CONFIGURE_OUTPUT
        "${CONFIGURE_OUTPUT}"
        PARENT_SCOPE
    )
endfunction()

function(check_variant VARIANT BUILD_DIR)
    if(NOT CONFIGURE_OUTPUT MATCHES "protobuf package variant: protobuf${VARIANT}-")
        message(
            FATAL_ERROR
            "${CONFIGURE_OUTPUT}\nThe meta package did not select the ${VARIANT} variant."
        )
    endif()

    file(
        STRINGS
            "${BUILD_DIR}/CMakeCache.txt"
            CONFIG_DIR_ENTRIES
        REGEX
            "^(protobuf|absl|utf8_range)_DIR:PATH="
    )

    if(NOT CONFIG_DIR_ENTRIES)
        message(
            FATAL_ERROR
            "The ${VARIANT} test build caches no protobuf package directory."
        )
    endif()

    foreach(CONFIG_DIR_ENTRY ${CONFIG_DIR_ENTRIES})
        if(NOT CONFIG_DIR_ENTRY MATCHES "/protobuf${VARIANT}-")
            message(
                FATAL_ERROR
                "The ${VARIANT} test build caches a directory of another package: ${CONFIG_DIR_ENTRY}"
            )
        endif()
    endforeach()
endfunction()

function(run_probe NAME BUILD_DIR)
    execute_process(
        COMMAND
            "${BUILD_DIR}/protobuf_package_test${CMAKE_EXECUTABLE_SUFFIX}"
        OUTPUT_VARIABLE
            RUN_OUTPUT
        ERROR_VARIABLE
            RUN_OUTPUT
        RESULT_VARIABLE
            RUN_RESULT
    )

    message(
        STATUS
        "${NAME}: exit code ${RUN_RESULT}: ${RUN_OUTPUT}"
    )

    set(
        RUN_OUTPUT
        "${RUN_OUTPUT}"
        PARENT_SCOPE
    )

    set(
        RUN_RESULT
        "${RUN_RESULT}"
        PARENT_SCOPE
    )
endfunction()

function(expect_clean_run NAME BUILD_DIR)
    run_probe(${NAME} "${BUILD_DIR}")

    if(NOT RUN_RESULT EQUAL 0 OR NOT RUN_OUTPUT MATCHES "parsed packed values" OR RUN_OUTPUT MATCHES "AddressSanitizer")
        message(
            FATAL_ERROR
            "The ${NAME} probe did not run to the end cleanly."
        )
    endif()
endfunction()

# The variants are configured one after another in the same build directory, as a consumer
# switching -fsanitize=address does.
message(
    STATUS
    "Testing the default variant"
)

configure_and_build(
    default
    "${BINARY_DIR}/build"
    -DCMAKE_BUILD_TYPE=Release
    -DPROTOBUF_TEST_BUILD_NUMBER=${META_BUILD_NUMBER}
    "-DPROTOBUF_TEST_TAG=$ENV{TAG}"
)
check_variant(default "${BINARY_DIR}/build")
expect_clean_run(default "${BINARY_DIR}/build")

file(
    GLOB
        DEFAULT_ARCHIVE
    "${ROOT}/protobufdefault-${ROGII_PKG_VERSION}-amd64-*$ENV{TAG}.7z"
)

file(
    GLOB
        ASAN_ARCHIVE
    "${ROOT}/protobufasan-${ROGII_PKG_VERSION}-amd64-*$ENV{TAG}.7z"
)

if(NOT ASAN_ARCHIVE)
    return()
endif()

message(
    STATUS
    "Testing the asan variant"
)

configure_and_build(
    asan
    "${BINARY_DIR}/build"
    -DCMAKE_BUILD_TYPE=Debug
    "-DCMAKE_CXX_FLAGS=${ASAN_FLAGS}"
    "-DCMAKE_EXE_LINKER_FLAGS=-fsanitize=address"
    -DPROTOBUF_TEST_BUILD_NUMBER=${META_BUILD_NUMBER}
    "-DPROTOBUF_TEST_TAG=$ENV{TAG}"
)
check_variant(asan "${BINARY_DIR}/build")
expect_clean_run(asan "${BINARY_DIR}/build")

message(
    STATUS
    "Control: the default variant in an ASan consumer"
)

get_filename_component(
    DEFAULT_ARCHIVE_NAME
    "${DEFAULT_ARCHIVE}"
    NAME
)

string(
    REGEX MATCH
        "-amd64-([0-9]+)"
        DEFAULT_BUILD_MATCH
        "${DEFAULT_ARCHIVE_NAME}"
)

configure_and_build(
    control
    "${BINARY_DIR}/control"
    -DCMAKE_BUILD_TYPE=Debug
    "-DCMAKE_CXX_FLAGS=${ASAN_FLAGS}"
    "-DCMAKE_EXE_LINKER_FLAGS=-fsanitize=address"
    -DPROTOBUF_TEST_VARIANT=protobufdefault
    -DPROTOBUF_TEST_BUILD_NUMBER=${CMAKE_MATCH_1}
    "-DPROTOBUF_TEST_TAG=$ENV{TAG}"
)
run_probe(control "${BINARY_DIR}/control")

if(NOT RUN_OUTPUT MATCHES "container-overflow")
    message(
        FATAL_ERROR
        "The control probe reported no container-overflow: the probe does not reach the annotated code."
    )
endif()
