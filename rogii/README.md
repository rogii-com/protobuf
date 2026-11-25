# Rogii protobuf package build

Builds the `protobuf-<version>-<arch>-<build><tag>.7z` cnpm package
(Debug + RelWithDebInfo static libraries, release `protoc`, headers and the
CMake config files of protobuf, abseil and utf8_range).

## Usage

```
cmake -P rogii/build_amd64.cmake
```

Environment variables:

- `ENV_INSTALL` (required) — output directory for the package
- `CNPM_URLS` — cnpm repository URLs (msvs / windowssdk / gxx_runtime packages)
- `CNPM_ROOT` — cnpm download cache
- `BUILD_NUMBER` — package build number (default `0`)
- `TAG` — package tag suffix (default: short git hash)

On a non-Windows host the package also carries an AddressSanitizer variant:
protobuf, abseil and utf8_range (including `protoc`) built with
`-fsanitize=address` and installed whole into the `asan/` subdirectory.

On Windows run from an environment prepared by
`build/windows/jenkins_env` (MSVC toolchain + Windows SDK), Ninja required.

## Abseil

protobuf v35+ requires abseil. It is downloaded by CMake at configure time
from GitHub (the version is pinned in `cmake/dependencies.cmake`), built and
installed into the package together with protobuf, so the resulting package is
self-contained. To build without network access, clone abseil-cpp manually and
pass `FETCHCONTENT_SOURCE_DIR_ABSL=<path>` to the configure step.

Abseil pins its ABI options into the installed `absl/base/options.h` based on
configure-time compile tests, which is why the wrapper sets a global
`CMAKE_CXX_STANDARD`. Sanity check for a freshly built package:
`include/absl/base/options.h` must contain
`#define ABSL_OPTION_USE_STD_STRING_VIEW 1`, and the
`ABSL_INTERNAL_AT_LEAST_CXX17` test must be reported as `Success` in the
configure log. Otherwise consumers get LNK2019 mismatches around
`absl::string_view`.

## Consumers

`package.cmake` is the package entry point included by
`CNPM_PREPARE_PACKAGES()`. It runs `find_package(protobuf CONFIG)` against the
package prefix, which provides the same interface as the old hand-written
package: `protobuf::libprotobuf`, `protobuf::libprotoc`, `protobuf::protoc`
targets and `protobuf_generate()` / `protobuf_generate_cpp()` commands
(the latter via `protobuf_MODULE_COMPATIBLE`).

A consumer whose `CMAKE_CXX_FLAGS` contain `-fsanitize=address` gets the
`asan/` variant: the inline container annotations of protobuf and abseil
(`ABSL_ANNOTATE_CONTIGUOUS_CONTAINER`) are active only in instrumented code,
so an ASan consumer linked with the plain libraries reports false
container-overflow.
