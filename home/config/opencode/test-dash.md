# Recipe – Grafana test dashboard loop

## Purpose
This recipe defines an iterative loop to edit a Grafana dashboard JSON, deploy a **test** version to Grafana, and ask for user feedback before each new round of changes.

## When to use
Use this recipe when the user asks to modify a Grafana dashboard and includes:
- “Use test-dash.md”
- or “apply the test-dash.md recipe”

## Mandatory loop
Repeat this sequence for **each** round of changes:

1. **Edit JSON**
   - Apply the requested changes to the dashboard JSON file.
2. **Publish test dashboard**
   - Deploy a test version to Grafana **root folder**.
   - The test dashboard **must** have `-test` suffix in both:
     - `title`
     - `uid`
3. **Ask for feedback**
   - Ask: “Do you want more changes?”
   - Do **not** proceed to another round without the user’s response.

## Test dashboard overwrite rules
- Always reuse the same `title` and `uid` suffixed with `-test` for the test deployment.
- If overwrite fails, delete the existing test dashboard and recreate it with the same `-test` title/uid.

## End of loop
When the user confirms the dashboard is final:
1. Delete the test dashboard in Grafana.
2. Remove the `-test` suffixes from the versioned JSON.
3. Ask: “Do you want me to add the changes to Git?”

## Example user prompt
“For the dashboard `monDashboard.json`, add a variable X bound to label Y. Change the title to ‘Mon Beau Dashboard’. Use test-dash.md.”

## Expected assistant behavior (summary)
- Modify JSON → publish `-test` version → ask for feedback.
- Repeat until user confirms.
- Cleanup test dashboard → remove `-test` → offer to add to Git.
