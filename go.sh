#!/usr/bin/env bash

die() { printf $'Error: %s\n' "$*" >&2; exit 1; }
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
self=${BASH_SOURCE[0]:?}
project=${root##*/}
exec() { >&2 printf $'exec'; >&2 printf $' %q' "$@"; >&2 printf $'\n'; builtin exec "$@"; }


#---

data=/mnt/seenas2/data/LLMs

go---docker() {
    exec "${self:?}" docker \
    exec "${self:?}" "$@"
}

go---q2q3() {
    exec "${self:?}" q2q3 \
    exec "${self:?}" "$@"
}

go-exec() {
    exec "$@"
}


#--- Docker

docker_tag=${project,,}:latest
docker_name=${project,,}
docker_workdir=${PWD:?}
docker_start=(
    --mount="type=bind,src=${root:?},dst=${root:?},readonly=false"
    --mount="type=bind,src=${HOME:?},dst=${HOME:?},readonly=false"
)

go-docker() {
    "${FUNCNAME[0]:?}-$@"
}

go-docker-build() {
    exec docker build \
        --tag "${docker_tag:?}" \
        - <<'EOF'
FROM ubuntu:22.10
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        python3.10 \
        python3-pip \
        python3-virtualenv \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y \
        cmake \
    && rm -rf /var/lib/apt/lists/*
EOF
}

go-docker-start() {
    docker run \
        --rm \
        --init \
        --detach \
        --name "${docker_name:?}" \
        --mount "type=bind,src=/etc/passwd,dst=/etc/passwd,readonly=true" \
        --mount "type=bind,src=/etc/group,dst=/etc/group,readonly=true" \
        "${docker_start[@]}" \
        "${docker_tag:?}" \
        sleep infinity \
        ##
}

go-docker-stop() {
    exec docker stop \
        --time 0 \
        "${docker_name:?}" \
        ##
}

go-docker-exec() {
    exec docker exec \
        --interactive \
        --detach-keys="ctrl-q,ctrl-q" \
        --user "$(id -u):$(id -g)" \
        --workdir "${docker_workdir:?}" \
        --env USER \
        --env HOSTNAME \
        "${docker_name:?}" \
        "$@" \
		##
}


#--- llama.cpp: 2 and 3 bit quantization

q2q3_source_path=${root:?}/llama.cpp-q2q3
q2q3_binary_path=${q2q3_source_path:?}/build
q2q3_install_path=${q2q3_binary_path:?}/install
q2q3_configure=(
    -DCMAKE_INSTALL_PREFIX:PATH="${q2q3_install_path:?}"
    -DCMAKE_BUILD_TYPE:STRING=Release
)
q2q3_build=(
    --verbose
)
q2q3_install=(
    --verbose
)

go-q2q3() {
    "${FUNCNAME[0]:?}-$@"
}

go-q2q3-configure() {
    cmake \
        -H"${q2q3_source_path:?}" \
        -B"${q2q3_binary_path:?}" \
        "${q2q3_configure[@]}" \
        "$@" \
        ##
}

go-q2q3-build() {
    cmake \
        --build "${q2q3_binary_path:?}" \
        "${q2q3_build[@]}" \
        "$@" \
        ##
}

go-q2q3-install() {
    cmake \
        --install "${q2q3_binary_path:?}" \
        "${q2q3_install[@]}" \
        "$@" \
        ##
}

go-q2q3-exec() {
    PATH=${q2q3_binary_path:?}/bin${PATH:+:${PATH:?}} \
    exec "$@"
}


#---

source_path=${root:?}
binary_path=${root:?}/build
install_path=${binary_path:?}/install
configure=(
    -DCMAKE_INSTALL_PREFIX:PATH="${install_path:?}"
    -DCMAKE_BUILD_TYPE:STRING=Release
)
build=(
    --verbose
)
install=(
    --verbose
)

go-configure() {
    exec cmake \
        -H"${source_path:?}" \
        -B"${binary_path:?}" \
        "${configure[@]}" \
        "$@" \
        ##
}

go-build() {
    exec cmake \
        --build "${binary_path:?}" \
        "${build[@]}" \
        "$@" \
        ##
}

go-install() {
    exec cmake \
        --install "${binary_path:?}" \
        "${install[@]}" \
        "$@" \
        ##
}


#--- Raw LLaMA Weights

go-Download-Llama-Weights() {
    exec bash "${root:?}/llama/download.sh"
}


#--- HuggingFace LLaMA Weights

go-Convert-Llama-to-Huggingface() {
    convert=${root:?}/transformers/src/transformers/models/llama/convert_llama_weights_to_hf.py
    inputdir=${data:?}/llama
    modelsize=${1:?need modelsize}
    outputdir=${data:?}/llama/${modelsize^^}

    exec python3.8 "${convert:?}" \
        --input_dir "${inputdir:?}" \
        --model_size "${modelsize:?}" \
        --output_dir "${outputdir:?}" \
        ##
}


#--- WizardLM

go-WizardLM-Patch() {
    patch=${root:?}/WizardLM/src/weight_diff_wizard.py
    task=recover
    pathraw=${data:?}/llama/7B
    pathdiff=${data:?}/WizardLM/7B-Delta
    pathtuned=${data:?}/WizardLM/7B

    exec python3.8 "${patch:?}" \
        "${task:?}" \
        --path_raw "${pathraw:?}" \
        --path_diff "${pathdiff:?}" \
        --path_tuned "${pathtuned:?}" \
        ##
}


#--- Vicuna Weights

go-Apply-Vicuna-Weight-Delta() {
    modelsize=${1:?need modelsize}
    patch=${root:?}/FastChat/fastchat/model/apply_delta.py
    base=${data:?}/llama/${modelsize^^}
    targetmodelpath=${data:?}/vicuna/${modelsize^^}
    deltapath=lmsys/vicuna-${modelsize,,}-delta-v1.1

    mkdir -p "${targetmodelpath:?}" \
    || die "Failed to mkdir: ${_:?}"

    exec python3.8 "${patch:?}" \
        --base-model-path "${base:?}" \
        --target-model-path "${targetmodelpath:?}" \
        --delta-path "${deltapath:?}" \
        ##
}

go-Download-Bloom() {
    : ${1:?need modelname (e.g. bloom or bloomz)}
    modelname=${1,,}
    Modelname=${1^}
    MODELNAME=${1^^}

    : ${2:?need modelsize}
    modelsize=${2,,}
    MODELSIZE=${2^^}

    url=https://huggingface.co/bigscience/${modelname:?}-${modelsize:?}
    dstdir=${data:?}/${Modelname:?}/${MODELSIZE:?}

    mkdir -p "${dstdir%/*}"

    git lfs clone \
        "${url:?}" \
        "${dstdir:?}" \
        ##

}

go-Convert-Bloom-Tokenizer() {
    modelsize=${1:?need modelsize}

    convert=${root:?}/llama.cpp-pr867/tokenconvert.py
    tokenizertype=SentencePiece
    modelpath=${data:?}/Bloom/${modelsize:?}

    exec python3.8 "${convert:?}" \
        "${tokenizertype:?}" \
        "${modelpath:?}" \
        ##
}

go-Convert-Bloom-Weights() {
    modelname=${1:?need modelname}
    _modelname=${modelname,,}
    _Modelname=${modelname^}
    _MODELNAME=${modelname^^}

    modelsize=${2:?need modelsize}
    _modelsize=${modelsize,,}
    _MODELSIZE=${modelsize^^}

    convert=${root:?}/bloomz.cpp-main/convert-hf-to-ggml.py
    modelname=${data:?}/${_Modelname:?}/${modelsize:?}
    outputdir=${data:?}/${_Modelname:?}/${modelsize:?}
    tokenizername=bigscience/${_modelname:?}-${_modelsize:?}

    exec python3.8 "${convert:?}" \
        --model-name "${modelname:?}" \
        --output-dir "${outputdir:?}" \
        --tokenizer-name "${tokenizername:?}" \
        ##
}

go-Quantize-Bloom-Weights() {
    : ${1:?need modelname (e.g. bloom or bloomz)}
    modelname=${1,,}
    Modelname=${1^}
    MODELNAME=${1^^}

    : ${2:?need modelsize}
    modelsize=${2,,}
    MODELSIZE=${2^^}

    : ${3:?need quant name (e.g. q4_1 or q4_0)}
    quantname=${3,,}

    convert=${root:?}/bloomz.cpp-main/quantize
    floatmodel=${data:?}/${Modelname:?}/${MODELSIZE:?}/ggml-model-f16.bin
    quantmodel=${data:?}/${Modelname:?}/${MODELSIZE:?}/ggml-model-${quantname:?}.bin
    case "${quantname:?}" in
    (q4_0) quanttype=2;;
    (q4_1) quanttype=3;;
    esac

    exec "${convert:?}" \
        "${floatmodel:?}" \
        "${quantmodel:?}" \
        "${quanttype:?}" \
        ##
}

go-Update-Bloom-Weights() {
    modelsize=${1:?need modelsize}

    # convert=${root:?}/llama.cpp-pr867/convert-unversioned-ggml-to-ggml.py
    convert=${root:?}/llama.cpp-master/convert.py
    model=${data:?}/Bloom/${modelsize:?}/ggml-model-${modelsize:?}-f16.bin
    # tokenizer=${data:?}/Bloom/${modelsize:?}/tokenizer.model
    outfile=${data:?}/Bloom/${modelsize:?}/ggml-model-f16.bin

    exec python3.8 "${convert:?}" \
        "${model:?}" \
        --outfile "${outfile:?}" \
        ##

        # --vocab-dir "${tokenizer:?}"
}

go-Convert-Weights-to-GGML() {
    modelname=${1:?need modelname (e.g. "vicuna" or "Bloom")}
    modelsize=${2:?need modelsize (e.g. "7B" or "560M")}

    converter=${root:?}/llama.cpp-master/convert.py
    outtype=f16
    model=${data:?}/${modelname:?}/${modelsize:?}${3:+/${3:?}}

    exec python3.8 "${converter:?}" \
        --outtype "${outtype:?}" \
        "${model:?}" \
        ##
}

go-quantize() {
    quantize=${root:?}/llama.cpp/build/bin/quantize

    exec "${quantize:?}" \
        "$@" \
        ##
}


go-Quantize-f16-to-q4_2() {
    modelsize=${1:?need modelsize}
    original=${data:?}/vicuna/${modelsize^^}/ggml-model-f16.bin
    quantized=${data:?}/vicuna/${modelsize^^}/ggml-model-q4_2.bin
    level=3

    exec "${self:?}" quantize \
        "${original:?}" \
        "${quantized:?}" \
        "${level:?}"
}

go-Complete() {
    exec "${root:?}/llama.cpp/build/bin/main" \
        -m "${data:?}/vicuna/7B/ggml-model-q4_2.bin" \
        "$@" \
        ##
}

go-Server() {
    modelsize=${1:?need modelsize (e.g. 7B or 13B)}
    type=${2:?need type (e.g. f16 or q4_2)}
    port=${3:?need port (e.g. 7772)}

    PYTHONPATH=${root:?}/llama-cpp-python${PYTHONPATH:+:${PYTHONPATH:?}} \
    LLAMA_CPP_LIB=${root:?}/llama.cpp/build/libllama.so \
    HOST=127.0.0.1 \
    PORT=${port:?} \
    MODEL=${data:?}/vicuna/${modelsize^^}/ggml-model-${type,,}.bin \
    exec python3.8 -m llama_cpp.server \
        "$@" \
        ##
}


#--- Administrative stuff

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

go-exec() {
    exec "$@"
}

test -f "${root:?}/env.sh" && source "${_:?}"
go-"$@"
