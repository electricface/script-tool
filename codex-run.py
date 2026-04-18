#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 UnionTech Software Technology Co., Ltd.
#
# SPDX-License-Identifier: MIT

"""codex-run: Manage codex model_provider and run codex with auth env."""

import argparse
import json
import os
import re
import shutil
import sys
import tomllib
from pathlib import Path

HOME = Path.home()
CODEX_CONFIG = HOME / ".codex" / "config.toml"
RUN_CONFIG_DIR = HOME / ".config" / "codex-run"
AUTH_CONFIG = RUN_CONFIG_DIR / "auth.json"


def load_codex_config():
    """Load and parse ~/.codex/config.toml."""
    if not CODEX_CONFIG.exists():
        print(f"Error: {CODEX_CONFIG} not found", file=sys.stderr)
        sys.exit(1)
    with open(CODEX_CONFIG, "rb") as f:
        return tomllib.load(f)


def get_current_provider(config=None):
    """Get the current model_provider from config.toml."""
    if config is None:
        config = load_codex_config()
    return config.get("model_provider", "")


def get_providers(config=None):
    """Get list of model_provider names from config.toml."""
    if config is None:
        config = load_codex_config()
    providers_section = config.get("model_providers", {})
    return list(providers_section.keys())


def cmd_list():
    """List all available model providers."""
    config = load_codex_config()
    current = get_current_provider(config)
    providers = get_providers(config)
    for name in providers:
        if name == current:
            print(f"* {name} (current)")
        else:
            print(f"  {name}")


def cmd_use(provider):
    """Switch to the specified model provider."""
    config = load_codex_config()
    providers = get_providers(config)
    if provider not in providers:
        print(f"Error: provider '{provider}' not found. Available: {', '.join(providers)}", file=sys.stderr)
        sys.exit(1)

    # Update model_provider in ~/.codex/config.toml (regex replace to preserve formatting)
    toml_text = CODEX_CONFIG.read_text()
    new_text, count = re.subn(
        r'^(model_provider\s*=\s*)"[^"]*"',
        rf'\1"{provider}"',
        toml_text,
        count=1,
        flags=re.MULTILINE,
    )
    if count == 0:
        print(f"Error: failed to update model_provider in {CODEX_CONFIG}", file=sys.stderr)
        sys.exit(1)
    CODEX_CONFIG.write_text(new_text)

    print(f"Switched to '{provider}'")


def get_env_provider():
    """Get the current model_provider from config.toml."""
    return get_current_provider()


def run_codex(extra_args):
    """Run codex with auth environment variables."""
    provider = get_env_provider()
    if not provider:
        print("Error: no model_provider configured", file=sys.stderr)
        sys.exit(1)

    # Load auth config
    if not AUTH_CONFIG.exists():
        print(f"Error: {AUTH_CONFIG} not found", file=sys.stderr)
        sys.exit(1)
    auth = json.loads(AUTH_CONFIG.read_text())

    # Build env key: provider -> PROVIDER_API_KEY
    env_key = f"{provider}_API_KEY"
    env_value = auth.get(env_key, "")
    if not env_value:
        print(f"Error: {env_key} not found in {AUTH_CONFIG}", file=sys.stderr)
        sys.exit(1)

    os.environ[env_key] = env_value
    print(f"{env_key} (length: {len(env_value)})")

    # Find codex binary
    codex_bin = shutil.which("codex")
    if not codex_bin:
        print("Error: 'codex' command not found in PATH", file=sys.stderr)
        sys.exit(1)

    os.execvp(codex_bin, ["codex"] + extra_args)


def main():
    parser = argparse.ArgumentParser(
        prog="codex-run",
        description="Manage codex model_provider and run codex with auth env",
    )
    parser.add_argument("-l", "--list", action="store_true", help="List all available model providers")
    parser.add_argument("-u", "--use", metavar="PROVIDER", help="Switch to the specified model provider")
    args, remainder = parser.parse_known_args()

    # Strip leading '--' from remainder (argparse keeps it)
    if remainder and remainder[0] == "--":
        remainder = remainder[1:]

    if args.list:
        cmd_list()
    elif args.use:
        cmd_use(args.use)
    else:
        run_codex(remainder)


if __name__ == "__main__":
    main()
