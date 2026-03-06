#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "pyyaml>=5.0",
#     "tomli>=1.2.0;python_version<'3.11'",
# ]
# ///

"""
Python Package Version Sync Hook - Redesigned

Auto-discovers Python packages from .claude/skills/*/pyproject.toml
and syncs them based on version comparison with installed tools.

Hook Event: SessionStart

Purpose:
    This hook automatically discovers which packages need to be installed
    as uv tools by scanning .claude/skills/ directory. It then compares
    the desired versions (from pyproject.toml) with the actually installed
    versions (via 'uv tool list') and reinstalls if versions mismatch.

How it works:
    Phase 1: Auto-scan - Traverse .claude/skills/*/pyproject.toml
             and extract package names and versions
    Phase 2: Query - Execute 'uv tool list' to get actual installed versions
    Phase 3: Compare - Check if desired version == installed version
    Phase 4: Sync - Reinstall packages that need updates

Exit codes:
    0 - Sync completed (success or no action needed)
    1 - Warnings (errors caught, hook continues)
"""

import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Optional

sys.path.insert(0, str(Path(__file__).parent))
from hook_utils import setup_hook_logging, run_hook_safely

# TOML 解析：試圖使用 tomllib（Python 3.11+），否則 fallback 到 tomli
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib  # type: ignore
    except ImportError:
        tomllib = None  # type: ignore


# ============================================================================
# Constants
# ============================================================================

SKILLS_DIR_NAME = ".claude/skills"
PYPROJECT_FILENAME = "pyproject.toml"


def get_project_root() -> Path:
    """Get project root from CLAUDE_PROJECT_DIR or infer from hook location."""
    if "CLAUDE_PROJECT_DIR" in os.environ:
        return Path(os.environ["CLAUDE_PROJECT_DIR"])

    # Fallback: infer from hook location (.claude/hooks/xxx.py)
    hook_dir = Path(__file__).parent
    return hook_dir.parent.parent


def scan_skill_packages(project_root: Path) -> Dict[str, Dict[str, str]]:
    """Scan .claude/skills/*/pyproject.toml and extract package info.

    Traverses the skills directory and parses each pyproject.toml to extract
    the [project] name and version fields. Returns a dict mapping package names
    to their metadata.

    Args:
        project_root: Root directory of the project.

    Returns:
        Dict mapping package name → {"path": relative_path, "version": version_str}.
        Returns empty dict if skills directory doesn't exist or no valid packages found.

    Example:
        {
            "ticket-system": {
                "path": ".claude/skills/ticket",
                "version": "1.0.0"
            },
            "mermaid-ascii": {
                "path": ".claude/skills/mermaid-ascii",
                "version": "0.5.0"
            }
        }
    """
    packages: Dict[str, Dict[str, str]] = {}
    skills_dir = project_root / SKILLS_DIR_NAME

    if not skills_dir.exists():
        return packages

    try:
        for skill_dir in skills_dir.iterdir():
            if not skill_dir.is_dir():
                continue

            pyproject_path = skill_dir / PYPROJECT_FILENAME
            if not pyproject_path.exists():
                continue

            try:
                pyproject_data = _load_pyproject_toml(pyproject_path)
                if not pyproject_data:
                    continue

                project_info = pyproject_data.get("project", {})
                pkg_name = project_info.get("name", "")
                version = project_info.get("version", "")

                if pkg_name and version:
                    packages[pkg_name] = {
                        "path": str(skill_dir.relative_to(project_root)),
                        "version": version,
                    }
            except Exception as e:
                # Log warning but continue scanning other skills
                logger = setup_hook_logging("package-version-sync-hook")
                logger.warning(f"Failed to parse {pyproject_path}: {e}")
                continue
    except Exception:
        # If iterating skills_dir fails, return what we have
        pass

    return packages


def _load_pyproject_toml(pyproject_path: Path) -> Optional[Dict]:
    """Load and parse a pyproject.toml file.

    Attempts to use tomllib (Python 3.11+) or tomli fallback (Python 3.9-3.10).
    Returns None if the file cannot be parsed.

    Args:
        pyproject_path: Path to the pyproject.toml file.

    Returns:
        Parsed TOML dict, or None if parsing fails.
    """
    if tomllib is None:
        return None

    try:
        with open(pyproject_path, "rb") as f:
            return tomllib.load(f)
    except Exception:
        return None


def get_installed_uv_tools() -> Dict[str, str]:
    """Query 'uv tool list' and extract installed package versions.

    Executes 'uv tool list' and parses the output to extract tool names
    and their versions. Returns a dict mapping tool names to versions.

    Returns:
        Dict mapping tool name → version string.
        Returns empty dict if 'uv tool list' fails.

    Example output format:
        Tool Name      Version  Executable Location
        ─────────────  ───────  ──────────────────────────
        ticket-system  1.0.0    ~/.venv/bin/ticket
        mermaid-ascii  0.5.0    ~/.venv/bin/mermaid
    """
    tools: Dict[str, str] = {}

    try:
        result = subprocess.run(
            ["uv", "tool", "list"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            return tools

        # Parse output lines: skip headers and empty lines
        for line in result.stdout.splitlines():
            # Skip separator lines and empty lines
            if not line.strip() or "─" in line or "─" in line:
                continue
            # Skip header line
            if "Tool Name" in line or "Version" in line:
                continue

            parts = line.split()
            if len(parts) >= 2:
                tool_name = parts[0]
                version_str = parts[1]
                # Normalize version: remove 'v' prefix if present
                version_str = version_str.lstrip("v")
                tools[tool_name] = version_str

        return tools
    except Exception:
        return tools


def should_reinstall(desired_version: str, installed_version: Optional[str]) -> bool:
    """Check if a package needs to be reinstalled based on version mismatch.

    Compares desired version (from pyproject.toml) with installed version
    (from uv tool list). Returns True if:
    - Package is not installed (installed_version is None)
    - Versions don't match (string comparison, not semantic versioning)

    Args:
        desired_version: Version string from pyproject.toml (e.g. "1.0.0")
        installed_version: Version string from 'uv tool list' or None if not installed

    Returns:
        True if package needs reinstallation, False if versions match.
    """
    if installed_version is None:
        return True  # Not installed, need to install
    return desired_version != installed_version  # Mismatch, need to reinstall


def reinstall_uv_tool(package_name: str, package_full_path: Path) -> bool:
    """Reinstall a uv tool: uninstall → cache clean → install --reinstall.

    Avoids the uv cache trap where stale wheels are reused.

    Args:
        package_name: Name of the package (e.g. 'ticket-system')
        package_full_path: Absolute path to the package directory

    Returns:
        True if reinstall succeeded, False otherwise.
    """
    try:
        # Step 1: uninstall (ignore errors if not installed)
        subprocess.run(
            ["uv", "tool", "uninstall", package_name],
            capture_output=True,
            text=True,
            timeout=30,
        )

        # Step 2: cache clean (ignore errors)
        subprocess.run(
            ["uv", "cache", "clean", package_name],
            capture_output=True,
            text=True,
            timeout=30,
        )

        # Step 3: install --reinstall
        result = subprocess.run(
            ["uv", "tool", "install", ".", "--reinstall"],
            cwd=str(package_full_path),
            capture_output=True,
            text=True,
            timeout=120,
        )

        # Verify: "Building" in output confirms wheel was rebuilt
        combined_output = (result.stdout or "") + (result.stderr or "")
        if result.returncode == 0 and "Building" in combined_output:
            return True
        # returncode 0 but no "Building" means cache was used
        return result.returncode == 0
    except Exception:
        return False


def main() -> int:
    """Main hook entry point.

    Phase 1: Auto-scan .claude/skills/*/pyproject.toml
    Phase 2: Query 'uv tool list' for installed versions
    Phase 3: Compare desired vs installed versions
    Phase 4: Reinstall packages that need updates

    Returns:
        0 if successful or no action needed
        1 if errors occurred (but hook continues)
    """
    logger = setup_hook_logging("package-version-sync-hook")
    project_root = get_project_root()

    # Phase 1: Auto-scan skill packages
    packages = scan_skill_packages(project_root)

    if not packages:
        print("Package Version Sync - No packages found in .claude/skills/")
        return 0

    # Print header
    print("=" * 60)
    print("Package Version Sync - Session Startup Check")
    print("=" * 60)

    # Phase 2: Query installed tools
    installed_tools = get_installed_uv_tools()

    # Phase 3 & 4: Compare and reinstall
    for package_name, package_info in packages.items():
        package_path = package_info.get("path", "")
        desired_version = package_info.get("version", "")

        if not package_path or not desired_version:
            print(f"{package_name}: Invalid package metadata")
            continue

        package_full_path = project_root / package_path

        if not package_full_path.exists():
            print(f"{package_name}: Package directory not found")
            continue

        installed_version = installed_tools.get(package_name)

        # Display version status
        version_display = installed_version or "not installed"
        print(
            f"{package_name}: desired={desired_version}, "
            f"installed={version_display}"
        )

        # Check if reinstall is needed
        if not should_reinstall(desired_version, installed_version):
            print(f"  Status: up to date")
            continue

        # Reinstall
        print(f"  Status: installing...")
        if reinstall_uv_tool(package_name, package_full_path):
            print(f"  Result: reinstalled")
        else:
            print(f"  Result: failed", file=sys.stderr)

    print("=" * 60)
    return 0


if __name__ == "__main__":
    sys.exit(run_hook_safely(main, "package-version-sync-hook"))
