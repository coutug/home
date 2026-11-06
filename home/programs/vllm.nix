{ config, ... }:

let
  home = config.home.homeDirectory;
in
{
  xdg.configFile."containers/systemd/vllm.container".text = ''
    [Unit]
    Description=vLLM Qwen3.8-27B inference server
    After=network-online.target
    Wants=network-online.target

    [Container]
    Image=docker.io/vllm/vllm-openai:v0.29.0
    ContainerName=vllm

    AddDevice=nvidia.com/gpu=all

    PublishPort=100.100.235.93:8001:8000

    Volume=${home}/.cache/huggingface:/root/.cache/huggingface
    Volume=${home}/.cache/vllm:/root/.cache/vllm

    ShmSize=8g

    Pull=missing

    Exec=--model cyankiwi/Qwen3.8-27B-AWQ-INT4 --served-model-name qwen38 --language-model-only --max-model-len 32768 --max-num-seqs 1 --gpu-memory-utilization 0.97 --enable-auto-tool-choice --tool-call-parser qwen3_coder --reasoning-parser qwen3 --default-chat-template-kwargs="{\"enable_thinking\":false}" --host 0.0.0.0 --port 8000

    [Service]
    Restart=on-failure
    RestartSec=5
    TimeoutStartSec=900
    TimeoutStopSec=60

    [Install]
    WantedBy=default.target
  '';
}
