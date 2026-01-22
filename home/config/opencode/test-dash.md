# Recipe – test dashboards workflow

## When to use
Use this recipe when you ask me to modify a Grafana dashboard and add:
- “Use test-dash.md”
- or “apply the test-dash.md recipe”

## Rules
1. After each JSON modification of the dashboard, publish a test version in Grafana (root folder).
2. The test version must have the `-test` suffix in both `title` **and** `uid`.
3. After each new round of changes, update the json file and republish the same test dashboard (same `title` and `uid` with `-test`) to overwrite the previous version. If overwrite fails, delete the test dashboard and recreate it with the same `-test` name/uid in the root folder.
4. After each publication, ask if you want more changes.
5. When you confirm everything is correct:
   - delete the test dashboard in Grafana,
   - remove the `-test` suffix in the versioned JSON,
   - ask if you want me to add the changes to Git.

## Example user prompt
“For the dashboard `monDashboard.json`, add a variable X and bind it to label Y. Change the title to ‘Mon Beau Dashboard’. Use test-dash.md.”

## Expected assistant behavior
1. Modify the dashboard JSON.
2. Publish the test version with `title` `Mon Beau Dashboard-test` and a `uid` suffixed with `-test`.
3. Ask if you want more changes.

## Iterative example
- **User**: “Yes, I also want to remove the last panel named ‘mon panneau’.”
- **Assistant**: modifies the JSON, republishes the test dashboard, asks if more changes are needed.

## End of cycle
- **User**: “No, everything is correct.”
- **Assistant**: deletes the test dashboard, removes `-test` suffixes, offers to add to Git.
