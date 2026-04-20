#!/usr/bin/env bash
# canon-workspace PreToolUse hook.
# Blocks Write/Edit/MultiEdit calls that target files under a canon workspace's sources/ directory.
# A "canon workspace" is identified by the presence of both synthesis.md and process.md as siblings of sources/.
# Exits 0 to allow, 2 to block (stderr shown to the agent).

set -u

input=$(cat)

extract_string_field() {
  printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]+\"" | head -1 \
    | sed -E "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"([^\"]+)\".*/\1/"
}

tool_name=$(extract_string_field "$input" "tool_name")

case "$tool_name" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

file_path=$(extract_string_field "$input" "file_path")
[ -z "$file_path" ] && exit 0

# JSON-decode doubled backslashes (Windows paths come through as "C:\\foo\\bar").
decoded=$(printf '%s' "$file_path" | sed -E 's/\\\\/\\/g')

# Normalize backslashes to forward slashes for path matching.
normalized=$(printf '%s' "$decoded" | tr '\\' '/')

case "$normalized" in
  */sources/*)
    parent="${normalized%%/sources/*}"
    if [ -f "$parent/synthesis.md" ] && [ -f "$parent/process.md" ]; then
      cat >&2 <<'EOF'
BLOCKED by canon-workspace: sources/ is immutable after capture.

Files under sources/ are preserved verbatim to maintain provenance. Modifying
them breaks the audit trail from canonical claims back to their source fragments.

If a capture error genuinely needs correcting, the human should edit the file
manually outside the agent.
EOF
      exit 2
    fi
    ;;
esac

exit 0
