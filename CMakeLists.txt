project(LLMs)
cmake_minimum_required(VERSION 3.24)

include(ExternalProject)


#--- llama.cpp with 2 and 3 bit quantization

ExternalProject_Add(_q2q3
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-q2q3"
    CMAKE_CACHE_ARGS
        "-DCMAKE_BUILD_TYPE:STRING=Release"
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property(_q2q3 SOURCE_DIR)
set(_q2q3_SOURCE_DIR "${SOURCE_DIR}")
ExternalProject_Get_Property(_q2q3 BINARY_DIR)
set(_q2q3_BINARY_DIR "${BINARY_DIR}")

add_executable(_q2q3_quantize IMPORTED)
set_property(
    TARGET _q2q3_quantize
    PROPERTY IMPORTED_LOCATION
        "${_q2q3_BINARY_DIR}/bin/quantize"
)
add_executable(q2q3::quantize ALIAS _q2q3_quantize)

add_executable(_q2q3_convert IMPORTED)
set_property(
    TARGET _q2q3_convert
    PROPERTY IMPORTED_LOCATION
        "${_q2q3_SOURCE_DIR}/convert.py"
)
add_executable(q2q3::convert ALIAS _q2q3_convert)


#--- WizardLM

ExternalProject_Add(_wizard_lm
    SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/WizardLM"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property(_wizard_lm SOURCE_DIR)
set(_wizard_lm_SOURCE_DIR "${SOURCE_DIR}")
ExternalProject_Get_Property(_wizard_lm BINARY_DIR)
set(_wizard_lm_BINARY_DIR "${BINARY_DIR}")

add_executable(_wizard_lm_patch IMPORTED)
set_property(TARGET _wizard_lm_patch PROPERTY
    IMPORTED_LOCATION
        "${_wizard_lm_SOURCE_DIR}/src/weight_diff_wizard.py"
)
add_executable(WizardLM::patch ALIAS _wizard_lm_patch)


#--- Generic Convert Function

function(convert)
    set(options
        ALL
    )
    set(oneValueArgs
        OUTPUT
        TARGET
        SOURCE
    )
    set(multiValueArgs
        COMMAND
    )
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

    if(DEFINED ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: unparsed arguments: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT DEFINED ARG_TARGET)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: TARGET required")
    endif()

    if(NOT DEFINED ARG_OUTPUT)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: OUTPUT required")
    endif()

    if(NOT DEFINED ARG_SOURCE)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: SOURCE required")
    endif()

    if(NOT DEFINED ARG_COMMAND)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: COMMAND required")
    endif()


    #---

    add_custom_command(
        OUTPUT "${ARG_OUTPUT}"
        MAIN_DEPENDENCY "${ARG_SOURCE}"
        COMMAND ${ARG_COMMAND}
    )

    set(_args)

    if(ARG_ALL)
        list(APPEND _args ALL)
    endif()

    add_custom_target(
        "${ARG_TARGET}" ${_args}
        DEPENDS "${ARG_OUTPUT}"
    )
endfunction(convert)


#--- Convert Pytorch to GGML

function(pytorch2ggml)
    set(options
    )
    set(oneValueArgs
        # Required
        OUTPUT
        TARGET

        # Optional
        EXECUTABLE
        SOURCE
        TYPE_INDEX
        TYPE_NAME
    )
    set(multiValueArgs
    )
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

    if(DEFINED ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: unparsed arguments: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT DEFINED ARG_TARGET)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: TARGET required")
    endif()

    if(NOT DEFINED ARG_OUTPUT)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: OUTPUT required")
    endif()

endfunction(pytorch2ggml)


#--- Quantize

function(quantize)
    set(options
    )
    set(oneValueArgs
        # Required
        OUTPUT
        TARGET

        # Optional
        EXECUTABLE
        SOURCE
        TYPE_INDEX
        TYPE_NAME
    )
    set(multiValueArgs
    )
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${options}" "${oneValueArgs}" "${multiValueArgs}")

    if(DEFINED ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: unparsed arguments: ${ARG_UNPARSED_ARGUMENTS}")
    endif()

    if(NOT DEFINED ARG_TARGET)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: TARGET required")
    endif()

    if(NOT DEFINED ARG_OUTPUT)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: OUTPUT required")
    endif()

    if(NOT DEFINED ARG_SOURCE)
        if(NOT ARG_OUTPUT MATCHES "(.+)/ggml-model-([^.]+)\\.bin$")
            message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: No default OUTPUT for SOURCE: ${ARG_SOURCE}")
        endif()

        set(ARG_SOURCE "${CMAKE_MATCH_1}/ggml-model-f16.bin")

        if(NOT DEFINED ARG_TYPE_NAME)
            set(ARG_TYPE_NAME "${CMAKE_MATCH_2}")
        endif()
    endif()

    if(NOT DEFINED ARG_TYPE_INDEX)
        if(ARG_TYPE_NAME STREQUAL "q2_0")
            set(ARG_TYPE_INDEX 5)
        elseif(ARG_TYPE_NAME STREQUAL "q3_0")
            set(ARG_TYPE_INDEX 6)
        elseif(ARG_TYPE_NAME STREQUAL "q4_0")
            set(ARG_TYPE_INDEX 2)
        elseif(ARG_TYPE_NAME STREQUAL "q4_1")
            set(ARG_TYPE_INDEX 3)
        elseif(ARG_TYPE_NAME STREQUAL "q4_2")
            set(ARG_TYPE_INDEX 7)
        elseif(ARG_TYPE_NAME STREQUAL "q4_3")
            set(ARG_TYPE_INDEX 8)
        else()
            message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: No default TYPE_INDEX for TYPE_NAME: ${ARG_TYPE_NAME}")
        endif()
    endif()

    if(NOT DEFINED ARG_EXECUTABLE)
        if(ARG_TYPE_NAME MATCHES "q2_0|q3_0|q4_0|q4_1|q4_2|q4_3")
            set(ARG_EXECUTABLE q2q3::quantize)
        else()
            message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: No default EXECUTABLE for TYPE_NAME: ${ARG_TYPE_NAME}")
        endif()
    endif()


    #---

    convert(
        TARGET "${ARG_TARGET}"
        OUTPUT "${ARG_OUTPUT}"
        SOURCE "${ARG_SOURCE}"
        COMMAND
            "${ARG_EXECUTABLE}"
                "${ARG_SOURCE}"
                "${ARG_OUTPUT}"
                "${ARG_TYPE_INDEX}"
    )
endfunction(quantize)

set(QUANTIZE_MODELS
        LLAMA
        VICUNA
    CACHE STRING "The models to quantize")

set(QUANTIZE_MODEL_VICUNA_SIZES
        7B
        13B
    CACHE STRING "The sizes of the model VICUNA")

set(QUANTIZE_MODEL_LLAMA_SIZES
        7B
        13B
        30B
        65B
    CACHE STRING "The sizes of the model LLAMA")

set(QUANTIZE_MODEL_VICUNA_TYPES
        q2_0
        q3_0
        q4_2
    CACHE STRING "The quantized types to generate for the model VICUNA")

set(QUANTIZE_MODEL_LLAMA_TYPES
        q2_0
        q3_0
        q4_2
    CACHE STRING "The quantized types to generate for the model LLAMA")

foreach(_model IN LISTS QUANTIZE_MODELS)
    string(TOLOWER "${_model}" _model)
    string(TOUPPER "${_model}" _MODEL)

    message(STATUS "Configuring quantization: ${_model}")

    foreach(_size IN LISTS "QUANTIZE_MODEL_${_MODEL}_SIZES")
        string(TOLOWER "${_size}" _size)
        string(TOUPPER "${_size}" _SIZE)

        message(STATUS "Configuring quantization: ${_model}-${_size}")

        foreach(_type IN LISTS "QUANTIZE_MODEL_${_MODEL}_TYPES")
            string(TOLOWER "${_type}" _type)
            string(TOUPPER "${_type}" _TYPE)

            message(STATUS "Configuring quantization: ${_model}-${_size}-${_type}")

            quantize(
                TARGET "${_model}-${_size}-${_type}"
                OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/data/${_model}/${_SIZE}/ggml-model-${_type}.bin"
            )
        endforeach()
    endforeach()
endforeach()
