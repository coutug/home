# Reusing a LinkedIn Login with `agent-browser`

This guide uses an isolated Chrome profile for LinkedIn. You log in yourself in a visible browser window; `agent-browser` then reuses that profile on later runs.

> **Security:** The profile contains active LinkedIn session cookies. Anyone who can read or control it may be able to use your account. Keep it outside the repository, restrict its permissions, and do not share it.

## How the pieces fit together

- `--profile <directory>` selects a persistent Chrome user-data directory. Cookies, local storage, IndexedDB, and other browser data persist there between browser launches.
- `--session <name>` selects an `agent-browser` control session. It separates browser sessions managed by the CLI; it does not make a shared profile safe for simultaneous Chrome processes.
- `state save <file>` exports a point-in-time copy of cookies and web storage. Treat it as a credential, not as ordinary data.
- `--session-name <name>` automatically persists browser state by name. It is a separate persistence mechanism from a Chrome profile.

For the workflow below, use the profile as the source of truth. Keep one browser process using it at a time.

## 1. Create a private profile directory

```bash
install -d -m 700 "$HOME/.agent-browser/profiles/linkedin"
```

`install -d` creates the directory and missing parents. Mode `700` gives the owner full access and denies access to other local users. Chrome will create its profile files inside this directory.

Do not put this directory in a Git repository or a synced/shared folder.

## 2. Sign in manually

```bash
LI_PROFILE="$HOME/.agent-browser/profiles/linkedin"

agent-browser --session linkedin --profile "$LI_PROFILE" --headed \
  open https://www.linkedin.com/login
```

- `--session linkedin` gives the CLI session a recognizable name.
- `--profile "$LI_PROFILE"` tells Chrome to use the persistent profile directory.
- `--headed` opens a visible browser window so you can enter your credentials and complete any 2FA or security challenge yourself.
- `open ...` navigates to LinkedIn's login page.

Complete login in the browser window. Do not send your password or one-time codes to an agent or put them in a command, script, or shell history. Do not automate or bypass LinkedIn security checks.

## 3. Check that login succeeded

```bash
agent-browser --session linkedin --profile "$LI_PROFILE" get url
```

An authenticated LinkedIn page, such as `/feed/`, is a good sign. A redirect to `/login`, `/authwall`, or `/checkpoint` means the session is not ready or LinkedIn requires further verification. Complete any challenge manually in the headed window.

Optionally check cookie **names** without printing their values:

```bash
agent-browser --session linkedin --profile "$LI_PROFILE" cookies --json \
  | jq -r '.[].name' | sort
```

`cookies --json` retrieves cookie data, including secret values; the `jq` filter emits names only. Do not remove the filter or paste raw cookie output into chat/logs. Cookie names vary; their presence alone does not prove login is valid.

## 4. Reuse profile on later runs

Close the browser after login if you want to end the current run:

```bash
agent-browser --session linkedin --profile "$LI_PROFILE" close
```

This closes the browser; it does not delete the profile. Later, start a browser with the same profile:

```bash
agent-browser --session linkedin --profile "$LI_PROFILE" \
  open https://www.linkedin.com/feed/
```

Verify access after navigation:

```bash
agent-browser --session linkedin --profile "$LI_PROFILE" get url
agent-browser --session linkedin --profile "$LI_PROFILE" snapshot -i
```

`snapshot -i` displays interactive page elements. After navigation or other page changes, take a fresh snapshot before using element references such as `@e1`; refs become stale when the page changes.

If LinkedIn redirects to login or a checkpoint, switch to a visible browser and complete the requested verification manually:

```bash
agent-browser --session linkedin --profile "$LI_PROFILE" --headed \
  open https://www.linkedin.com/login
```

Session expiry and additional checks are controlled by LinkedIn. Do not assume a profile guarantees indefinite access.

## Optional shell shortcut

Add this function to your shell startup file (for Bash, usually `~/.bashrc`) if you want to avoid repeating the flags:

```bash
li-browser() {
  agent-browser --session linkedin \
    --profile "$HOME/.agent-browser/profiles/linkedin" "$@"
}
```

Reload the shell configuration or open a new terminal. Then use:

```bash
li-browser open https://www.linkedin.com/feed/
li-browser snapshot -i
li-browser get url
li-browser close
```

For the initial manual login, call the full command with `--headed` as shown above. The function does not add `--headed` by default.

## Can multiple agents reuse this workflow?

### Sequential runs: yes, recommended

Agents can use the same profile at different times. Close the browser after one run before the next agent starts. Keep the profile path and CLI session name consistent. Each agent should take a fresh snapshot rather than relying on refs from an earlier run.

Do not let two agents independently launch Chrome against the same profile at once. Chrome profiles are not designed for concurrent independent processes; this can cause profile-lock errors, state conflicts, or unexpected browser control.

### Concurrent runs: use separate sessions cautiously

For concurrent agents, one option is to export a state snapshot and load it into separate browser sessions:

```bash
# While the authenticated profile's browser is running:
agent-browser --session linkedin --profile "$LI_PROFILE" \
  state save "$HOME/.agent-browser/linkedin-state.json"
chmod 600 "$HOME/.agent-browser/linkedin-state.json"

# Give each concurrent agent a distinct CLI session:
agent-browser --session linkedin-agent-a \
  --state "$HOME/.agent-browser/linkedin-state.json" \
  open https://www.linkedin.com/feed/

agent-browser --session linkedin-agent-b \
  --state "$HOME/.agent-browser/linkedin-state.json" \
  open https://www.linkedin.com/feed/
```

Each session gets its own browser context, but both copies carry the same authentication tokens. LinkedIn may rotate or invalidate tokens, and concurrent account activity can trigger additional verification. Treat the state file as a password: keep it private, never commit or share it, and delete it when no longer needed. State-file encryption is available through `AGENT_BROWSER_ENCRYPTION_KEY`; retain the key securely or the encrypted state cannot be restored.

Use this only when concurrent browsing is genuinely needed. Prefer sequential runs for reliability. Re-exporting state does not guarantee that LinkedIn will accept simultaneous copies of one account session.

Connecting multiple agents to one Chrome through CDP is another possibility, but they share tabs and browser control. Concurrent navigation/clicks can race, so this is not a reliable way to give agents independent workspaces.

## Cleanup and recovery

- To sign out remotely, use LinkedIn's **Settings → Sign in & security** session management and end the relevant session(s).
- To remove the local profile, first close its browser, then delete `~/.agent-browser/profiles/linkedin` yourself. This permanently removes local browser data; verify the path before deletion.
- To remove an exported state file, delete the exact file after closing any sessions that need it.
- If the profile becomes unusable, try a headed login first. Recreating the profile means starting with a fresh browser profile and signing in again.

## Operational notes

- Do not use `--profile Default` to attach to the Brave profile for this workflow. A dedicated profile keeps LinkedIn automation isolated from your everyday browser.
- Do not copy cookies into chat or print cookie values. Do not commit profiles, state files, or credentials.
- LinkedIn may limit automated activity and its terms may restrict it. Use the browser only for actions you are authorized to perform, at a conservative rate, and respect any prompts or restrictions shown by LinkedIn.
- If a command fails to launch, `agent-browser doctor --offline --quick` runs local diagnostics. Avoid `--fix` unless you have reviewed its repair actions.
