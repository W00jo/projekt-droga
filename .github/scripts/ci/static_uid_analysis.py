#!/usr/bin/env python3
import os
import re
import sys
import subprocess
import logging
from pathlib import Path

# Allow the caller to override verbosity via the LOG_LEVEL environment variable
log_level_env = os.getenv("LOG_LEVEL", "INFO").upper()
# Fall back to INFO gracefully if the supplied value is not a recognised log level
log_level = getattr(logging, log_level_env, logging.INFO)

logging.basicConfig(level=log_level, format="[%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# Regex patterns for extracting UID and path declarations from Godot text files
UID_PATTERN = re.compile(r'uid="(uid://[a-zA-Z0-9]+)"')
EXT_RESOURCE_PATTERN = re.compile(r"\[ext_resource[^\]]+\]")
PATH_PATTERN = re.compile(r'path="(res://[^"]+)"')

# Asset extensions that the Godot engine automatically imports,
# generating a companion .import configuration file on first encounter
IMPORTABLE_EXTENSIONS = {
    # Images
    ".png", ".jpg", ".jpeg", ".webp", ".bmp", ".svg",
    ".tga", ".dds", ".ktx", ".exr", ".hdr",
    # 3D models
    ".gltf", ".glb", ".obj", ".dae", ".fbx",
    # Audio
    ".wav", ".ogg", ".mp3",
    # Data and translations
    ".csv", ".po",
}
# Matches the top-level [gd_scene] or [gd_resource] header to extract the file's own UID
HEADER_PATTERN = re.compile(
    r'\[gd_(?:scene|resource).*?uid="(uid://[a-zA-Z0-9]+)".*?\]'
)


def get_fallback_files() -> list[str]:
    """
    Walks the filesystem manually when Git is unavailable, skipping
    build artefacts and editor-generated directories.
    """
    ignore_dirs = {".git", ".godot", ".vs", "bin", "obj", "export"}
    all_files = []
    logger.info("Executing fallback os.walk traversal...")
    for root, dirs, files in os.walk("."):
        dirs[:] = [d for d in dirs if d not in ignore_dirs]
        for f in files:
            all_files.append(os.path.normpath(os.path.join(root, f)))
    return all_files


def get_git_files() -> list[str]:
    """
    Returns every file visible to Git (tracked + untracked), automatically
    excluding anything covered by .gitignore. Falls back to os.walk if
    the Git executable is missing or the repository is inaccessible.
    """
    try:
        result = subprocess.run(
            ["git", "ls-files", "-c", "-o", "--exclude-standard"],
            capture_output=True,
            text=True,
            check=True,
        )
        return [line for line in result.stdout.split("\n") if line.strip()]
    except (subprocess.CalledProcessError, FileNotFoundError):
        logger.warning(
            "Git executable not found or repository unavailable. Defaulting to fallback tree traversal."
        )
        return get_fallback_files()


def to_res_path(os_filepath: str) -> str:
    """
    Converts a native OS path into the canonical Godot res:// format
    used throughout scene and resource files.
    """
    if os_filepath.startswith("res://"):
        return os_filepath
    normalized = os_filepath.replace("\\", "/")
    if normalized.startswith("./"):
        normalized = normalized[2:]
    return f"res://{normalized}"


def to_os_path(res_path: str) -> str:
    """
    Converts a Godot res:// path back into a native OS path so that
    we can verify physical file existence on disk.
    """
    if res_path.startswith("res://"):
        stripped = res_path[6:]
    else:
        stripped = res_path
    return os.path.normpath(stripped)


def register_uid(
    found_uid: str,
    logical_asset_path: str,
    declared_by_uid: dict[str, str],
    declared_by_path: dict[str, str],
) -> int:
    """
    Records a UID-to-path binding and checks for collisions.
    Returns 1 if the UID is already claimed by a different file, 0 otherwise.
    """
    if (
        found_uid in declared_by_uid
        and declared_by_uid[found_uid] != logical_asset_path
    ):
        logger.error(
            f"Duplicated UID declaration: '{found_uid}' in both '{declared_by_uid[found_uid]}' and '{logical_asset_path}'"
        )
        return 1
    declared_by_uid[found_uid] = logical_asset_path
    declared_by_path[logical_asset_path] = found_uid
    return 0


def main() -> int:
    if not os.path.exists("project.godot"):
        logger.error(
            "project.godot not found. Script must be executed from the Godot project root."
        )
        return 1

    logger.info("Initialising Godot UID referential integrity check...")

    files = get_git_files()
    # Only these text-based file types can contain UID declarations or references
    text_extensions = {".tscn", ".tres", ".import", ".gd", ".cs"}

    # Two-way lookup tables: UID -> canonical res:// path and vice versa
    declared_by_uid: dict[str, str] = {}
    declared_by_path: dict[str, str] = {}

    # Collected outward references that each file declares via [ext_resource]
    references: list[tuple[str, str, str]] = []
    errors_found = 0

    # Phase 0 — Unaccompanied Asset Check
    # Catches the scenario where a contributor commits a raw asset (PNG, OGG, etc.)
    # without running the Godot engine to generate its .import companion
    all_files_set = set(files)
    importable_assets = [
        f for f in files if Path(f).suffix.lower() in IMPORTABLE_EXTENSIONS
    ]
    logger.info(
        f"Scanning {len(importable_assets)} importable assets for missing .import companions..."
    )

    for asset_path in importable_assets:
        import_companion = asset_path + ".import"
        if import_companion not in all_files_set:
            logger.error(
                f"Unaccompanied asset: '{to_res_path(asset_path)}' was committed without a corresponding .import file"
            )
            errors_found += 1

    filtered_files = [f for f in files if Path(f).suffix in text_extensions]
    logger.info(f"Scanning {len(filtered_files)} relevant text files...")

    for filepath in filtered_files:
        if not os.path.isfile(filepath):
            continue

        path_obj = Path(filepath)

        # Phase 1 — Orphan Import Check
        # The inverse of Phase 0: detects .import files whose source asset has been
        # deleted or was never committed
        if path_obj.suffix == ".import":
            physical_asset_path = filepath[:-7]  # Strip '.import'
            if not os.path.exists(physical_asset_path):
                logger.error(
                    f"Orphaned metadata: Import file without corresponding asset: '{filepath}'"
                )
                errors_found += 1
                continue
        else:
            physical_asset_path = filepath

        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
        except UnicodeDecodeError:
            logger.warning(f"Unrecognised encoding in file: '{filepath}' - skipping.")
            continue

        # Convert the OS path to a res:// path for consistent dictionary lookups
        logical_asset_path = to_res_path(physical_asset_path)

        # Phase 2a — Record the UID that each scene or resource declares for itself
        if path_obj.suffix in {".tscn", ".tres"}:
            header_match = HEADER_PATTERN.search(content)
            if header_match:
                errors_found += register_uid(
                    header_match.group(1),
                    logical_asset_path,
                    declared_by_uid,
                    declared_by_path,
                )

        elif path_obj.suffix == ".import":
            uid_match = UID_PATTERN.search(content)
            if uid_match:
                errors_found += register_uid(
                    uid_match.group(1),
                    logical_asset_path,
                    declared_by_uid,
                    declared_by_path,
                )

        # Phase 2b — Collect every [ext_resource] reference so we can cross-check
        # that the UID and path in each reference agree with their source of truth
        current_res_path = to_res_path(filepath)
        for ext_match in EXT_RESOURCE_PATTERN.finditer(content):
            ext_line = ext_match.group(0)
            uid_param = UID_PATTERN.search(ext_line)
            path_param = PATH_PATTERN.search(ext_line)

            if uid_param and path_param:
                references.append(
                    (current_res_path, uid_param.group(1), path_param.group(1))
                )

    logger.info(
        f"Parsing complete. Registered {len(declared_by_uid)} explicit UID declarations and {len(references)} external references."
    )
    logger.info("Validating referential dependencies...")

    # Phase 3 — Cross-reference validation
    # For each outward dependency, verify that the UID and the path point to the
    # same file and that the referenced file actually exists on disk
    for source_res, ref_uid, ref_res in references:
        physical_ref_path = to_os_path(ref_res)

        if not os.path.exists(physical_ref_path):
            logger.error(
                f"Target path breach in '{source_res}': The referenced file '{ref_res}' does not exist on disk."
            )
            errors_found += 1
            continue

        expected_res = declared_by_uid.get(ref_uid)
        expected_uid = declared_by_path.get(ref_res)

        if expected_res and expected_res != ref_res:
            logger.error(
                f"UID resolution drift in '{source_res}': Expects '{ref_uid}' to point to '{ref_res}', but the UID is formally registered to '{expected_res}'."
            )
            errors_found += 1
            continue

        if expected_uid and expected_uid != ref_uid:
            logger.error(
                f"Metadata assignment drift in '{source_res}': Path '{ref_res}' is referenced using '{ref_uid}', but formally declares '{expected_uid}'."
            )
            errors_found += 1
            continue

    if errors_found > 0:
        logger.error(
            f"Validation failed. Identified {errors_found} referential integrity defect(s)."
        )
        return 1

    logger.info("Validation successful. Zero referential defects detected.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
