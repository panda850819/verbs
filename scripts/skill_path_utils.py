#!/usr/bin/env python3
"""Shared containment checks for skill-local runtime references."""

import os


def skill_local_path(skill_dir, value):
    """Resolve one skill-local path without allowing traversal or symlinks."""
    if os.path.isabs(value) or ".." in value.replace("\\", "/").split("/"):
        return None
    skill_dir = os.path.abspath(skill_dir)
    if os.path.islink(skill_dir):
        return None
    candidate = os.path.abspath(os.path.normpath(os.path.join(skill_dir, value)))
    real_skill_dir = os.path.realpath(skill_dir)
    try:
        if os.path.commonpath((skill_dir, candidate)) != skill_dir:
            return None
        if os.path.commonpath(
            (real_skill_dir, os.path.realpath(candidate))
        ) != real_skill_dir:
            return None
    except ValueError:
        return None
    current = skill_dir
    for part in os.path.relpath(candidate, skill_dir).split(os.sep):
        current = os.path.join(current, part)
        if os.path.islink(current):
            return None
    return candidate
