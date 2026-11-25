cmake_minimum_required(VERSION 3.21)

project(protobuf_package_test CXX)

set(CMAKE_CXX_STANDARD 17)

include(${CMAKE_CURRENT_LIST_DIR}/../npm/Include.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../version.cmake)

# The meta package by default; PROTOBUF_TEST_VARIANT pins one variant package
# directly, bypassing the meta package's choice.
if(PROTOBUF_TEST_VARIANT)
    CNPM_ADD_PACKAGE(
        NAME
            ${PROTOBUF_TEST_VARIANT}
        VERSION
            ${ROGII_PKG_VERSION}
        BUILD_NUMBER
            ${PROTOBUF_TEST_BUILD_NUMBER}
        TAG
            "${PROTOBUF_TEST_TAG}"
    )
else()
    CNPM_ADD_PACKAGE(
        NAME
            protobuf
        VERSION
            ${ROGII_PKG_VERSION}
        BUILD_NUMBER
            ${PROTOBUF_TEST_BUILD_NUMBER}
        TAG
            "${PROTOBUF_TEST_TAG}"
    )
endif()

CNPM_PREPARE_PACKAGES(DEFAULT_REPOSITORY_URLS "")

add_executable(protobuf_package_test main.cpp probe.proto)

protobuf_generate(TARGET protobuf_package_test)

target_include_directories(protobuf_package_test PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

target_link_libraries(protobuf_package_test PRIVATE protobuf::libprotobuf)
