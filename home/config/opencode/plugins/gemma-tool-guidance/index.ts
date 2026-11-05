import { Plugin } from "@opencode/plugin"
import { isTargetModel } from "./model-match.mjs"

const TOOL_GUIDANCE = `# Tool routing

Native tools and execute's catalog are separate interfaces.

- Call native tools directly using their tool schemas. This includes
  webfetch, websearch, subagent, read, glob and grep when advertised.
- Do not call or search for native tools inside execute.
- Use execute only for tools in its catalog. Discover their exact paths
  with search and use the returned signatures. Never invent a path.
- A tool absent from execute's catalog may still be a native tool.

# Tool arguments

- Follow the selected tool's schema exactly.
- String values contain the value only: do not include extra quote
  characters. Example: {"url": "https://example.com"}.
- glob accepts one pattern string, not a list encoded as a string.
- For subagent, choose an advertised agent and give it a clear,
  self-contained task. Respect its permissions.

# Errors and results

- On an error, read the message and correct the interface or arguments.
  Do not repeat the same failed call unchanged.
- If a tool is unavailable or access is denied, report it. Do not claim
  success without a successful tool result.
- Base the answer on actual results; distinguish findings from guesses.
- Do not bypass permissions or higher-priority instructions.

# Read-only investigation

In plan mode, perform requested read-only investigation when permitted.
Do not ask again merely to confirm the requested read-only task.`

export default Plugin.define({
  id: "gemma-tool-guidance",
  async setup(ctx) {
    await ctx.session.hook("context", (event) => {
      if (!isTargetModel(event.model)) return

      event.system.push({ type: "text", text: TOOL_GUIDANCE })
    })
  },
})
