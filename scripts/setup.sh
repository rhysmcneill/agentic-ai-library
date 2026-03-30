#!/usr/bin/env bash
# script: setup.sh
# description: Set up AI agent configuration in a target repository.
#              Creates local symlinks only — never commits or pushes.
#              Run once per repo. Updates propagate automatically via symlinks
#              when the library is pulled.

set -euo pipefail

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Set up AI agent configuration in a target repository. Supports Cursor, Claude Code, Codex, and Antigravity.

Options:
  -t, --target <path>  Target repository path (required)
  -g, --group <name>   Team/group name in the config library (e.g., infrastructure, backend) (required)
  -h, --help           Show this help message

Example:
  $0 --target ../my-repo --group infrastructure
EOF
    exit 1
}

TARGET=""
TEAM=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -g|--group)
            TEAM="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$TARGET" || -z "$TEAM" ]]; then
    echo "Error: Both --target and --group are required."
    echo ""
    usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBRARY_DIR="$(dirname "$SCRIPT_DIR")"

if [[ ! -d "$TARGET" ]]; then
    echo "Error: Target directory '$TARGET' does not exist."
    exit 1
fi

TARGET_DIR="$(cd "$TARGET" && pwd)"

TEAMS_DIR="$LIBRARY_DIR/teams"

if [[ ! -d "$TEAMS_DIR/$TEAM" ]]; then
    echo "Error: Team directory '$TEAM' does not exist in the library ($TEAMS_DIR/$TEAM)."
    exit 1
fi

if [[ ! -d "$LIBRARY_DIR/_generated/$TEAM" ]]; then
    echo "Error: Pre-built indexes not found for '$TEAM'."
    echo "Run 'scripts/generate-indexes.sh' in the library first."
    exit 1
fi

AGENTS_DIR="$TARGET_DIR/.agents"

echo "Setting up AI agent configuration for: $TARGET_DIR"
echo "Team: $TEAM"
echo ""

# 1. Create directory structure
echo "Creating directory structure..."
mkdir -p "$AGENTS_DIR/rules"
mkdir -p "$AGENTS_DIR/skills"

rm -rf "$AGENTS_DIR/company" "$AGENTS_DIR/$TEAM"

# 2. Symlink rules
echo "Linking rules..."
REL_COMPANY_AGENTS=$(realpath --relative-to="$AGENTS_DIR/rules" "$LIBRARY_DIR/company/AGENTS.md")
ln -sfn "$REL_COMPANY_AGENTS" "$AGENTS_DIR/rules/agents-company-link"

REL_TEAM_AGENTS=$(realpath --relative-to="$AGENTS_DIR/rules" "$TEAMS_DIR/$TEAM/AGENTS.md")
ln -sfn "$REL_TEAM_AGENTS" "$AGENTS_DIR/rules/agents-$TEAM-link"

# 3. Symlink skills
echo "Linking skills..."
if [[ -d "$LIBRARY_DIR/company/skills" ]]; then
    REL_COMPANY_SKILLS=$(realpath --relative-to="$AGENTS_DIR/skills" "$LIBRARY_DIR/company/skills")
    ln -sfn "$REL_COMPANY_SKILLS" "$AGENTS_DIR/skills/company-links"
fi
if [[ -d "$TEAMS_DIR/$TEAM/skills" ]]; then
    REL_TEAM_SKILLS=$(realpath --relative-to="$AGENTS_DIR/skills" "$TEAMS_DIR/$TEAM/skills")
    ln -sfn "$REL_TEAM_SKILLS" "$AGENTS_DIR/skills/$TEAM-links"
fi

# 4. Symlink pre-built indexes (generated in the library by generate-indexes.sh)
echo "Linking indexes..."
REL_MASTER_INDEX=$(realpath --relative-to="$AGENTS_DIR" "$LIBRARY_DIR/_generated/$TEAM/master-index.md")
ln -sfn "$REL_MASTER_INDEX" "$AGENTS_DIR/AGENTS.md"

REL_SKILLS_INDEX=$(realpath --relative-to="$AGENTS_DIR/skills" "$LIBRARY_DIR/_generated/$TEAM/skills-index.md")
ln -sfn "$REL_SKILLS_INDEX" "$AGENTS_DIR/skills/AGENTS.md"

# 5. Manage root AGENTS.md
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
    echo "Creating root AGENTS.md..."
    echo "# Project Agent Rules" > "$ROOT_AGENTS"
    echo "" >> "$ROOT_AGENTS"
    echo "$MANAGED_CONTENT" >> "$ROOT_AGENTS"
    echo "" >> "$ROOT_AGENTS"
    echo "## Project-specific Rules" >> "$ROOT_AGENTS"
    echo "Add your repository-level rules here." >> "$ROOT_AGENTS"
else
    echo "Updating root AGENTS.md..."
    if grep -q "$MANAGED_START" "$ROOT_AGENTS"; then
        sed -i "/$MANAGED_START/,/$MANAGED_END/d" "$ROOT_AGENTS"
        echo "$MANAGED_CONTENT" >> "$ROOT_AGENTS"
    else
        echo "" >> "$ROOT_AGENTS"
        echo "$MANAGED_CONTENT" >> "$ROOT_AGENTS"
    fi
fi

# 6. Update .gitignore
GITIGNORE="$TARGET_DIR/.gitignore"
echo "Updating .gitignore..."

add_to_gitignore() {
    local pattern="$1"
    if [[ ! -f "$GITIGNORE" ]]; then
        echo "$pattern" > "$GITIGNORE"
    elif ! grep -qxF "$pattern" "$GITIGNORE"; then
        echo "$pattern" >> "$GITIGNORE"
    fi
}

add_to_gitignore "# AI Agent Configuration (managed by ai-agents-config-library)"
add_to_gitignore ".agents/"
add_to_gitignore "AGENTS.local.md"

echo ""
echo "Done! Configuration established in $TARGET_DIR"
echo ""
echo "Symlinks point back to the library. Future library updates"
echo "(git pull) propagate automatically — no need to re-run this script."
