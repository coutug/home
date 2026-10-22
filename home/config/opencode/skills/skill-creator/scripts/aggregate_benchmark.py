#!/usr/bin/env python3
"""
Aggregate individual run results into benchmark summary statistics.

Reads grading.json files from run directories and produces:
- run_summary with mean, stddev, min, max for each metric
- delta between with_skill and without_skill configurations

Usage:
    python aggregate_benchmark.py <benchmark_dir>

Example:
    python aggregate_benchmark.py benchmarks/2026-01-15T10-30-00/

The script supports two directory layouts:

    Workspace layout (from skill-creator iterations):
    <benchmark_dir>/
    └── eval-N/
        ├── with_skill/
        │   ├── run-1/grading.json
        │   └── run-2/grading.json
        └── without_skill/
            ├── run-1/grading.json
            └── run-2/grading.json

    Legacy layout (with runs/ subdirectory):
    <benchmark_dir>/
    └── runs/
        └── eval-N/
            ├── with_skill/
            │   └── run-1/grading.json
            └── without_skill/
                └── run-1/grading.json
"""

import argparse
import json
import math
import sys
from numbers import Real
from datetime import datetime, timezone
from pathlib import Path


def calculate_stats(values: list[float]) -> dict:
    """Calculate mean, stddev, min, max for a list of values."""
    if not values:
        return {"mean": None, "stddev": None, "min": None, "max": None}

    n = len(values)
    mean = sum(values) / n

    if n > 1:
        variance = sum((x - mean) ** 2 for x in values) / (n - 1)
        stddev = math.sqrt(variance)
    else:
        stddev = 0.0

    return {
        "mean": round(mean, 4),
        "stddev": round(stddev, 4),
        "min": round(min(values), 4),
        "max": round(max(values), 4)
    }


def _safe_entry(root: Path, path: Path) -> bool:
    return not path.is_symlink() and path.resolve().is_relative_to(root.resolve())


def load_run_results(benchmark_dir: Path) -> dict:
    """
    Load all run results from a benchmark directory.

    Returns dict keyed by config name (e.g. "with_skill"/"without_skill",
    or "new_skill"/"old_skill"), each containing a list of run results.
    """
    # Support both layouts: eval dirs directly under benchmark_dir, or under runs/
    benchmark_dir = benchmark_dir.resolve()
    runs_dir = benchmark_dir / "runs"
    if runs_dir.is_symlink() or (runs_dir.exists() and not _safe_entry(benchmark_dir, runs_dir)):
        raise ValueError(f"Unsafe symlink in benchmark path: {runs_dir}")
    if runs_dir.exists():
        search_dir = runs_dir
    elif list(benchmark_dir.glob("eval-*")):
        search_dir = benchmark_dir
    else:
        print(f"No eval directories found in {benchmark_dir} or {benchmark_dir / 'runs'}")
        return {}

    results: dict[str, list] = {}
    expected_run_numbers: set[int] | None = None
    expected_configs: set[str] | None = None

    for eval_idx, eval_dir in enumerate(sorted(search_dir.glob("eval-*"))):
        if not _safe_entry(benchmark_dir, eval_dir) or not eval_dir.is_dir():
            raise ValueError(f"Unsafe or invalid eval directory: {eval_dir}")
        metadata_path = eval_dir / "eval_metadata.json"
        if metadata_path.is_symlink() or not metadata_path.resolve().is_relative_to(benchmark_dir):
            raise ValueError(f"Unsafe metadata path: {metadata_path}")
        eval_name = eval_dir.name
        if metadata_path.exists():
            try:
                with open(metadata_path) as mf:
                    metadata = json.load(mf)
                eval_id = metadata.get("eval_id", eval_idx)
                eval_name = metadata.get("eval_name", eval_name)
            except (json.JSONDecodeError, OSError):
                eval_id = eval_idx
        else:
            try:
                eval_id = int(eval_dir.name.split("-")[1])
            except ValueError:
                eval_id = eval_idx

        eval_configs: dict[str, set[int]] = {}
        # Discover config directories dynamically rather than hardcoding names
        for config_dir in sorted(eval_dir.iterdir()):
            if config_dir.is_symlink():
                raise ValueError(f"Unsafe symlink in benchmark: {config_dir}")
            if not config_dir.is_dir():
                continue
            run_paths = sorted(config_dir.glob("run-*"))
            if not run_paths:
                continue
            config = config_dir.name
            run_numbers: set[int] = set()
            for run_dir in run_paths:
                if not _safe_entry(benchmark_dir, run_dir) or not run_dir.is_dir():
                    raise ValueError(f"Unsafe or invalid run directory: {run_dir}")
                try:
                    run_numbers.add(int(run_dir.name.split("-")[1]))
                except (IndexError, ValueError) as error:
                    raise ValueError(f"Invalid run directory name: {run_dir}") from error
            eval_configs[config] = run_numbers
            if config not in results:
                results[config] = []

            for run_dir in sorted(config_dir.glob("run-*")):
                run_number = int(run_dir.name.split("-")[1])
                grading_file = run_dir / "grading.json"

                if grading_file.is_symlink() or not grading_file.resolve().is_relative_to(benchmark_dir):
                    raise ValueError(f"Unsafe grading path: {grading_file}")
                if not grading_file.exists():
                    raise ValueError(f"Incomplete benchmark: grading.json not found in {run_dir}")

                try:
                    with open(grading_file) as f:
                        grading = json.load(f)
                except json.JSONDecodeError as e:
                    raise ValueError(f"Invalid grading JSON in {grading_file}: {e}") from e

                summary_data = grading.get("summary") if isinstance(grading, dict) else None
                required_summary = {"pass_rate", "passed", "failed", "total"}
                if not isinstance(summary_data, dict) or not required_summary.issubset(summary_data):
                    raise ValueError(f"Incomplete grading summary in {grading_file}")
                rate = summary_data["pass_rate"]
                counts = [summary_data[key] for key in ("passed", "failed", "total")]
                if (
                    isinstance(rate, bool)
                    or not isinstance(rate, Real)
                    or not 0 <= rate <= 1
                    or any(isinstance(value, bool) or not isinstance(value, int) or value < 0 for value in counts)
                    or summary_data["passed"] + summary_data["failed"] != summary_data["total"]
                    or not isinstance(grading.get("expectations", []), list)
                ):
                    raise ValueError(f"Invalid grading summary in {grading_file}")

                # Extract metrics
                result = {
                    "eval_id": eval_id,
                    "eval_name": eval_name,
                    "run_number": run_number,
                    "pass_rate": grading.get("summary", {}).get("pass_rate", 0.0),
                    "passed": grading.get("summary", {}).get("passed", 0),
                    "failed": grading.get("summary", {}).get("failed", 0),
                    "total": grading.get("summary", {}).get("total", 0),
                }

                # Extract timing — check grading.json first, then sibling timing.json
                timing = grading.get("timing", {})
                result["time_seconds"] = None
                timing_file = run_dir / "timing.json"
                timing_data = {}
                if timing_file.is_symlink() or not timing_file.resolve().is_relative_to(benchmark_dir):
                    raise ValueError(f"Unsafe timing path: {timing_file}")
                if timing_file.exists():
                    try:
                        with open(timing_file) as tf:
                            timing_data = json.load(tf)
                    except json.JSONDecodeError:
                        timing_data = {}
                result["time_seconds"] = timing_data.get("total_duration_seconds")
                if result["time_seconds"] is None:
                    result["time_seconds"] = timing.get(
                        "executor_duration_seconds", timing.get("total_duration_seconds")
                    )
                result["tokens"] = timing_data.get("total_tokens")
                result["session_id"] = timing_data.get("session_id")

                # Extract metrics if available
                metrics = grading.get("execution_metrics", {})
                result["tool_calls"] = metrics.get("total_tool_calls", 0)
                result["output_chars"] = metrics.get("output_chars", 0)
                result["errors"] = metrics.get("errors_encountered", 0)

                # Extract expectations — viewer requires fields: text, passed, evidence
                raw_expectations = grading.get("expectations", [])
                for exp in raw_expectations:
                    if "text" not in exp or "passed" not in exp:
                        print(f"Warning: expectation in {grading_file} missing required fields (text, passed, evidence): {exp}")
                result["expectations"] = raw_expectations

                # Extract notes from user_notes_summary
                notes_summary = grading.get("user_notes_summary", {})
                notes = []
                notes.extend(notes_summary.get("uncertainties", []))
                notes.extend(notes_summary.get("needs_review", []))
                notes.extend(notes_summary.get("workarounds", []))
                result["notes"] = notes

                results[config].append(result)

        if eval_configs:
            names = set(eval_configs)
            if expected_configs is None:
                expected_configs = names
            elif names != expected_configs:
                raise ValueError(f"Incomplete benchmark configurations in {eval_dir}")
            for run_numbers in eval_configs.values():
                if expected_run_numbers is None:
                    expected_run_numbers = run_numbers
                elif run_numbers != expected_run_numbers:
                    raise ValueError(f"Unequal or missing benchmark runs in {eval_dir}")

    return results


def aggregate_results(results: dict) -> dict:
    """
    Aggregate run results into summary statistics.

    Returns run_summary with stats for each configuration and delta.
    """
    run_summary = {}
    configs = list(results.keys())

    for config in configs:
        runs = results.get(config, [])

        if not runs:
            empty_stats = {"mean": None, "stddev": None, "min": None, "max": None}
            run_summary[config] = {
                "pass_rate": empty_stats.copy(),
                "time_seconds": empty_stats.copy(),
                "tokens": empty_stats.copy()
            }
            continue

        pass_rates = [r["pass_rate"] for r in runs if r.get("pass_rate") is not None]
        times = [r["time_seconds"] for r in runs if r.get("time_seconds") is not None]
        tokens = [r["tokens"] for r in runs if r.get("tokens") is not None]

        run_summary[config] = {
            "pass_rate": calculate_stats(pass_rates),
            "time_seconds": calculate_stats(times),
            "tokens": calculate_stats(tokens)
        }

    # Candidate-minus-baseline delta uses semantic roles, not alphabetic order.
    candidate = next((name for name in ("with_skill", "new_skill", "candidate") if name in run_summary), None)
    baseline_name = next((name for name in ("without_skill", "old_skill", "baseline") if name in run_summary), None)
    if candidate and baseline_name:
        primary = run_summary[candidate]
        baseline = run_summary[baseline_name]
    else:
        primary = run_summary.get(configs[0], {}) if configs else {}
        baseline = {}

    def difference(metric: str) -> float | None:
        left = primary.get(metric, {}).get("mean")
        right = baseline.get(metric, {}).get("mean")
        return left - right if left is not None and right is not None else None

    delta_pass_rate = difference("pass_rate")
    delta_time = difference("time_seconds")
    delta_tokens = difference("tokens")

    run_summary["delta"] = {
        "pass_rate": f"{delta_pass_rate:+.2f}" if delta_pass_rate is not None else None,
        "time_seconds": f"{delta_time:+.1f}" if delta_time is not None else None,
        "tokens": f"{delta_tokens:+.0f}" if delta_tokens is not None else None
    }

    return run_summary


def generate_benchmark(benchmark_dir: Path, skill_name: str = "", skill_path: str = "") -> dict:
    """
    Generate complete benchmark.json from run results.
    """
    results = load_run_results(benchmark_dir)
    run_summary = aggregate_results(results)

    # Build runs array for benchmark.json
    runs = []
    for config in results:
        for result in results[config]:
            runs.append({
                "eval_id": result["eval_id"],
                "eval_name": result.get("eval_name"),
                "configuration": config,
                "run_number": result["run_number"],
                "result": {
                    "pass_rate": result["pass_rate"],
                    "passed": result["passed"],
                    "failed": result["failed"],
                    "total": result["total"],
                    "time_seconds": result["time_seconds"],
                    "tokens": result.get("tokens"),
                    "tool_calls": result.get("tool_calls", 0),
                    "errors": result.get("errors", 0),
                    "output_chars": result.get("output_chars", 0),
                    "session_id": result.get("session_id"),
                },
                "expectations": result["expectations"],
                "notes": result["notes"]
            })

    # Determine eval IDs from results
    eval_ids = sorted(set(
        r["eval_id"]
        for config in results.values()
        for r in config
    ))

    benchmark = {
        "metadata": {
            "skill_name": skill_name or "<skill-name>",
            "skill_path": skill_path or "<path/to/skill>",
            "executor_model": "<model-name>",
            "analyzer_model": "<model-name>",
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "evals_run": eval_ids,
            "runs_per_configuration": max(
                (
                    sum(1 for result in values if result["eval_id"] == eval_id)
                    for values in results.values()
                    for eval_id in {result["eval_id"] for result in values}
                ),
                default=0,
            )
        },
        "runs": runs,
        "run_summary": run_summary,
        "notes": []  # To be filled by analyzer
    }

    return benchmark


def generate_markdown(benchmark: dict) -> str:
    """Generate human-readable benchmark.md from benchmark data."""
    metadata = benchmark["metadata"]
    run_summary = benchmark["run_summary"]

    # Determine config names (excluding "delta")
    configs = [k for k in run_summary if k != "delta"]
    config_a = configs[0] if len(configs) >= 1 else "config_a"
    config_b = configs[1] if len(configs) >= 2 else "config_b"
    label_a = config_a.replace("_", " ").title()
    label_b = config_b.replace("_", " ").title()

    lines = [
        f"# Skill Benchmark: {metadata['skill_name']}",
        "",
        f"**Model**: {metadata['executor_model']}",
        f"**Date**: {metadata['timestamp']}",
        f"**Evals**: {', '.join(map(str, metadata['evals_run']))} ({metadata['runs_per_configuration']} runs each per configuration)",
        "",
        "## Summary",
        "",
        f"| Metric | {label_a} | {label_b} | Delta |",
        "|--------|------------|---------------|-------|",
    ]

    a_summary = run_summary.get(config_a, {})
    b_summary = run_summary.get(config_b, {})
    delta = run_summary.get("delta", {})

    # Format pass rate
    a_pr = a_summary.get("pass_rate", {})
    b_pr = b_summary.get("pass_rate", {})
    def stat_text(stats: dict, multiplier: float = 1, suffix: str = "") -> str:
        mean, stddev = stats.get("mean"), stats.get("stddev")
        if mean is None or stddev is None:
            return "N/A"
        return f"{mean * multiplier:.0f}{suffix} ± {stddev * multiplier:.0f}{suffix}"

    lines.append(f"| Pass Rate | {stat_text(a_pr, 100, '%')} | {stat_text(b_pr, 100, '%')} | {delta.get('pass_rate') or '—'} |")

    # Format time
    a_time = a_summary.get("time_seconds", {})
    b_time = b_summary.get("time_seconds", {})
    lines.append(f"| Time | {stat_text(a_time, 1, 's')} | {stat_text(b_time, 1, 's')} | {(delta.get('time_seconds') + 's') if delta.get('time_seconds') is not None else '—'} |")

    # Format tokens
    a_tokens = a_summary.get("tokens", {})
    b_tokens = b_summary.get("tokens", {})
    lines.append(f"| Tokens | {stat_text(a_tokens)} | {stat_text(b_tokens)} | {delta.get('tokens') or '—'} |")

    # Notes section
    if benchmark.get("notes"):
        lines.extend([
            "",
            "## Notes",
            ""
        ])
        for note in benchmark["notes"]:
            lines.append(f"- {note}")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Aggregate benchmark run results into summary statistics"
    )
    parser.add_argument(
        "benchmark_dir",
        type=Path,
        help="Path to the benchmark directory"
    )
    parser.add_argument(
        "--skill-name",
        default="",
        help="Name of the skill being benchmarked"
    )
    parser.add_argument(
        "--skill-path",
        default="",
        help="Path to the skill being benchmarked"
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        help="Output path for benchmark.json (default: <benchmark_dir>/benchmark.json)"
    )

    args = parser.parse_args()

    if not args.benchmark_dir.exists():
        print(f"Directory not found: {args.benchmark_dir}")
        sys.exit(1)

    # Generate benchmark
    benchmark = generate_benchmark(args.benchmark_dir, args.skill_name, args.skill_path)

    # Determine output paths
    output_json = args.output or (args.benchmark_dir / "benchmark.json")
    output_md = output_json.with_suffix(".md")

    # Write benchmark.json
    with open(output_json, "w") as f:
        json.dump(benchmark, f, indent=2)
    print(f"Generated: {output_json}")

    # Write benchmark.md
    markdown = generate_markdown(benchmark)
    with open(output_md, "w") as f:
        f.write(markdown)
    print(f"Generated: {output_md}")

    # Print summary
    run_summary = benchmark["run_summary"]
    configs = [k for k in run_summary if k != "delta"]
    delta = run_summary.get("delta", {})

    print(f"\nSummary:")
    for config in configs:
        pr = run_summary[config]["pass_rate"]["mean"]
        label = config.replace("_", " ").title()
        print(f"  {label}: {pr*100:.1f}% pass rate")
    print(f"  Delta:         {delta.get('pass_rate', '—')}")


if __name__ == "__main__":
    main()
