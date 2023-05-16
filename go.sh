#!/usr/bin/env bash

die() { printf $'Error: %s\n' "$*" >&2; exit 1; }
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
project=${root##*/}
exec() { >&2 printf $'exec'; >&2 printf $' %q' "$@"; >&2 printf $'\n'; builtin exec "$@"; }


#---

data='/media/thobson/SD CARD A/DataSets/LLMs'

go-Server() {
    LLAMA_CPP_LIB=${llama_cpp__q2q3_binary_path:?}/libllama.so \
    MODEL=${data:?}/Vicuna/7B/ggml-model-q2_0.bin \
    PYTHONPATH=${root:?}/llama-cpp-python--v0.1.36${PYTHONPATH:+:${PYTHONPATH:?}} \
    exec python3 -m llama_cpp.server \
        "$@" \
        ##
}

go-AutoFFmpeg() {
    MODEL=${data:?}/Bloomz/560M/ggml-model-f16.bin \
    exec python3 -c '
import os
from transformers import (
    AutoModelForCausalLM as Model,
    AutoTokenizer as Tokenizer,
)
import rellm

model = Model.from_pretrained(


'
}


#---

llama_cpp__q2q3_source_path=${root:?}/llama.cpp--q2q3
llama_cpp__q2q3_binary_path=${llama_cpp__q2q3_source_path:?}/build
llama_cpp__q2q3_configure=(
    -DBUILD_SHARED_LIBS:BOOL=ON
    # -DLLAMA_AVX:BOOL=OFF
    -DLLAMA_FMA:BOOL=OFF
    -DLLAMA_F16C:BOOL=OFF
    -DLLAMA_AVX2:BOOL=OFF
    # -DLLAMA_OPENBLAS:BOOL=OFF
)
llama_cpp__q2q3_build=(
)

go-llama.cpp--q2q3() {
    "${FUNCNAME[0]:?}-$@"
}

go-llama.cpp--q2q3-clean() {
    rm -rfv -- \
        "${llama_cpp__q2q3_binary_path:?}" \
        ##
}

go-llama.cpp--q2q3-configure() {
    exec cmake \
        -H"${llama_cpp__q2q3_source_path:?}" \
        -B"${llama_cpp__q2q3_binary_path:?}" \
        "${llama_cpp__q2q3_configure[@]}" \
        "$@" \
        ##
}

go-llama.cpp--q2q3-build() {
    exec cmake \
        --build "${llama_cpp__q2q3_binary_path:?}" \
        "${llama_cpp__q2q3_build[@]}" \
        "$@" \
        ##
}


#--- r2d4's ReLLM and ParserLLM

r2d4_rellm_source_dir=${root:?}/rellm--main
r2d4_parserllm_source_dir=${root:?}/parserllm--main

go---r2d4() {
    exec "${self:?}" r2d4 \
    exec "${self:?}" "$@"
}

go-r2d4() {
    "${FUNCNAME[0]:?}-$@"
}

go-r2d4-exec() {
    PYTHONPATH=${r2d4_rellm_source_dir:?}${PYTHONPATH:+:${PYTHONPATH:?}} \
    PYTHONPATH=${r2d4_parserllm_source_dir:?}${PYTHONPATH:+:${PYTHONPATH:?}} \
    exec "$@"
}


#---

go-Add-Existing-Repo-as-Submodule() {
    localrepo=${1:?need relative path to repository (e.g. ./llama.cpp-q2q3)}

    remote=$(exec git \
        -C "${root:?}" \
        -C "${localrepo:?}" \
        config \
            --file .git/config \
            --get remote.origin.url \
            ##
    )

    exec git \
        -C "${root:?}" \
        submodule add \
            "${remote:?}" \
            "${localrepo:?}" \
            ##
}


#---

test -f "${root:?}/env.sh" && source "${_:?}"
go-"$@"
