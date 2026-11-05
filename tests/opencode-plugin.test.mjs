import assert from "node:assert/strict"
import test from "node:test"
import { isTargetModel } from "../home/config/opencode/plugins/gemma-tool-guidance/model-match.mjs"

test("matches Gemma 4 served by vLLM regardless of variant", () => {
  assert.equal(isTargetModel({ providerID: "vllm", id: "gemma4" }), true)
  assert.equal(isTargetModel({ providerID: "vllm", id: "gemma4", variant: "think" }), true)
})

test("does not match other providers or models", () => {
  assert.equal(isTargetModel({ providerID: "openrouter", id: "gemma4" }), false)
  assert.equal(isTargetModel({ providerID: "vllm", id: "other-model" }), false)
  assert.equal(isTargetModel(undefined), false)
  assert.equal(isTargetModel(null), false)
})
