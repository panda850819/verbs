#!/usr/bin/env python3
"""Classify a Bash hook payload against the Verbs ticket-gate policy."""

import json
import os
import shlex
import subprocess
import sys
from pathlib import Path


DEFAULT_BRANCHES = {"main", "master"}
SIMPLE_WRAPPERS = {"command", "builtin", "exec", "nohup", "time"}
GIT_OPTIONS_WITH_VALUE = {
    "-C", "-c", "--git-dir", "--work-tree", "--namespace", "--config-env",
}
PUSH_OPTIONS_WITH_VALUE = {
    "--repo", "--receive-pack", "--exec", "-o", "--push-option",
}


def _result(decision, reason, detail="", artifact=""):
    fields = (decision, reason, detail, artifact)
    print("\t".join(str(field).replace("\t", " ").replace("\n", " ") for field in fields))


def _stream(command):
    """Yield ('cmd', tokens) and ('punct', token) items in shell order."""
    lexer = shlex.shlex(
        command.replace("\n", " ; "),
        posix=True,
        punctuation_chars=";&|()`",
    )
    lexer.whitespace_split = True
    lexer.commenters = ""
    current = []
    for token in lexer:
        if token and set(token) <= set(";&|()`"):
            if current:
                yield "cmd", current
                current = []
            yield "punct", token
        else:
            current.append(token)
    if current:
        yield "cmd", current


def _punct_runs(token):
    """Split a punctuation token into operator runs: ');&&' -> [')', ';', '&&']."""
    runs = []
    for char in token:
        if runs and runs[-1][0] == char and char in "&|":
            runs[-1] += char
        else:
            runs.append(char)
    return runs


def _git_start(tokens):
    index = 0
    while index < len(tokens):
        token = tokens[index]
        base = token.rsplit("/", 1)[-1]
        if "=" in token and not token.startswith("-"):
            index += 1
            continue
        if base == "git":
            return index
        if base in SIMPLE_WRAPPERS:
            index += 1
            while index < len(tokens) and tokens[index].startswith("-"):
                index += 1
            continue
        if base == "env":
            index += 1
            while index < len(tokens):
                env_token = tokens[index]
                env_option = env_token.split("=", 1)[0]
                if env_option in {"-u", "--unset", "-C", "--chdir", "-S", "--split-string"}:
                    index += 2 if "=" not in env_token else 1
                elif env_token.startswith("-") or "=" in env_token:
                    index += 1
                else:
                    break
            continue
        if base == "nice":
            index += 1
            if index < len(tokens) and tokens[index] in {"-n", "--adjustment"}:
                index += 2
            elif index < len(tokens) and tokens[index].startswith("-n"):
                index += 1
            elif index < len(tokens) and tokens[index].startswith("--adjustment="):
                index += 1
            continue
        if base == "stdbuf":
            index += 1
            while index < len(tokens) and tokens[index].startswith("-"):
                option = tokens[index]
                index += 1
                if option in {"-i", "-o", "-e"}:
                    index += 1
            continue
        if base == "timeout":
            index += 1
            while index < len(tokens) and tokens[index].startswith("-"):
                index += 1
            if index < len(tokens):
                index += 1
            continue
        if base in {"sudo", "doas"}:
            index += 1
            while index < len(tokens) and tokens[index].startswith("-"):
                option = tokens[index]
                index += 1
                if option in {"-u", "-g", "-h", "-p", "-C", "-R", "-T"}:
                    index += 1
            continue
        return None
    return None


# Targets holding runtime shell expansions the guard cannot resolve statically.
_UNSAFE_TARGET_CHARS = set("$*?[{")


def _after_dir_change(base, tokens, current, oldpwd, stack, fallback):
    """(current, oldpwd, pushd_stack) after a cd/pushd/popd, modeling bash.

    Anything the guard cannot resolve statically falls back to the session
    cwd — the pre-tracking behavior — so tracking never weakens the gate.
    A cd to a nonexistent directory fails in the shell and keeps the current
    directory, so it does here too.
    """
    stack = list(stack)
    if base == "popd":
        return (stack.pop() if stack else fallback), current, stack
    args = [t for t in tokens[1:] if t == "-" or not t.startswith("-")]
    if not args:
        if base == "pushd":
            if stack:
                top = stack.pop()
                stack.append(current)
                return top, current, stack
            return fallback, current, stack
        return Path(os.path.expanduser("~")), current, stack
    if len(args) > 1:
        new = fallback  # two-arg cd is shell-dependent (zsh substitutes)
    else:
        target = args[0]
        if target == "-":
            new = oldpwd
        elif set(target) & _UNSAFE_TARGET_CHARS:
            new = fallback
        else:
            candidate = Path(os.path.expanduser(target))
            if not candidate.is_absolute():
                candidate = current / candidate
            new = candidate if candidate.is_dir() else current
    if base == "pushd":
        stack.append(current)
    return new, current, stack


def _parse_git(tokens, current_dir):
    git_index = _git_start(tokens)
    if git_index is None:
        return None
    repo_dir = current_dir
    index = git_index + 1
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            index += 1
            break
        option = token.split("=", 1)[0]
        if option == "-C":
            if "=" in token:
                value = token.split("=", 1)[1]
            elif index + 1 < len(tokens):
                index += 1
                value = tokens[index]
            else:
                return None
            candidate = Path(os.path.expanduser(value))
            repo_dir = candidate if candidate.is_absolute() else repo_dir / candidate
            index += 1
            continue
        if option in GIT_OPTIONS_WITH_VALUE:
            if "=" not in token:
                index += 1
            index += 1
            continue
        if token.startswith("-"):
            index += 1
            continue
        break
    if index >= len(tokens):
        return None
    return tokens[index], tokens[index + 1 :], repo_dir.resolve()


def _git(repo_dir, *args):
    return subprocess.run(
        ["git", "-C", str(repo_dir), *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )


def _repo_state(repo_dir):
    top = _git(repo_dir, "rev-parse", "--show-toplevel")
    if top.returncode != 0:
        return None, None, False
    top_path = Path(top.stdout.strip())
    branch = _git(repo_dir, "symbolic-ref", "--short", "-q", "HEAD")
    branch_name = branch.stdout.strip() if branch.returncode == 0 else None
    return top_path, branch_name, (top_path / ".verbs-ticket-gate-off").is_file()


def _push_args(args):
    positionals = []
    flags = set()
    index = 0
    while index < len(args):
        token = args[index]
        if token == "--":
            positionals.extend(args[index + 1 :])
            break
        option = token.split("=", 1)[0]
        if token.startswith("-"):
            flags.add(option)
            if option in PUSH_OPTIONS_WITH_VALUE and "=" not in token:
                index += 1
            index += 1
            continue
        positionals.append(token)
        index += 1
    remote = positionals[0] if positionals else None
    return remote, positionals[1:], flags


def _targets_default(refspec):
    refspec = refspec.lstrip("+")
    target = refspec.rsplit(":", 1)[-1]
    if target.startswith("refs/heads/"):
        target = target[len("refs/heads/") :]
    return target in DEFAULT_BRANCHES


def classify(payload):
    if not isinstance(payload, dict) or payload.get("tool_name") != "Bash":
        return "allow", "not_bash", "", ""
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict) or not isinstance(tool_input.get("command"), str):
        raise ValueError("Bash payload requires tool_input.command")
    command = tool_input["command"]
    cwd = payload.get("cwd") or payload.get("workdir") or os.getcwd()
    if not isinstance(cwd, str):
        cwd = os.getcwd()

    fallback = Path(cwd)
    current, oldpwd, pushd_stack = fallback, fallback, []
    scopes = []  # saved dir state at each '(' or opening backtick
    backtick_open = False
    pending = None  # dir state from a cd, applied only if the separator keeps it

    for kind, item in _stream(command):
        if kind == "punct":
            for run in _punct_runs(item):
                if run == "(":
                    if pending is not None:
                        current, oldpwd, pushd_stack = pending
                        pending = None
                    scopes.append((current, oldpwd, list(pushd_stack)))
                elif run == ")" or run == "`":
                    if run == "`" and not backtick_open:
                        backtick_open = True
                        scopes.append((current, oldpwd, list(pushd_stack)))
                        pending = None
                        continue
                    if run == "`":
                        backtick_open = False
                    if scopes:
                        current, oldpwd, pushd_stack = scopes.pop()
                    else:
                        current, oldpwd, pushd_stack = fallback, fallback, []
                    pending = None
                elif run in {"|", "&"}:
                    pending = None  # pipeline / background: the cd ran in a subshell
                else:  # ';', '&&', '||'
                    if pending is not None:
                        current, oldpwd, pushd_stack = pending
                        pending = None
            continue
        tokens = item
        base = tokens[0].rsplit("/", 1)[-1]
        if base in {"cd", "pushd", "popd"}:
            pending = _after_dir_change(
                base, tokens, current, oldpwd, pushd_stack, fallback
            )
            continue
        parsed = _parse_git(tokens, current)
        if parsed is None:
            continue
        subcommand, args, repo_dir = parsed
        if subcommand not in {"commit", "push"}:
            continue
        top, branch, opted_out = _repo_state(repo_dir)
        if top is None or opted_out:
            continue
        artifact = str(top)
        if subcommand == "commit" and branch in DEFAULT_BRANCHES:
            return (
                "deny", "commit_default_branch",
                "git commit on default branch '{}'".format(branch), artifact,
            )
        if subcommand != "push":
            continue

        _remote, refspecs, flags = _push_args(args)
        if "--all" in flags or "--mirror" in flags:
            return (
                "deny", "push_all_branches",
                "git push may update the default branch", artifact,
            )
        if any(_targets_default(refspec) for refspec in refspecs):
            return (
                "deny", "push_default_branch",
                "git push targeting the default branch", artifact,
            )
        selector_flags = {"--tags", "--all", "--mirror", "--delete"}
        implicit_push = not refspecs and not (flags & selector_flags)
        if implicit_push and branch in DEFAULT_BRANCHES:
            return (
                "deny", "bare_push_default_branch",
                "bare git push while on default branch '{}'".format(branch),
                artifact,
            )
    return "allow", "no_policy_match", "", ""


def main():
    try:
        payload = json.load(sys.stdin)
        _result(*classify(payload))
        return 0
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
