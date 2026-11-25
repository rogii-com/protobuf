# Rogii protobuf package build

Builds a variant cnpm package (Debug + RelWithDebInfo static libraries,
release `protoc`, headers and the CMake config files of protobuf, abseil and
utf8_range) and the `protobuf` meta package that consumers pin. CI:
[3rd_party/upstream/protobuf](https://gitlab.rogii.com/3rd_party/upstream/protobuf).

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
- `PROTOBUF_VARIANT` — `default` (the default) builds
  `protobufdefault-<version>-<arch>-<build><tag>.7z`; `asan` (GCC/Clang only)
  builds `protobufasan-...` with protobuf, abseil and utf8_range, including
  `protoc`, compiled with `-fsanitize=address`

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

Consumers pin the `protobuf` meta package. Its `package.cmake`
(`meta/package.cmake.in`, made by `build_meta_package.cmake` from the variant
archives in `ENV_INSTALL`) fetches and includes one variant: `protobufasan`
when the consumer's `CMAKE_CXX_FLAGS` contain `-fsanitize=address`,
`protobufdefault` otherwise. The inline container annotations of protobuf and
abseil (`ABSL_ANNOTATE_CONTIGUOUS_CONTAINER`) are active only in instrumented
code, so an ASan consumer linked with the plain libraries reports false
container-overflow.

`test_package.cmake` makes the meta package from the archives in
`ENV_INSTALL`, then builds and runs `test/` against each variant, and checks
that the default variant in an ASan consumer does report that
container-overflow, so the probe is known to reach the annotated code.

A variant's `package.cmake` is the entry point the meta package includes. It runs `find_package(protobuf CONFIG)` against the
package prefix, which provides the same interface as the old hand-written
package: `protobuf::libprotobuf`, `protobuf::libprotoc`, `protobuf::protoc`
targets and `protobuf_generate()` / `protobuf_generate_cpp()` commands
(the latter via `protobuf_MODULE_COMPATIBLE`).
