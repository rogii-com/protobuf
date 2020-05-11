cmake_minimum_required(VERSION 3.12.4)
project(ProtobufCmakeNPMWrapper)

include(${PROJECT_SOURCE_DIR}/cmake/npm/NastyPackageManager.cmake)

NPM_ADD_PACKAGE(
    NAME
        msvs
    VERSION
        2019
    BUILD_NUMBER
        1
)

NPM_ADD_PACKAGE(
    NAME
        WindowsSDK
    VERSION
        10.0.18362.0
    BUILD_NUMBER
        2
)

NPM_PREPARE_PACKAGES(
    DEFAULT_REPOSITORY_URLS
    "$ENV{CNPM_URLS}"
)

add_subdirectory(protobuf-cmake)

if(WIN32)
    set_target_properties(
        libprotobuf
        PROPERTIES

        COMPILE_PDB_NAME
        "libprotobuf"

        COMPILE_PDB_NAME_DEBUG
        "libprotobufd"
    )

    set_target_properties(
        libprotoc
        PROPERTIES

        COMPILE_PDB_NAME
        "libprotoc"

        COMPILE_PDB_NAME_DEBUG
        "libprotocd"
    )

    install(
        FILES
            $<TARGET_FILE_DIR:libprotobuf>/$<TARGET_PROPERTY:libprotobuf,COMPILE_PDB_NAME>$<$<CONFIG:Debug>:d>.pdb
            $<TARGET_FILE_DIR:libprotoc>/$<TARGET_PROPERTY:libprotoc,COMPILE_PDB_NAME>$<$<CONFIG:Debug>:d>.pdb
        DESTINATION
            ./lib
    )
    install(
        FILES
            $<TARGET_FILE_DIR:protoc>/protoc.pdb
        DESTINATION
            ./bin
    )
    install(
        FILES
            ${PROJECT_SOURCE_DIR}/../src/google/protobuf/stubs/stl_util.h
        DESTINATION
            ./include/google/protobuf/stubs
    )
endif()
