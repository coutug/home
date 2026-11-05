export function isTargetModel(model) {
  return model?.providerID === "vllm" && model?.id === "gemma4"
}
