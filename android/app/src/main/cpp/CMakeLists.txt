cmake_minimum_required(VERSION 3.22)
project(natsuyume_android LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---------------------------------------------------------------------------
# Paths to prebuilt JNI libs and headers
# Resolved relative to this file: android/app/src/main/cpp/
# Repo layout:  android/jni/libs/arm64-v8a/
#               android/jni/include/
# ---------------------------------------------------------------------------
set(JNI_ROOT     ${CMAKE_CURRENT_SOURCE_DIR}/../../../../jni)
set(JNI_LIBS     ${JNI_ROOT}/libs/${ANDROID_ABI})
set(JNI_INCLUDE  ${JNI_ROOT}/include)

# ---------------------------------------------------------------------------
# Pull in the core as a subdirectory
# Repo layout:  core/CMakeLists.txt  (relative to repo root)
# From android/app/src/main/cpp/ that's ../../../../.. + /core
# ---------------------------------------------------------------------------
set(CORE_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../core)

add_subdirectory(
    ${CORE_ROOT}
    ${CMAKE_CURRENT_BINARY_DIR}/core
)

# Pass JNI paths into the core build
target_include_directories(natsuyume_core PRIVATE
    ${JNI_INCLUDE}
    ${JNI_INCLUDE}/taglib
    ${JNI_INCLUDE}/mpv
)

# ---------------------------------------------------------------------------
# FFI bridge — thin C shim exposing NatsuyumeCore to Dart via dart:ffi
# ---------------------------------------------------------------------------
add_library(natsuyume_bridge SHARED
    natsuyume_bridge.cpp
)

target_include_directories(natsuyume_bridge PRIVATE
    ${CORE_ROOT}/src
    ${CORE_ROOT}/src/core
    ${JNI_INCLUDE}
)

target_link_libraries(natsuyume_bridge PRIVATE
    natsuyume_core
)
