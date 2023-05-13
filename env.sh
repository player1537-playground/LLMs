docker_tag=th--${docker_tag:?}
docker_name=th--${docker_name:?}
docker_start+=(
    --mount="type=bind,src=/mnt/seenas2/data/LLMs,dst=/mnt/seenas2/data/LLMs,readonly=false"
)
configure+=(
    -DQUANTIZE_MODELS:STRING="vicuna"
)
