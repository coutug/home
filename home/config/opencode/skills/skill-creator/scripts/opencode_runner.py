"""Small subprocess adapter for the pinned OpenCode V2 CLI."""

from __future__ import annotations

import json
import os
import shutil
import signal
import subprocess
from pathlib import Path
from typing import Any


class OpenCodeRunError(RuntimeError):
    """An OpenCode invocation failed or exceeded its deadline."""

    def __init__(
        self,
        message: str,
        *,
        session_id: str | None = None,
        events: list[dict[str, Any]] | None = None,
    ) -> None:
        super().__init__(message)
        self.session_id = session_id
        self.events = events or []


def _session_id_from_output(output: bytes | str | None) -> str | None:
    if output is None:
        return None
    text = output.decode("utf-8", errors="replace") if isinstance(output, bytes) else output
    for line in text.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(event, dict) and isinstance(event.get("sessionID"), str):
            return event["sessionID"]
    return None


def run_opencode(
    prompt: str,
    *,
    agent: str,
    model: str | None,
    cwd: Path,
    timeout: int,
    config: dict[str, Any] | None = None,
    json_output: bool = False,
) -> tuple[str, list[dict[str, Any]]]:
    """Run a fresh standalone OpenCode session and return text and JSON events.

    This is not an OS sandbox. Callers evaluating skill content must choose
    appropriate tool permissions and use disposable workspaces.
    """
    executable = shutil.which("opencode")
    if not executable:
        raise OpenCodeRunError("OpenCode CLI not found on PATH")
    if not prompt.strip():
        raise ValueError("OpenCode prompt cannot be empty")
    if timeout <= 0:
        raise ValueError("timeout must be a positive number of seconds")

    # Encode before spawning so invalid prompt data cannot orphan a process.
    prompt_bytes = prompt.encode("utf-8")
    location = cwd.resolve()
    location.mkdir(parents=True, exist_ok=True)
    command = [executable, "run", "--standalone", "--agent", agent]
    command += ["--format", "json" if json_output else "default"]
    if model:
        command += ["--model", model]

    env = os.environ.copy()
    env["PWD"] = str(location)
    env["OPENCODE_CONFIG_PROJECT_DISABLE"] = "1"
    if config is not None:
        env["OPENCODE_CONFIG_CONTENT"] = json.dumps(config)

    process = subprocess.Popen(
        command,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=location,
        env=env,
        start_new_session=True,
    )
    try:
        try:
            stdout, stderr = process.communicate(input=prompt_bytes, timeout=timeout)
        except subprocess.TimeoutExpired as error:
            raise OpenCodeRunError(
                f"OpenCode timed out after {timeout}s; the session was interrupted",
                session_id=_session_id_from_output(error.output),
            ) from error
    finally:
        # The detached process group will not receive this Python process's
        # terminal SIGINT. Interrupt it explicitly on timeout, cancellation, or
        # any exception, then force-kill and reap it if graceful shutdown stalls.
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGINT)
            except ProcessLookupError:
                pass
            try:
                process.communicate(timeout=3)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.communicate()

    output = stdout.decode("utf-8", errors="replace")
    error_text = stderr.decode("utf-8", errors="replace")
    events: list[dict[str, Any]] = []
    text_parts: list[str] = []
    if json_output:
        for line_number, line in enumerate(output.splitlines(), start=1):
            if not line.strip():
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError as error:
                raise OpenCodeRunError(
                    f"Invalid OpenCode JSON event at stdout line {line_number}: {error}",
                    session_id=_session_id_from_output(output),
                    events=events,
                ) from error
            if not isinstance(event, dict):
                raise OpenCodeRunError(
                    f"OpenCode event at stdout line {line_number} is not an object",
                    session_id=_session_id_from_output(output),
                    events=events,
                )
            events.append(event)
            if event.get("type") == "text":
                part = event.get("part", {})
                if isinstance(part, dict) and isinstance(part.get("text"), str):
                    text_parts.append(part["text"])
            if event.get("type") == "error":
                details = event.get("error", {})
                message = details.get("message") if isinstance(details, dict) else None
                raise OpenCodeRunError(
                    message or "OpenCode emitted an error event",
                    session_id=_session_id_from_output(output),
                    events=events,
                )
        text = "\n".join(text_parts).strip()
    else:
        text = output.strip()

    if process.returncode != 0:
        detail = error_text.strip() or output.strip() or "no diagnostic output"
        raise OpenCodeRunError(
            f"OpenCode exited with status {process.returncode}: {detail}",
            session_id=_session_id_from_output(output),
            events=events,
        )
    return text, events
