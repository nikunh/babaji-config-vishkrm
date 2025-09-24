#!/bin/bash
# Feature Update Checker for Zsh Prompt
# Checks for available updates to DevContainer features and displays in prompt

CACHE_FILE="/tmp/feature-updates-cache.json"
CACHE_DURATION=3600  # 1 hour in seconds
DEVCONTAINER_JSON="/workspaces/shellinator/.devcontainer/devcontainer.json"

# Colors for prompt display
PROMPT_BLUE="%F{blue}"
PROMPT_YELLOW="%F{yellow}"
PROMPT_GREEN="%F{green}"
PROMPT_RESET="%f"

# Check if cache is valid (not older than CACHE_DURATION)
is_cache_valid() {
    if [[ -f "$CACHE_FILE" ]]; then
        # Use stat to get modification time, handling both macOS and Linux
        local cache_time
        if command -v stat >/dev/null 2>&1; then
            # Try Linux format first (more common in containers)
            cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
            # If that fails, try macOS format
            if [[ -z "$cache_time" ]]; then
                cache_time=$(stat -f %m "$CACHE_FILE" 2>/dev/null)
            fi
        fi

        # If stat failed or returned empty, assume cache is invalid
        if [[ -z "$cache_time" ]]; then
            return 1
        fi

        local current_time=$(date +%s)
        local cache_age=$((current_time - cache_time))

        if [[ $cache_age -lt $CACHE_DURATION ]]; then
            return 0
        fi
    fi
    return 1
}

# Extract enabled features from devcontainer.json
get_enabled_features() {
    if [[ ! -f "$DEVCONTAINER_JSON" ]]; then
        return 1
    fi

    # Parse features from devcontainer.json
    # Format: "ghcr.io/nikunh/feature-vishkrm/feature:version": {}
    jq -r '.features | to_entries[] | select(.key | contains("-vishkrm/")) | .key' "$DEVCONTAINER_JSON" 2>/dev/null | while read -r feature_key; do
        # Extract feature info from the key
        # Example: ghcr.io/nikunh/ai-tools-vishkrm/ai-tools:0.0.13
        if [[ $feature_key =~ ghcr\.io/nikunh/([^/]+)/([^:]+):([0-9.]+) ]]; then
            local repo_name="${BASH_REMATCH[1]}"
            local feature_name="${BASH_REMATCH[2]}"
            local current_version="${BASH_REMATCH[3]}"

            echo "${repo_name}|${feature_name}|${current_version}"
        fi
    done
}

# Get latest version for a specific feature from GitHub Container Registry
get_latest_version() {
    local repo_name="$1"
    local feature_name="$2"

    # Query GitHub Container Registry API for latest version
    # Use users API instead of orgs for personal repos
    local package_name="${repo_name}%2F${feature_name}"
    local api_url="https://api.github.com/users/nikunh/packages/container/${package_name}/versions"

    # Get the latest version tag (assuming semantic versioning)
    curl -s -H "Accept: application/vnd.github.v3+json" "$api_url" 2>/dev/null | \
    jq -r '.[0].metadata.container.tags[]' 2>/dev/null | \
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | \
    sort -V | \
    tail -1
}

# Check for updates and generate cache
update_cache() {
    local updates=()

    while IFS='|' read -r repo_name feature_name current_version; do
        if [[ -n "$repo_name" && -n "$feature_name" && -n "$current_version" ]]; then
            local latest_version=$(get_latest_version "$repo_name" "$feature_name")

            if [[ -n "$latest_version" && "$latest_version" != "$current_version" ]]; then
                # Compare versions using sort -V
                if [[ "$(printf '%s\n%s' "$current_version" "$latest_version" | sort -V | tail -1)" != "$current_version" ]]; then
                    updates+=("{\"feature\":\"$feature_name\",\"current\":\"$current_version\",\"latest\":\"$latest_version\"}")
                fi
            fi
        fi
    done < <(get_enabled_features)

    # Create JSON cache file
    if [[ ${#updates[@]} -gt 0 ]]; then
        printf '[%s]\n' "$(IFS=','; echo "${updates[*]}")" > "$CACHE_FILE"
    else
        echo '[]' > "$CACHE_FILE"
    fi
}

# Get prompt string for available updates
get_update_prompt() {
    local cache_content
    local update_parts=()

    if [[ -f "$CACHE_FILE" ]]; then
        cache_content=$(cat "$CACHE_FILE" 2>/dev/null)

        # Parse cache and build prompt parts
        while IFS= read -r update_line; do
            if [[ -n "$update_line" ]]; then
                local feature=$(echo "$update_line" | jq -r '.feature' 2>/dev/null)
                local latest=$(echo "$update_line" | jq -r '.latest' 2>/dev/null)

                if [[ -n "$feature" && -n "$latest" && "$feature" != "null" && "$latest" != "null" ]]; then
                    update_parts+=("${feature}:v${latest}")
                fi
            fi
        done < <(echo "$cache_content" | jq -c '.[]' 2>/dev/null)

        # Build the prompt string - only show if updates are available
        if [[ ${#update_parts[@]} -gt 0 ]]; then
            local updates_string=$(IFS=', '; echo "${update_parts[*]}")
            echo "${PROMPT_YELLOW}[${updates_string}]${PROMPT_RESET}"
        fi
        # If no updates available, return empty string (nothing displayed)
    fi
}

# Main function
check_feature_updates() {
    local mode="${1:-prompt}"

    case "$mode" in
        "force")
            # Force cache update
            update_cache
            get_update_prompt
            ;;
        "prompt")
            # Normal prompt check
            if ! is_cache_valid; then
                # Update cache in background to not slow down prompt
                (update_cache &)
            fi
            get_update_prompt
            ;;
        "status")
            # Detailed status output
            if ! is_cache_valid; then
                echo "Checking for feature updates..."
                update_cache
            fi

            local cache_content=$(cat "$CACHE_FILE" 2>/dev/null)
            if [[ "$cache_content" == "[]" ]]; then
                echo "✅ All features are up to date"
            else
                echo "📦 Feature updates available:"
                echo "$cache_content" | jq -r '.[] | "  \(.feature): v\(.latest) update available (current: v\(.current))"' 2>/dev/null
            fi
            ;;
        *)
            echo "Usage: check_feature_updates [prompt|force|status]"
            echo "  prompt - Quick check for prompt display (default)"
            echo "  force  - Force cache update and show prompt"
            echo "  status - Show detailed update status"
            ;;
    esac
}

# If script is called directly, run the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_feature_updates "$@"
fi