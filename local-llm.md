# Local LLMs — RTX 3090 24 GB

For summarization, generation, and text understanding. Starting configurations; validate against the exact vLLM version and checkpoint. Memory estimates are approximate; quantization, context, and KV cache affect usage.

## Shared settings

- Use a recent vLLM release that supports the model architecture; RTX 3090 is NVIDIA Ampere.
- Start with `--max-model-len 8192 --max-num-seqs 1 --gpu-memory-utilization 0.88`. Increase context or concurrency only after checking VRAM.
- Prefer vLLM-compatible **4-bit AWQ/GPTQ** checkpoints. AWQ/GPTQ/Marlin support Ampere. Avoid BF16/FP16 for 26–27B models: weights alone exceed 24 GB.
- Example:

```bash
vllm serve <checkpoint> --max-model-len 8192 --max-num-seqs 1 --gpu-memory-utilization 0.88
```

Quantized checkpoints should include their quantization configuration, which vLLM normally detects. Do not add `--quantization` unless checkpoint instructions require it.

## Models

### Qwen3.8-27B — best all-rounder

- **Checkpoint**: `Qwen/Qwen3.8-27B` is BF16; use a compatible 4-bit AWQ/GPTQ checkpoint, e.g. `cyankiwi/Qwen3.8-27B-AWQ-INT4`.
- **Configuration**: 4-bit; shared settings above; start with 8K context. Disable thinking for quick summaries; enable for complex analysis, using chat-template options supported by the checkpoint/vLLM.
- **Pros**: versatile; strong comprehension and summarization; configurable thinking; long native context.
- **Cons**: large dense model; quantization and KV cache limit context and throughput on 24 GB; thinking can greatly increase response length.
- **Why these settings**: 4-bit weights leave room for KV cache; 8K context and one sequence reduce OOM risk.

### Gemma 4 26B-A4B-it — throughput-oriented alternative

- **Checkpoint**: `google/gemma-4-26B-A4B-it`; for the 3090, use a compatible 4-bit AWQ checkpoint, e.g. `cyankiwi/gemma-4-26B-A4B-it-AWQ-4bit`.
- **Configuration**: 4-bit; shared settings; start at 8K. Confirm the vLLM release and quantized checkpoint support Gemma 4 together; compatibility has varied by release.
- **Pros**: MoE with about 4B active parameters per token; potentially fast; capable general and multimodal model.
- **Cons**: all experts still need to be loaded—“4B active” does not mean 4B weights; quantization compatibility is less certain; vendor benchmarks do not establish French quality.
- **Why these settings**: 4-bit is needed to fit weights and cache; modest sequence/context settings reduce peak memory.

### Gemma 4 12B-it — more memory headroom and batching

- **Checkpoint**: `google/gemma-4-12B-it`; use a 4-bit AWQ/GPTQ version to reserve VRAM for context.
- **Configuration**: 4-bit; shared settings; then increase context or `--max-num-seqs` based on available VRAM.
- **Pros**: smaller; good candidate for quick responses, repeated processing, and longer context.
- **Cons**: weaker than larger models on difficult reasoning and summarization; quality also depends on quantization.
- **Why these settings**: smaller weights leave memory for KV cache or concurrent requests; 4-bit maximizes that headroom.

### Qwen3-14B — established compact option

- **Checkpoint**: instruction-tuned Qwen3-14B in a vLLM-compatible 4-bit AWQ or GPTQ version.
- **Configuration**: 4-bit; shared settings; start at 8K, then tune context/concurrency after measuring.
- **Pros**: good quality/speed/size balance; more headroom than a 27B for long documents or multiple requests.
- **Cons**: older generation and capabilities than Qwen3.8; carefully verify the quantized model and format.
- **Why these settings**: moderate size suits 24 GB; quantization reserves more VRAM for KV cache.

## Recommendation

Start with **Qwen3.8-27B AWQ INT4**, 8K, one sequence. Compare with **Gemma 4 12B-it 4-bit** when throughput or longer documents matter most. Test Gemma 4 26B-A4B only with an explicitly compatible vLLM release/checkpoint. For books or large collections, summarize sections then synthesize: advertised model context is not necessarily usable context on 24 GB.

## References

- [Qwen3.8-27B](https://huggingface.co/Qwen/Qwen3.8-27B) · [recette vLLM](https://recipes.vllm.ai/Qwen/Qwen3.8-27B)
- [Gemma 4 26B-A4B](https://huggingface.co/google/gemma-4-26B-A4B) · [recette vLLM](https://recipes.vllm.ai/Google/gemma-4-26B-A4B-it)
- [vLLM documentation — quantization and supported hardware](https://docs.vllm.ai/en/latest/features/quantization/)
