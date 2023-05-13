project(LLMs)
cmake_minimum_required(VERSION 3.24)

include(ExternalProject)


#--- llama.cpp-master

set(_target "_llamacpp_master")
ExternalProject_Add("${_target}"
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master"
    CMAKE_CACHE_ARGS
        "-DCMAKE_BUILD_TYPE:STRING=Release"
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property("${_target}" SOURCE_DIR)
set("${_target}_SOURCE_DIR" "${SOURCE_DIR}")
ExternalProject_Get_Property("${_target}" BINARY_DIR)
set("${_target}_BINARY_DIR" "${BINARY_DIR}")


#--- llama.cpp-pr867

set(_target "_llamacpp_pr867")
ExternalProject_Add("${_target}"
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-pr867"
    CMAKE_CACHE_ARGS
        "-DCMAKE_BUILD_TYPE:STRING=Release"
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property("${_target}" SOURCE_DIR)
set("${_target}_SOURCE_DIR" "${SOURCE_DIR}")
ExternalProject_Get_Property("${_target}" BINARY_DIR)
set("${_target}_BINARY_DIR" "${BINARY_DIR}")


#--- llama.cpp with 2 and 3 bit quantization

set(_target "_llamacpp_q2q3")
ExternalProject_Add("${_target}"
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-q2q3"
    CMAKE_CACHE_ARGS
        "-DCMAKE_BUILD_TYPE:STRING=Release"
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property("${_target}" SOURCE_DIR)
set("${_target}_SOURCE_DIR" "${SOURCE_DIR}")
ExternalProject_Get_Property("${_target}" BINARY_DIR)
set("${_target}_BINARY_DIR" "${BINARY_DIR}")


#--- bloomz.cpp-main

set(_target "_bloomzcpp_main")
ExternalProject_Add("${_target}"
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/bloomz.cpp-main"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND
        make -C "<SOURCE_DIR>"
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property("${_target}" SOURCE_DIR)
set("${_target}_SOURCE_DIR" "${SOURCE_DIR}")
ExternalProject_Get_Property("${_target}" BINARY_DIR)
set("${_target}_BINARY_DIR" "${BINARY_DIR}")


