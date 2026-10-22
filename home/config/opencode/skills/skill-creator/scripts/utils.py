"""Shared, deterministic helpers for skill-creator scripts."""

import re
from pathlib import Path

import yaml


def _frontmatter(content: str) -> tuple[dict, re.Match[str]]:
    match = re.match(r"\A---\s*\n(.*?)\n---(\s*\n|\Z)", content, re.DOTALL)
    if not match:
        raise ValueError("SKILL.md is missing valid YAML frontmatter")
    parsed = yaml.safe_load(match.group(1))
    if not isinstance(parsed, dict):
        raise ValueError("SKILL.md frontmatter must be a YAML mapping")
    return parsed, match


def parse_skill_md(skill_path: Path) -> tuple[str, str, str]:
    """Parse SKILL.md; return display name, description, and full content."""
    content = (skill_path / "SKILL.md").read_text(encoding="utf-8")
    frontmatter, _ = _frontmatter(content)
    name = frontmatter.get("name", skill_path.name)
    description = frontmatter.get("description", "")
    if not isinstance(name, str) or not isinstance(description, str):
        raise ValueError("SKILL.md name and description must be strings")
    return name, description, content


def replace_skill_description(content: str, description: str) -> str:
    """Replace frontmatter description while preserving the skill body."""
    frontmatter, match = _frontmatter(content)
    frontmatter["description"] = description
    encoded = yaml.safe_dump(frontmatter, allow_unicode=True, sort_keys=False).rstrip()
    return f"---\n{encoded}\n---{match.group(2)}{content[match.end():]}"
