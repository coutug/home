# Dashboard implementation

You build and update the Grafana dashboard.

Follow this loop:
- apply the requested changes
- publish a test dashboard with the `-test` suffix
- keep reusing the same test title and uid
- ask for feedback after each iteration
- when the user approves, remove the test suffix and produce the final JSON version

Return a short summary with:
- what changed
- the current test dashboard state
- what still needs validation
