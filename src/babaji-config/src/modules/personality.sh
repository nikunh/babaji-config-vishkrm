#!/bin/bash

# Babaji Configuration Utility - Branch Personality Info Module
# Shows current branch info, installed features, and available updates

# Path to the feature update checker script
FEATURE_UPDATE_CHECKER="/usr/local/lib/babaji-config/modules/feature-update-checker.sh"

# Get current shellinator branch
get_current_branch() {
    local branch_name=""

    # Try to detect from git repo
    if [[ -d "/workspaces/shellinator/.git" ]]; then
        cd "/workspaces/shellinator" 2>/dev/null && {
            branch_name=$(git branch --show-current 2>/dev/null)
            cd - >/dev/null
        }
    fi

    # Fallback detection
    if [[ -z "$branch_name" ]]; then
        if [[ -f "/.devcontainer/devcontainer.json" ]]; then
            local container_name=$(jq -r '.name // empty' /.devcontainer/devcontainer.json 2>/dev/null)
            case "$container_name" in
                *"GitHub"*) branch_name="master" ;;
                *"Local"*) branch_name="local" ;;
                *) branch_name="unknown" ;;
            esac
        else
            branch_name="local"
        fi
    fi

    echo "$branch_name"
}

# Get branch description
get_branch_description() {
    local branch="$1"

    case "$branch" in
        master|main)
            echo "Full-featured Shellinator with all available tools and features"
            ;;
        ai)
            echo "AI-focused development environment with machine learning tools"
            ;;
        devops)
            echo "DevOps-focused setup with Kubernetes, cloud tools, and automation"
            ;;
        web|frontend)
            echo "Web development focused with Node.js, frontend frameworks, and tools"
            ;;
        minimal)
            echo "Minimal setup with only essential development tools"
            ;;
        experimental)
            echo "Experimental features and cutting-edge development tools"
            ;;
        local|custom)
            echo "Local development setup with custom configuration"
            ;;
        *)
            echo "Custom branch with specialized feature set"
            ;;
    esac
}

# Branch Personality Info Menu
personality_menu() {
    while true; do
        local current_branch=$(get_current_branch)
        local branch_desc=$(get_branch_description "$current_branch")

        style_subheader "🎭 Branch Personality Information" "Current: $current_branch" "#00ffff"

        echo ""
        style_info "📍 Current Branch Personality:"
        echo "  Branch: $current_branch"
        echo "  Description: $branch_desc"
        echo ""

        local choice=$(choose_option "Select information to view:" \
            "📋 Show Installed Features" \
            "🔍 Check for Feature Updates" \
            "🔄 Force Update Check" \
            "📊 Show Update Status" \
            "💻 Available Shell Commands" \
            "ℹ️  Branch System Help" \
            "⬅️  Back to Main Menu")

        case "$choice" in
            "📋 Show Installed Features")
                show_installed_features
                ;;
            "🔍 Check for Feature Updates")
                check_feature_updates
                ;;
            "🔄 Force Update Check")
                force_feature_update_check
                ;;
            "📊 Show Update Status")
                show_update_status
                ;;
            "💻 Available Shell Commands")
                show_available_commands
                ;;
            "ℹ️  Branch System Help")
                show_branch_help
                ;;
            "⬅️  Back to Main Menu"|*)
                return 0
                ;;
        esac
    done
}

# Show all installed features
show_installed_features() {
    local current_branch=$(get_current_branch)
    style_subheader "📋 Installed Features" "Branch: $current_branch" "#00ff00"

    echo ""
    if [[ -f "$FEATURE_UPDATE_CHECKER" ]]; then
        "$FEATURE_UPDATE_CHECKER" list
    else
        style_error "❌ Feature update checker not available"
    fi

    echo ""
    style_info "💡 These features are installed in your current $current_branch personality"
    wait_for_user
}

# Check for feature updates
check_feature_updates() {
    style_subheader "🔍 Feature Update Check" "" "#ffff00"

    echo ""
    if [[ -f "$FEATURE_UPDATE_CHECKER" ]]; then
        "$FEATURE_UPDATE_CHECKER" status
    else
        style_error "❌ Feature update checker not available"
    fi

    echo ""
    style_info "💡 Updates require rebuilding the container with 'devpod up'"
    wait_for_user
}

# Force update check
force_feature_update_check() {
    style_subheader "🔄 Force Update Check" "" "#ff8800"

    echo ""
    echo "🔄 Clearing cache and checking for updates..."
    if [[ -f "$FEATURE_UPDATE_CHECKER" ]]; then
        "$FEATURE_UPDATE_CHECKER" force
        echo ""
        "$FEATURE_UPDATE_CHECKER" status
    else
        style_error "❌ Feature update checker not available"
    fi

    echo ""
    style_info "💡 Your prompt will now show any available updates"
    wait_for_user
}

# Show current update status in prompt
show_update_status() {
    style_subheader "📊 Current Prompt Status" "" "#00ffff"

    echo ""
    echo "Current prompt indicator:"
    if [[ -f "$FEATURE_UPDATE_CHECKER" ]]; then
        local prompt_status=$("$FEATURE_UPDATE_CHECKER" prompt 2>/dev/null)
        if [[ -n "$prompt_status" ]]; then
            echo "  🏠 $(get_current_branch) $(echo "$prompt_status" | sed 's/.*\[\(.*\)\].*/\1/')"
            echo ""
            echo "This appears in your shell prompt to show feature status."
        else
            echo "  🏠 $(get_current_branch) (checking...)"
            echo ""
            echo "System is building the status cache."
        fi
    else
        style_error "❌ Feature update checker not available"
    fi

    echo ""
    style_info "📍 Prompt Status Indicators:"
    echo "  • ✓ up-to-date - All features current"
    echo "  • checking... - System checking for updates"
    echo "  • feature:vX.X.X - Updates available"

    wait_for_user
}

# Show all available shell commands
show_available_commands() {
    style_subheader "💻 Available Shell Commands" "Quick reference for all commands" "#ffff00"

    echo ""
    style_info "🔧 Feature Management Commands:"
    echo "  ${CYAN}list-features${RESET}     - List all installed features and versions"
    echo "  ${CYAN}check-updates${RESET}     - Check for available feature updates"
    echo "  ${CYAN}force-check${RESET}       - Force refresh update cache"
    echo ""

    style_info "🛠️  Babaji Configuration Commands:"
    echo "  ${CYAN}babaji-config${RESET}     - Open the main Babaji configuration menu"
    echo ""

    style_info "🎯 System Commands:"
    echo "  ${CYAN}htop${RESET}              - System process monitor"
    echo "  ${CYAN}df -h${RESET}             - Check disk space usage"
    echo "  ${CYAN}free -h${RESET}           - Check memory usage"
    echo "  ${CYAN}docker ps${RESET}         - List running containers (if Docker available)"
    echo ""

    style_info "📁 Navigation Commands:"
    echo "  ${CYAN}ls -la${RESET}            - List files with details"
    echo "  ${CYAN}tree${RESET}              - Show directory tree structure"
    echo "  ${CYAN}find . -name \"*pattern*\"${RESET} - Find files by name pattern"
    echo ""

    style_info "💾 Git Commands (if in git repo):"
    echo "  ${CYAN}git status${RESET}        - Show git working tree status"
    echo "  ${CYAN}git log --oneline${RESET}  - Show commit history"
    echo "  ${CYAN}git branch -a${RESET}     - Show all branches"

    wait_for_user
}

# Show branch system help
show_branch_help() {
    style_subheader "ℹ️  Branch-Based Personality System" "How it works" "#00ffff"

    echo ""
    style_info "🎭 What are Branch Personalities?"
    echo "  Each git branch represents a different 'personality' or feature set:"
    echo ""
    echo "  • ${CYAN}master${RESET} - Full-featured environment with all tools"
    echo "  • ${CYAN}ai${RESET} - Machine learning and AI development focused"
    echo "  • ${CYAN}devops${RESET} - Kubernetes, cloud tools, infrastructure automation"
    echo "  • ${CYAN}web${RESET} - Frontend/backend web development tools"
    echo "  • ${CYAN}minimal${RESET} - Essential tools only, lightweight setup"
    echo "  • ${CYAN}experimental${RESET} - Cutting-edge and beta features"
    echo ""

    style_info "🔄 How to Switch Personalities:"
    echo "  1. Stop your current container: ${CYAN}devpod stop shellinator${RESET}"
    echo "  2. Switch to desired branch: ${CYAN}devpod up https://github.com/nikunh/shellinator.git@branch-name${RESET}"
    echo "  3. Your prompt will show: ${CYAN}🔀 branch-name ✓ up-to-date${RESET}"
    echo ""

    style_info "📦 Feature Updates:"
    echo "  • Features are updated automatically via GitHub workflows"
    echo "  • Your prompt shows when updates are available"
    echo "  • Rebuild container to get latest versions: ${CYAN}devpod up${RESET}"
    echo ""

    style_info "🎯 Current Branch Benefits:"
    local current_branch=$(get_current_branch)
    echo "  You're on: ${CYAN}$current_branch${RESET}"
    echo "  $(get_branch_description "$current_branch")"

    wait_for_user
}