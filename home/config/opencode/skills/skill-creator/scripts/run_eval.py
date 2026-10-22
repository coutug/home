#!/usr/bin/env python3
"""Measure natural OpenCode skill loading for a description and query set."""

import argparse
import json
import shutil
import sys
import tempfile
import time
import uuid
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path
from typing import Any

from scripts.opencode_runner import OpenCodeRunError, run_opencode
from scripts.utils import parse_skill_md, replace_skill_description


def _eval_config(
    skill_root: Path, candidate_id: str, *, include_skill: bool = True
) -> dict[str, Any]:
    # V2 defaults allow tools. Deny all actions for this disposable evaluation,
    # then allow the ambient style skill and, only for candidate runs, candidate.
    # Parent agent rules append after global rules.
    permissions = [
        {"action": "*", "resource": "*", "effect": "deny"},
        {"action": "skill", "resource": "caveman", "effect": "allow"},
    ]
    if include_skill:
        permissions.append(
            {"action": "skill", "resource": candidate_id, "effect": "allow"}
        )
    return {
        "skills": [str(skill_root.resolve())],
        "agents": {"plan": {"permissions": permissions}},
    }


def _candidate_tool_calls(
    events: list[dict[str, Any]], candidate_id: str
) -> tuple[bool, list[str]]:
    """Return successful candidate load and diagnostics for failed load calls."""
    loaded = False
    errors: list[str] = []
    for event in events:
        if event.get("type") != "tool_use":
            continue
        part = event.get("part")
        if not isinstance(part, dict) or part.get("tool") != "skill":
            continue
        state = part.get("state")
        if not isinstance(state, dict):
            continue
        tool_input = state.get("input")
        # V2 skill tool selects by exact ID; `name` is display metadata, not ID.
        if not isinstance(tool_input, dict) or tool_input.get("id") != candidate_id:
            continue
        if state.get("status") == "completed":
            loaded = True
        elif state.get("status") == "error":
            errors.append(str(state.get("error", "Candidate skill load failed")))
    return loaded, errors


def run_single_query(
    query: str,
    skill_path: str,
    description: str,
    timeout: int,
    workspace_root: str,
    model: str | None = None,
    include_skill: bool = True,
) -> dict[str, Any]:
    """Run one isolated query; infrastructure failures are not trigger misses."""
    trial_id = uuid.uuid4().hex
    workspace = Path(workspace_root) / trial_id
    skill_root = workspace / "skills"
    # Keep native skill ID equal to the source directory ID. A synthetic ID
    # changes model-visible context and biases trigger measurements.
    candidate_id = Path(skill_path).name

    started = time.perf_counter()
    try:
        if include_skill:
            source = Path(skill_path)
            _, _, content = parse_skill_md(source)
            candidate = skill_root / candidate_id
            candidate.mkdir(parents=True, exist_ok=False)
            staged = replace_skill_description(content, description)
            (candidate / "SKILL.md").write_text(staged, encoding="utf-8")

        started = time.perf_counter()
        _, events = run_opencode(
            query,
            agent="plan",
            model=model,
            cwd=workspace,
            timeout=timeout,
            config=_eval_config(skill_root, candidate_id, include_skill=include_skill),
            json_output=True,
        )
        duration_seconds = time.perf_counter() - started
        triggered, load_errors = _candidate_tool_calls(events, candidate_id)
        if load_errors:
            return {
                "status": "error",
                "triggered": False,
                "error": "; ".join(load_errors),
                "session_id": next(
                    (event.get("sessionID") for event in events if event.get("sessionID")),
                    None,
                ),
                "requested_model": model,
                "duration_seconds": duration_seconds,
            }
        triggered = include_skill and triggered
        usage = []
        for event in events:
            if event.get("type") != "step_finish":
                continue
            part = event.get("part")
            if isinstance(part, dict) and isinstance(part.get("tokens"), dict):
                usage.append({"tokens": part["tokens"], "cost": part.get("cost")})
        return {
            "status": "triggered" if triggered else "not_triggered",
            "triggered": triggered,
            "session_id": next(
                (event.get("sessionID") for event in events if event.get("sessionID")),
                None,
            ),
            "requested_model": model,
            "duration_seconds": duration_seconds,
            "usage": usage,
        }
    except (OpenCodeRunError, OSError, ValueError) as error:
        return {
            "status": "error",
            "triggered": False,
            "error": str(error),
            "session_id": getattr(error, "session_id", None),
            "requested_model": model,
            "duration_seconds": time.perf_counter() - started,
            "event_types": [
                event.get("type")
                for event in getattr(error, "events", [])
                if isinstance(event, dict)
            ],
        }
    finally:
        shutil.rmtree(workspace, ignore_errors=True)


def run_eval(
    eval_set: list[dict],
    skill_path: Path,
    description: str,
    num_workers: int,
    timeout: int,
    workspace_root: Path,
    runs_per_query: int = 1,
    trigger_threshold: float = 0.5,
    model: str | None = None,
    include_skill: bool = True,
) -> dict:
    """Run all trigger examples; report errors separately from misses."""
    if num_workers < 1 or runs_per_query < 1:
        raise ValueError("num_workers and runs_per_query must be positive")
    if not 0 <= trigger_threshold <= 1:
        raise ValueError("trigger_threshold must be between 0 and 1")
    workspace_root.mkdir(parents=True, exist_ok=True)

    futures = {}
    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        for eval_index, item in enumerate(eval_set):
            query = item.get("query")
            if not isinstance(query, str) or not query.strip():
                raise ValueError(f"eval {eval_index} has an empty or invalid query")
            if not isinstance(item.get("should_trigger"), bool):
                raise ValueError(f"eval {eval_index} must have boolean should_trigger")
            for run_index in range(runs_per_query):
                future = executor.submit(
                    run_single_query,
                    query,
                    str(skill_path),
                    description,
                    timeout,
                    str(workspace_root),
                    model,
                    include_skill,
                )
                futures[future] = (eval_index, run_index)

        outcomes: dict[int, list[dict[str, Any]]] = {
            index: [] for index in range(len(eval_set))
        }
        for future in as_completed(futures):
            eval_index, _ = futures[future]
            try:
                outcome = future.result()
                outcome["run_index"] = futures[future][1]
                outcomes[eval_index].append(outcome)
            except Exception as error:  # worker/process failures are invalid runs
                outcomes[eval_index].append(
                    {
                        "status": "error",
                        "triggered": False,
                        "error": str(error),
                        "run_index": futures[future][1],
                        "requested_model": model,
                    }
                )

    results = []
    passed = failed = errors = 0
    for eval_index, item in enumerate(eval_set):
        runs = outcomes[eval_index]
        valid = [run for run in runs if run["status"] != "error"]
        invalid = [run for run in runs if run["status"] == "error"]
        triggers = sum(bool(run["triggered"]) for run in valid)
        trigger_rate = triggers / len(valid) if valid else None
        did_pass = None
        if trigger_rate is not None:
            did_pass = (
                trigger_rate >= trigger_threshold
                if item["should_trigger"]
                else trigger_rate < trigger_threshold
            )
            passed += int(did_pass)
            failed += int(not did_pass)
        errors += len(invalid)
        results.append(
            {
                "eval_id": item.get("id", eval_index),
                "eval_index": eval_index,
                "query": item["query"],
                "should_trigger": item["should_trigger"],
                "trigger_rate": trigger_rate,
                "triggers": triggers,
                "runs": len(valid),
                "errors": invalid,
                "run_details": runs,
                "pass": did_pass,
            }
        )

    valid_evals = passed + failed
    return {
        "skill_name": skill_path.name,
        "description": description,
        "agent": "plan",
        "model": model,
        "results": results,
        "summary": {
            "total": len(eval_set),
            "valid": valid_evals,
            "passed": passed,
            "failed": failed,
            "errors": errors,
            "pass_rate": passed / valid_evals if valid_evals else None,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate natural OpenCode skill loading")
    parser.add_argument("--eval-set", required=True, help="Path to trigger-eval JSON")
    parser.add_argument("--skill-path", required=True, help="Path to skill directory")
    parser.add_argument("--description", default=None, help="Override description being tested")
    parser.add_argument("--num-workers", type=int, default=4, help="Concurrent fresh sessions")
    parser.add_argument("--timeout", type=int, default=120, help="Deadline per query in seconds")
    parser.add_argument("--runs-per-query", type=int, default=3, help="Fresh sessions per query")
    parser.add_argument("--trigger-threshold", type=float, default=0.5)
    parser.add_argument("--model", default=None, help="OpenCode model reference, optionally with variant")
    parser.add_argument("--workspace", type=Path, default=Path("/tmp/opencode/skill-creator/trigger-evals"))
    parser.add_argument("--without-skill", action="store_true", help="Run negative control without candidate")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text(encoding="utf-8"))
    skill_path = Path(args.skill_path).resolve()
    if not (skill_path / "SKILL.md").is_file():
        parser.error(f"No SKILL.md at {skill_path}")
    _, original_description, _ = parse_skill_md(skill_path)
    description = args.description if args.description is not None else original_description
    output = run_eval(
        eval_set=eval_set,
        skill_path=skill_path,
        description=description,
        num_workers=args.num_workers,
        timeout=args.timeout,
        workspace_root=args.workspace.resolve(),
        runs_per_query=args.runs_per_query,
        trigger_threshold=args.trigger_threshold,
        model=args.model,
        include_skill=not args.without_skill,
    )
    if args.verbose:
        for result in output["results"]:
            print(
                f"[{result['pass'] if result['pass'] is not None else 'ERROR'}] "
                f"{result['triggers']}/{result['runs']} triggered: {result['query'][:80]}",
                file=sys.stderr,
            )
    print(json.dumps(output, indent=2, ensure_ascii=False))
    if output["summary"]["errors"]:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
