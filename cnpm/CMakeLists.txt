cmake_minimum_required(VERSION 3.12.4)
project(ProtobufCmakeNPMWrapper)

include(${PROJECT_SOURCE_DIR}/cmake/npm/NastyPackageManager.cmake)

if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
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
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    NPM_ADD_PACKAGE(
        NAME
            gxx_runtime
        VERSION
            9.2.1
        BUILD_NUMBER
            0
    )
endif()

NPM_PREPARE_PACKAGES(
    DEFAULT_REPOSITORY_URLS
    "$ENV{CNPM_URLS}"
)

add_definitions(-D_GLIBCXX_USE_CXX11_ABI=1)

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
endif()

# install missing file(s)
install(
    FILES
        ${PROJECT_SOURCE_DIR}/../src/google/protobuf/stubs/stl_util.h
    DESTINATION
        ./include/google/protobuf/stubs
)

