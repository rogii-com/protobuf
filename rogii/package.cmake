# Consumer-side interface of the cnpm package.
# Included by CNPM_PREPARE_PACKAGES() during the consumer's configure step.
#
# The package ships the CMake config files installed by protobuf itself
# (plus the bundled abseil and utf8_range ones), so all the imported targets
# (protobuf::libprotobuf, protobuf::libprotoc, protobuf::protoc, absl::*) and
# the protobuf_generate()/protobuf_generate_cpp() commands come from there.

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # see for details https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_dual_abi.html
    # and the corresponding description in https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_macros.html
    add_definitions(-D_GLIBCXX_USE_CXX11_ABI=1)
endif()

# make the FindProtobuf-compatible commands (protobuf_generate_cpp() etc.)
# available after find_package()
set(protobuf_MODULE_COMPATIBLE TRUE)

list(
    INSERT
        CMAKE_PREFIX_PATH
        0
        "${CMAKE_CURRENT_LIST_DIR}"
)

find_package(
    protobuf
    CONFIG
    REQUIRED
)

# The package contains Debug and RelWithDebInfo binaries only. Map the other
# consumer configurations to RelWithDebInfo explicitly: otherwise CMake may
# silently pick the Debug variant for a Release build.
get_directory_property(
    ROGII_PROTOBUF_IMPORTED_TARGETS
    IMPORTED_TARGETS
)
foreach(ROGII_PROTOBUF_TARGET IN LISTS ROGII_PROTOBUF_IMPORTED_TARGETS)
    if(ROGII_PROTOBUF_TARGET MATCHES "^(protobuf|absl|utf8_range)::")
        set_property(
            TARGET
                ${ROGII_PROTOBUF_TARGET}
            PROPERTY
                MAP_IMPORTED_CONFIG_RELEASE RelWithDebInfo ""
        )
        set_property(
            TARGET
                ${ROGII_PROTOBUF_TARGET}
            PROPERTY
                MAP_IMPORTED_CONFIG_MINSIZEREL RelWithDebInfo ""
        )
    endif()
endforeach()
unset(ROGII_PROTOBUF_IMPORTED_TARGETS)
unset(ROGII_PROTOBUF_TARGET)
