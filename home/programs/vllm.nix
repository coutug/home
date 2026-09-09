{ config, ... }:

let
  home = config.home.homeDirectory;
in
{
  xdg.configFile."containers/systemd/vllm.container".text = ''
    [Unit]
    Description=vLLM inference server
    After=network-online.target
    Wants=network-online.target

    [Container]
    Image=docker.io/vllm/vllm-openai:v0.29.0
    ContainerName=vllm

    AddDevice=nvidia.com/gpu=all

    PublishPort=127.0.0.1:8001:8000

    Volume=${home}/.cache/huggingface:/root/.cache/huggingface
    Volume=${home}/.cache/vllm:/root/.cache/vllm

    ShmSize=8g

    Pull=missing

    Exec=--model google/gemma-4-12B-it-qat-w4a16-ct --served-model-name gemma4 --language-model-only --max-model-len 32768 --gpu-memory-utilization 0.92 --host 0.0.0.0 --port 8000

    [Service]
    Restart=on-failure
    RestartSec=5
    TimeoutStartSec=900
    TimeoutStopSec=60

    [Install]
    WantedBy=default.target
  '';
}
