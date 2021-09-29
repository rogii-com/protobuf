cmake_minimum_required(VERSION 3.12.4)
project(ProtobufCmakeNPMWrapper)

include(${PROJECT_SOURCE_DIR}/rogii/npm/Include.cmake)

CNPM_PREPARE_PACKAGES(
    DEFAULT_REPOSITORY_URLS
    "$ENV{CNPM_URLS}"
)

add_definitions(-D_GLIBCXX_USE_CXX11_ABI=1)

add_subdirectory(rogii/protobuf-cmake)

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
        ${PROJECT_SOURCE_DIR}/src/google/protobuf/stubs/stl_util.h
    DESTINATION
        ./include/google/protobuf/stubs
)

