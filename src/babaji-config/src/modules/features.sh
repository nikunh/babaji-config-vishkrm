#!/bin/bash

# Babaji Configuration Utility - Features Module
# DevContainer feature version management and updates

# Features menu function
features_menu() {
    while true; do
        style_subheader "📦 DevContainer Features Management" "Monitor and manage feature versions" "#00ffff"

        local choice=$(choose_option "Select features operation:" \
            "📋 List Installed Features" \
            "🔍 Check for Updates" \
            "🔄 Force Update Check" \
            "📊 View Update Status" \
            "💡 Feature Commands Help" \
            "⬅️  Back to Main Menu")

        case "$choice" in
            "📋 List Installed Features")
                list_installed_features
                ;;
            "🔍 Check for Updates")
                check_feature_updates
                ;;
            "🔄 Force Update Check")
                force_feature_update_check
                ;;
            "📊 View Update Status")
                view_update_status
                ;;
            "💡 Feature Commands Help")
                show_feature_commands_help
                ;;
            "⬅️  Back to Main Menu"|*)
                return 0
                ;;
        esac
    done
}

# List all installed features
list_installed_features() {
    style_subheader "📋 Installed DevContainer Features" "" "#00ff00"

    echo ""
    if command -v /usr/local/lib/babaji-config/modules/feature-update-checker.sh &>/dev/null; then
        /usr/local/lib/babaji-config/modules/feature-update-checker.sh list
    else
        style_error "❌ Feature update checker not available"
    fi

    echo ""
    style_info "💡 Tip: You can also run 'list-features' directly in your shell"
    wait_for_user
}

# Check for feature updates
check_feature_updates() {
    style_subheader "🔍 Checking for Feature Updates" "" "#ffff00"

    echo ""
    if command -v /usr/local/lib/babaji-config/modules/feature-update-checker.sh &>/dev/null; then
        /usr/local/lib/babaji-config/modules/feature-update-checker.sh status
    else
        style_error "❌ Feature update checker not available"
    fi

    echo ""
    style_info "💡 Tip: You can also run 'check-updates' directly in your shell"
    wait_for_user
}

# Force update check
force_feature_update_check() {
    style_subheader "🔄 Force Checking for Updates" "" "#ff8800"

    echo ""
    echo "🔄 Clearing cache and checking for updates..."
    if command -v /usr/local/lib/babaji-config/modules/feature-update-checker.sh &>/dev/null; then
        /usr/local/lib/babaji-config/modules/feature-update-checker.sh force
        echo ""
        /usr/local/lib/babaji-config/modules/feature-update-checker.sh status
    else
        style_error "❌ Feature update checker not available"
    fi

    echo ""
    style_info "💡 Tip: You can also run 'force-check' directly in your shell"
    wait_for_user
}

# View current update status
view_update_status() {
    style_subheader "📊 Feature Update Status" "" "#00ffff"

    echo ""
    echo "Current prompt status indicator:"
    if command -v /usr/local/lib/babaji-config/modules/feature-update-checker.sh &>/dev/null; then
        local prompt_status=$(/usr/local/lib/babaji-config/modules/feature-update-checker.sh prompt 2>/dev/null)
        if [[ -n "$prompt_status" ]]; then
            echo "  $prompt_status"
            echo ""
            echo "This is what appears in your shell prompt to indicate feature status."
        else
            echo "  No status available (cache may be building)"
        fi
    else
        style_error "❌ Feature update checker not available"
    fi

    echo ""
    style_info "ℹ️  Status indicators:"
    echo "  • [✓ up-to-date] - All features are at the latest versions"
    echo "  • [checking...] - System is checking for updates"
    echo "  • [feature:vX.X.X] - Updates available for listed features"

    wait_for_user
}

# Show help for feature commands
show_feature_commands_help() {
    style_subheader "💡 Feature Management Commands" "Quick reference for shell commands" "#ffff00"

    echo ""
    style_info "🚀 You can use these commands directly in your shell:"
    echo ""
    echo "  ${CYAN}list-features${RESET}"
    echo "    List all installed DevContainer features and their versions"
    echo ""
    echo "  ${CYAN}check-updates${RESET}"
    echo "    Check if any feature updates are available"
    echo ""
    echo "  ${CYAN}force-check${RESET}"
    echo "    Force refresh the update cache and check for updates"
    echo ""
    style_info "📍 Prompt Integration:"
    echo "  Your shell prompt automatically shows feature update status:"
    echo "  • ${GREEN}[✓ up-to-date]${RESET} when all features are current"
    echo "  • ${YELLOW}[feature:vX.X.X]${RESET} when updates are available"
    echo "  • ${BLUE}[checking...]${RESET} when the system is checking for updates"
    echo ""
    style_info "🔧 How it works:"
    echo "  The system automatically checks GitHub for newer feature versions"
    echo "  and compares them with what's installed in your container."
    echo "  Updates require rebuilding the DevContainer with 'devpod up'."

    wait_for_user
}