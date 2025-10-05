#!/bin/bash

# Babaji Configuration Utility - Persistent Files Module
# Setup symlinks from NAS to home directory

# Persistent files menu
persistent_files_menu() {
    # Check if dotfiles persistent files fragment exists
    local FRAGMENT="/usr/local/lib/babaji-config/fragments/dotfiles/persistent-files.fragment"

    if [ ! -f "$FRAGMENT" ]; then
        style_subheader "🔗 Persistent Files Setup" "Dotfiles not installed" "#e74c3c"
        echo ""
        style_error "❌ Dotfiles are not installed"
        echo ""
        echo "This feature requires dotfiles to be installed."
        echo ""
        echo "Configure DevPod dotfiles and rebuild your workspace."
        echo ""
        wait_for_user
        return
    fi

    # Source the fragment to load functions
    source "$FRAGMENT" 2>/dev/null || {
        style_error "❌ Failed to load persistent files fragment"
        wait_for_user
        return
    }

    while true; do
        style_subheader "🔗 Persistent Files Setup" "Symlink management for NAS-backed files" "#4a90e2"

        local choice=$(choose_option "Select action:" \
            "▶️  Setup Symlinks Now" \
            "📋 View Current Configuration" \
            "📝 How to Edit & Update" \
            "⬅️  Back to Main Menu")

        case "$choice" in
            "▶️  Setup Symlinks Now")
                run_persistent_files_setup
                ;;
            "📋 View Current Configuration")
                view_symlinks_config
                ;;
            "📝 How to Edit & Update")
                persistent_files_info
                wait_for_user
                ;;
            "⬅️  Back to Main Menu"|*)
                return
                ;;
        esac
    done
}

# Run the setup function
run_persistent_files_setup() {
    clear
    style_subheader "▶️  Running Persistent Files Setup" "" "#4a90e2"
    echo ""

    # Run the setup in a zsh subshell (persistent_files_setup is a zsh function)
    zsh -c '
        source ~/.zshrc
        if type persistent_files_setup &>/dev/null; then
            persistent_files_setup
        else
            echo "❌ persistent_files_setup function not found"
            echo ""
            echo "The function should be loaded from .persistent-files.zshrc"
            echo "Try reloading your shell: exec zsh"
            exit 1
        fi
    '

    echo ""
    wait_for_user
}

# View current configuration
view_symlinks_config() {
    clear
    style_subheader "📋 Current Symlink Configuration" "" "#4a90e2"
    echo ""

    local CONFIG_FILE="$HOME/dotfiles/config/symlinks.conf"

    if [ ! -f "$CONFIG_FILE" ]; then
        style_error "❌ Config file not found: $CONFIG_FILE"
        echo ""
        echo "Make sure dotfiles are properly installed."
    else
        echo "Config file: $CONFIG_FILE"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$CONFIG_FILE"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Active entries:"
        local count=$(grep -v '^#' "$CONFIG_FILE" | grep -v '^[[:space:]]*$' | wc -l)
        echo "  $count symlink(s) configured"
    fi

    echo ""
    wait_for_user
}
