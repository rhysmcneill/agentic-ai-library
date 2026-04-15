#!/usr/bin/env bash
# script: setup.sh
# description: Set up AI agent configuration in a target repository.
#              Creates local symlinks only — never commits or pushes.
#              Supports multiple groups per repo (e.g., --group backend --group infra).
#              Run once per repo. Updates propagate automatically via symlinks
#              when the library is pulled.

set -euo pipefail

# Colors (disabled if stdout is not a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    RESET='\033[0m'
    CHECK="${GREEN}✔${RESET}"
    CROSS="${RED}✘${RESET}"
    ARROW="${CYAN}→${RESET}"
else
    RED='' GREEN='' YELLOW='' CYAN='' BOLD='' DIM='' RESET=''
    CHECK='✔' CROSS='✘' ARROW='→'
fi

info()  { echo -e "  ${DIM}$1${RESET}"; }
step()  { echo -e "  ${CHECK}  $1"; }
err()   { echo -e "  ${CROSS}  ${RED}$1${RESET}" >&2; }

VALID_IDES="claude, cursor, windsurf"

usage() {
    cat << EOF
${BOLD}Usage:${RESET} $0 [OPTIONS]

Set up AI agent configuration in a target repository.

${BOLD}Options:${RESET}
  -t, --target <path>   Target repository path (required)
  -g, --group <name>    Group name in the config library (repeatable, at least one required)
  --ide <name>          IDE integration (repeatable). Valid: ${VALID_IDES}
  -h, --help            Show this help message

${BOLD}Tools that work without --ide:${RESET}
  Codex, Antigravity, GitHub Copilot — these read AGENTS.md natively.

${BOLD}Examples:${RESET}
  # Single group (works for Codex, Antigravity, Copilot out of the box)
  $0 --target ../my-repo --group infrastructure

  # With Claude Code and Cursor support
  $0 --target ../my-repo --group infrastructure --ide claude --ide cursor

  # With Windsurf support
  $0 --target ../my-repo --group infrastructure --ide windsurf

  # Multiple groups
  $0 --target ../my-monorepo --group backend --group infrastructure --ide cursor
EOF
    exit 1
}

TARGET=""
SELECTED_GROUPS=()
SELECTED_IDES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -g|--group)
            SELECTED_GROUPS+=("$2")
            shift 2
            ;;
        --ide)
            SELECTED_IDES+=("$2")
            shift 2
            ;;
        --claude)
            SELECTED_IDES+=("claude")
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            err "Unknown option: $1"
            echo ""
            usage
            ;;
    esac
done

if [[ -z "$TARGET" || ${#SELECTED_GROUPS[@]} -eq 0 ]]; then
    err "--target and at least one --group are required."
    echo ""
    usage
fi

# Validate IDE names
for IDE in "${SELECTED_IDES[@]}"; do
    case "$IDE" in
        claude|cursor|windsurf) ;;
        *) err "Unknown IDE '$IDE'. Valid options: ${VALID_IDES}"; exit 1 ;;
    esac
done

# Deduplicate IDE list
declare -A _seen_ides
UNIQUE_IDES=()
for IDE in "${SELECTED_IDES[@]}"; do
    if [[ -z "${_seen_ides[$IDE]+x}" ]]; then
        _seen_ides[$IDE]=1
        UNIQUE_IDES+=("$IDE")
    fi
done
SELECTED_IDES=("${UNIQUE_IDES[@]+"${UNIQUE_IDES[@]}"}")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBRARY_DIR="$(dirname "$SCRIPT_DIR")"

if [[ ! -d "$TARGET" ]]; then
    err "Target directory '$TARGET' does not exist."
    exit 1
fi

TARGET_DIR="$(cd "$TARGET" && pwd)"

GROUPS_DIR="$LIBRARY_DIR/groups"

# Portable relative path (works on macOS and Linux without GNU coreutils)
if ! command -v python3 &>/dev/null; then
    err "python3 is required but not found. Install Python 3 and try again."
    exit 1
fi

relpath() {
    python3 -c "import os.path, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$1" "$2"
}

for GROUP in "${SELECTED_GROUPS[@]}"; do
    if [[ ! -d "$GROUPS_DIR/$GROUP" ]]; then
        err "Group '$GROUP' does not exist in the library ($GROUPS_DIR/$GROUP)."
        exit 1
    fi
done

AGENTS_DIR="$TARGET_DIR/.agents"

echo ""
echo -e "${BOLD}Setting up AI agent configuration${RESET}"
echo -e "  Target:  ${CYAN}$TARGET_DIR${RESET}"
echo -e "  Groups:  ${CYAN}${SELECTED_GROUPS[*]}${RESET}"
if [[ ${#SELECTED_IDES[@]} -gt 0 ]]; then
    echo -e "  IDEs:    ${CYAN}${SELECTED_IDES[*]}${RESET}"
fi
echo ""

# 1. Create directory structure
mkdir -p "$AGENTS_DIR/rules"
mkdir -p "$AGENTS_DIR/skills"

for GROUP in "${SELECTED_GROUPS[@]}"; do
    rm -rf "$AGENTS_DIR/$GROUP"
done
step "Created directory structure"

# 2. Symlink global rules
REL_GLOBAL_AGENTS=$(relpath "$LIBRARY_DIR/global/AGENTS.md" "$AGENTS_DIR/rules")
ln -sfn "$REL_GLOBAL_AGENTS" "$AGENTS_DIR/rules/agents-global-link"
step "Linked global rules"

# 3. Symlink group rules
for GROUP in "${SELECTED_GROUPS[@]}"; do
    REL_GROUP_AGENTS=$(relpath "$GROUPS_DIR/$GROUP/AGENTS.md" "$AGENTS_DIR/rules")
    ln -sfn "$REL_GROUP_AGENTS" "$AGENTS_DIR/rules/agents-$GROUP-link"
done
step "Linked group rules  ${DIM}(${SELECTED_GROUPS[*]})${RESET}"

# 4. Symlink global skills
if [[ -d "$LIBRARY_DIR/global/skills" ]]; then
    REL_GLOBAL_SKILLS=$(relpath "$LIBRARY_DIR/global/skills" "$AGENTS_DIR/skills")
    ln -sfn "$REL_GLOBAL_SKILLS" "$AGENTS_DIR/skills/global-links"
fi

# 5. Symlink group skills
SKILL_GROUPS=()
for GROUP in "${SELECTED_GROUPS[@]}"; do
    if [[ -d "$GROUPS_DIR/$GROUP/skills" ]]; then
        REL_GROUP_SKILLS=$(relpath "$GROUPS_DIR/$GROUP/skills" "$AGENTS_DIR/skills")
        ln -sfn "$REL_GROUP_SKILLS" "$AGENTS_DIR/skills/$GROUP-links"
        SKILL_GROUPS+=("$GROUP")
    fi
done
step "Linked skills        ${DIM}(global${SKILL_GROUPS[*]:+, ${SKILL_GROUPS[*]}})${RESET}"

# 6. Generate composite master index (supports multiple groups)
MASTER_INDEX="$AGENTS_DIR/AGENTS.md"
rm -f "$MASTER_INDEX"
cat << 'HEADER' > "$MASTER_INDEX"
## AUTO-GENERATED FILE - DO NOT EDIT MANUALLY ##
# AI Agent Master Configuration Index

Auto-generated by `setup.sh`. Do not edit manually.

## Shared Rules
HEADER

echo "@rules/agents-global-link" >> "$MASTER_INDEX"
echo "" >> "$MASTER_INDEX"
for GROUP in "${SELECTED_GROUPS[@]}"; do
    echo "@rules/agents-$GROUP-link" >> "$MASTER_INDEX"
done
echo "" >> "$MASTER_INDEX"
echo "- [Global Rules](rules/agents-global-link)" >> "$MASTER_INDEX"
for GROUP in "${SELECTED_GROUPS[@]}"; do
    echo "- [Group Rules ($GROUP)](rules/agents-$GROUP-link)" >> "$MASTER_INDEX"
done
echo "" >> "$MASTER_INDEX"
echo "## Available Skills" >> "$MASTER_INDEX"
echo "@skills/AGENTS.md" >> "$MASTER_INDEX"
echo "- [Skills Catalog](skills/AGENTS.md)" >> "$MASTER_INDEX"

# 7. Generate composite skills index
SKILLS_INDEX="$AGENTS_DIR/skills/AGENTS.md"
rm -f "$SKILLS_INDEX"
cat << 'HEADER' > "$SKILLS_INDEX"
# Available Skills

Auto-generated by `setup.sh`. Do not edit manually.

HEADER

if [[ -d "$LIBRARY_DIR/global/skills" ]]; then
    echo "## Global Skills" >> "$SKILLS_INDEX"
    echo "" >> "$SKILLS_INDEX"
    find "$LIBRARY_DIR/global/skills" -maxdepth 2 -name "SKILL.md" | sort | while read -r skill_file; do
        skill_name=$(basename "$(dirname "$skill_file")")
        echo "- [$skill_name](global-links/$skill_name/SKILL.md)" >> "$SKILLS_INDEX"
        echo "@global-links/$skill_name/SKILL.md" >> "$SKILLS_INDEX"
    done
    echo "" >> "$SKILLS_INDEX"
fi

for GROUP in "${SELECTED_GROUPS[@]}"; do
    if [[ -d "$GROUPS_DIR/$GROUP/skills" ]]; then
        echo "## Group ($GROUP) Skills" >> "$SKILLS_INDEX"
        echo "" >> "$SKILLS_INDEX"
        find "$GROUPS_DIR/$GROUP/skills" -maxdepth 2 -name "SKILL.md" | sort | while read -r skill_file; do
            skill_name=$(basename "$(dirname "$skill_file")")
            echo "- [$skill_name]($GROUP-links/$skill_name/SKILL.md)" >> "$SKILLS_INDEX"
            echo "@$GROUP-links/$skill_name/SKILL.md" >> "$SKILLS_INDEX"
        done
        echo "" >> "$SKILLS_INDEX"
    fi
done
step "Generated composite indexes"

# 8. Manage root AGENTS.md
ROOT_AGENTS="$TARGET_DIR/AGENTS.md"
MANAGED_START="<!-- AGENTS_MANAGED_START -->"
MANAGED_END="<!-- AGENTS_MANAGED_END -->"

MANAGED_CONTENT=$(cat << EOF
$MANAGED_START
## AI Agent Configuration (Managed)
> [!NOTE]
> This section is automatically managed by the config library setup script.

### Shared Agent Rules & Skills
@.agents/AGENTS.md
- [Master Configuration Index](.agents/AGENTS.md)
$MANAGED_END
EOF
)

if [[ ! -f "$ROOT_AGENTS" ]]; then
    echo "# Project Agent Rules" > "$ROOT_AGENTS"
    echo "" >> "$ROOT_AGENTS"
    echo "$MANAGED_CONTENT" >> "$ROOT_AGENTS"
    echo "" >> "$ROOT_AGENTS"
    echo "## Project-specific Rules" >> "$ROOT_AGENTS"
    echo "Add your repository-level rules here." >> "$ROOT_AGENTS"
    step "Created root AGENTS.md"
else
    if grep -q "$MANAGED_START" "$ROOT_AGENTS"; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/$MANAGED_START/,/$MANAGED_END/d" "$ROOT_AGENTS"
        else
            sed -i "/$MANAGED_START/,/$MANAGED_END/d" "$ROOT_AGENTS"
        fi
        echo "$MANAGED_CONTENT" >> "$ROOT_AGENTS"
    else
        echo "" >> "$ROOT_AGENTS"
        echo "$MANAGED_CONTENT" >> "$ROOT_AGENTS"
    fi
    step "Updated root AGENTS.md"
fi

# 9. IDE-specific integrations (opt-in via --ide)
ide_has() {
    local needle="$1"
    for ide in "${SELECTED_IDES[@]}"; do
        [[ "$ide" == "$needle" ]] && return 0
    done
    return 1
}

# -- Claude Code: generate CLAUDE.md with @AGENTS.md import
if ide_has claude; then
    CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
    if [[ ! -f "$CLAUDE_MD" ]]; then
        cat << 'EOF' > "$CLAUDE_MD"
@AGENTS.md
EOF
        step "Created CLAUDE.md     ${DIM}(imports AGENTS.md for Claude Code CLI)${RESET}"
    else
        if ! grep -q "@AGENTS.md" "$CLAUDE_MD"; then
            info "CLAUDE.md exists but does not import AGENTS.md — add ${CYAN}@AGENTS.md${RESET} manually if needed"
        else
            step "CLAUDE.md already imports AGENTS.md"
        fi
    fi
fi

# -- Cursor: symlink skills into .cursor/skills/ for reliable discovery
if ide_has cursor; then
    CURSOR_SKILLS="$TARGET_DIR/.cursor/skills"
    mkdir -p "$CURSOR_SKILLS"

    if [[ -d "$LIBRARY_DIR/global/skills" ]]; then
        REL=$(relpath "$LIBRARY_DIR/global/skills" "$CURSOR_SKILLS")
        ln -sfn "$REL" "$CURSOR_SKILLS/global-links"
    fi

    for GROUP in "${SELECTED_GROUPS[@]}"; do
        if [[ -d "$GROUPS_DIR/$GROUP/skills" ]]; then
            REL=$(relpath "$GROUPS_DIR/$GROUP/skills" "$CURSOR_SKILLS")
            ln -sfn "$REL" "$CURSOR_SKILLS/$GROUP-links"
        fi
    done
    step "Linked Cursor skills  ${DIM}(.cursor/skills/)${RESET}"
fi

# -- Windsurf: symlink .windsurfrules to AGENTS.md
if ide_has windsurf; then
    WINDSURF_RULES="$TARGET_DIR/.windsurfrules"
    if [[ -L "$WINDSURF_RULES" || ! -f "$WINDSURF_RULES" ]]; then
        ln -sfn "AGENTS.md" "$WINDSURF_RULES"
        step "Linked .windsurfrules ${DIM}(symlink to AGENTS.md)${RESET}"
    else
        if [[ -f "$WINDSURF_RULES" ]]; then
            info ".windsurfrules already exists as a regular file — skipped"
        fi
    fi
fi

# 10. Update .gitignore
GITIGNORE="$TARGET_DIR/.gitignore"

add_to_gitignore() {
    local pattern="$1"
    if [[ ! -f "$GITIGNORE" ]]; then
        echo "$pattern" > "$GITIGNORE"
    elif ! grep -qxF "$pattern" "$GITIGNORE"; then
        echo "$pattern" >> "$GITIGNORE"
    fi
}

add_to_gitignore "# AI Agent Configuration (managed by agentic-ai-library)"
add_to_gitignore ".agents/"
add_to_gitignore "AGENTS.local.md"
if ide_has claude; then
    add_to_gitignore "CLAUDE.md"
    add_to_gitignore "CLAUDE.local.md"
fi
if ide_has cursor; then
    add_to_gitignore ".cursor/skills/"
fi
if ide_has windsurf; then
    add_to_gitignore ".windsurfrules"
fi
step "Updated .gitignore"

# Done
echo ""
echo -e "${GREEN}${BOLD}  Setup complete!${RESET}"
echo ""
echo -e "  ${ARROW} Rules and skills are symlinked to the library."
echo -e "  ${ARROW} Run ${CYAN}git pull${RESET} in the library to propagate updates."
echo -e "  ${ARROW} Re-run this script only to add or remove groups."
echo ""
