#!/bin/bash

# Babaji Configuration Utility - Personality Management Module
# Handles DevContainer personality creation, switching, and management

# Personality Management Menu
personality_menu() {
    while true; do
        style_header "🎭 Personality Management" "Feature-Based DevContainer Personalities"
        
        # Get current status
        local coord_dir="/coordination"
        local personalities_dir="$coord_dir/personalities"
        local current_personality=$(get_current_personality)
        local available_personalities=()
        
        # Scan for available personalities
        if [[ -d "$personalities_dir" ]]; then
            while IFS= read -r -d '' personality_dir; do
                local personality_name=$(basename "$personality_dir")
                if [[ -f "$personality_dir/port" ]] && [[ "$personality_name" != "v1" ]] && [[ "$personality_name" != "v2" ]]; then
                    available_personalities+=("$personality_name")
                fi
            done < <(find "$personalities_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
        fi
        
        # Status display
        echo ""
        style_info "Current Status:"
        
        if [[ "$current_personality" == "default" ]] || [[ "$current_personality" == "v1" ]]; then
            style_success "  🟢 Current Personality: Default (Port $(get_personality_port "$current_personality" || echo "2225"))"
        else
            style_success "  🟢 Current Personality: $current_personality (Port $(get_personality_port "$current_personality"))"
        fi
        
        # Show available personalities
        if [[ ${#available_personalities[@]} -gt 0 ]]; then
            echo ""
            style_info "Available Personalities:"
            for personality in "${available_personalities[@]}"; do
                local port=$(get_personality_port "$personality")
                local status=$(get_personality_status "$personality")
                case "$status" in
                    "active")
                        style_success "  🟢 $personality (Port $port) - Active"
                        ;;
                    "ready")
                        style_info "  ⚪ $personality (Port $port) - Ready"
                        ;;
                    "building")
                        style_warning "  🟡 $personality (Port $port) - Building"
                        ;;
                    *)
                        style_dim "  ⚫ $personality (Port $port) - Unknown"
                        ;;
                esac
            done
        fi
        
        echo ""
        
        # Menu options
        local menu_options=()
        
        # Core personality management
        menu_options+=("🎯 Create New Personality")
        menu_options+=("📊 Show All Personalities")
        
        # Switch options
        if [[ ${#available_personalities[@]} -gt 0 ]]; then
            menu_options+=("🔄 Switch to Personality")
        fi
        
        # Management options
        menu_options+=("🗑️  Remove Personality")
        menu_options+=("📝 Edit Personality Config")
        menu_options+=("🔧 Rebuild Personality")
        
        # Branch management
        menu_options+=("🌱 Create Feature Branch")
        menu_options+=("📋 Manage Feature Branches")
        
        # System options
        menu_options+=("⚙️  Personality System Settings")
        menu_options+=("🔙 Back to Main Menu")
        
        local choice=$(choose_option "Select action:" "${menu_options[@]}")
        
        case "$choice" in
            "🎯 Create New Personality")
                personality_create_new
                ;;
            "📊 Show All Personalities")
                personality_show_all
                ;;
            "🔄 Switch to Personality")
                personality_switch_menu
                ;;
            "🗑️  Remove Personality")
                personality_remove_menu
                ;;
            "📝 Edit Personality Config")
                personality_edit_menu
                ;;
            "🔧 Rebuild Personality")
                personality_rebuild_menu
                ;;
            "🌱 Create Feature Branch")
                personality_create_branch
                ;;
            "📋 Manage Feature Branches")
                personality_manage_branches
                ;;
            "⚙️  Personality System Settings")
                personality_system_settings
                ;;
            "🔙 Back to Main Menu")
                break
                ;;
        esac
    done
}

# Create new personality
personality_create_new() {
    style_header "🎯 Create New Personality"
    
    echo ""
    style_info "Create a custom DevContainer personality with specific features and tools."
    echo ""
    
    # Get personality name
    local personality_name
    personality_name=$(gum input --placeholder "Enter personality name (e.g., python-dev, ai-tools, minimal)")
    
    if [[ -z "$personality_name" ]]; then
        style_warning "Cancelled."
        return
    fi
    
    # Validate name
    if [[ ! "$personality_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        style_error "❌ Invalid name. Use only letters, numbers, hyphens, and underscores."
        read -p "Press Enter to continue..." -r
        return
    fi
    
    # Check if personality already exists
    local personalities_dir="/coordination/personalities"
    if [[ -d "$personalities_dir/$personality_name" ]]; then
        style_error "❌ Personality '$personality_name' already exists."
        read -p "Press Enter to continue..." -r
        return
    fi
    
    echo ""
    style_info "Personality Templates:"
    echo ""
    
    local base_template=$(choose_option "Choose base template:" \
        "🐍 Python Development (conda, jupyter, ai-tools)" \
        "🌐 Web Development (node, npm, dev-tools)" \
        "☁️  DevOps (k8s, terraform, cloud-tools)" \
        "🤖 AI Tools (aider, tmux-neovim, jupyter)" \
        "⚡ Minimal (basic tools only)" \
        "📄 Custom (start from scratch)")
    
    # Create personality directory
    mkdir -p "$personalities_dir/$personality_name"
    
    # Assign port (find next available)
    local port=$(find_next_available_port)
    echo "$port" > "$personalities_dir/$personality_name/port"
    echo "building" > "$personalities_dir/$personality_name/status"
    echo "$(date -u +%s)" > "$personalities_dir/$personality_name/created"
    
    # Create DevContainer config based on template
    local config_file=".devcontainer/personalities/$personality_name.json"
    
    case "$base_template" in
        "🐍 Python Development"*)
            personality_create_python_config "$personality_name" "$config_file"
            ;;
        "🌐 Web Development"*)
            personality_create_web_config "$personality_name" "$config_file"
            ;;
        "☁️  DevOps"*)
            personality_create_devops_config "$personality_name" "$config_file"
            ;;
        "🤖 AI Tools"*)
            personality_create_ai_config "$personality_name" "$config_file"
            ;;
        "⚡ Minimal"*)
            personality_create_minimal_config "$personality_name" "$config_file"
            ;;
        "📄 Custom"*)
            personality_create_custom_config "$personality_name" "$config_file"
            ;;
    esac
    
    # Signal manager to build the personality
    echo "build-$personality_name" > "/coordination/build-request"
    echo "$(date -u +%s)" > "/coordination/build-request-time"
    echo "user-created-personality" > "/coordination/build-trigger-source"
    
    style_success "✅ Personality '$personality_name' created!"
    echo ""
    style_info "Details:"
    echo "  • Name: $personality_name"
    echo "  • Port: $port"
    echo "  • Config: $config_file"
    echo "  • Build Status: Building..."
    echo ""
    style_info "The personality will be built automatically."
    style_info "Use 'Show All Personalities' to monitor build progress."
    
    read -p "Press Enter to continue..." -r
}

# Switch to personality
personality_switch_menu() {
    style_header "🔄 Switch to Personality"
    
    local personalities_dir="/coordination/personalities"
    local available_personalities=()
    local current_personality=$(get_current_personality)
    
    # Collect ready personalities
    if [[ -d "$personalities_dir" ]]; then
        while IFS= read -r -d '' personality_dir; do
            local personality_name=$(basename "$personality_dir")
            local status=$(get_personality_status "$personality_name")
            if [[ "$status" == "ready" ]] || [[ "$status" == "active" ]]; then
                if [[ "$personality_name" != "$current_personality" ]]; then
                    available_personalities+=("$personality_name")
                fi
            fi
        done < <(find "$personalities_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi
    
    # Add default option if not current
    if [[ "$current_personality" != "default" ]] && [[ "$current_personality" != "v1" ]]; then
        available_personalities=("default" "${available_personalities[@]}")
    fi
    
    if [[ ${#available_personalities[@]} -eq 0 ]]; then
        echo ""
        style_warning "No other personalities available to switch to."
        style_info "Create new personalities or wait for builds to complete."
        read -p "Press Enter to continue..." -r
        return
    fi
    
    echo ""
    style_info "Available personalities to switch to:"
    echo ""
    
    local menu_options=()
    for personality in "${available_personalities[@]}"; do
        local port=$(get_personality_port "$personality")
        menu_options+=("$personality (Port $port)")
    done
    menu_options+=("Cancel")
    
    local choice=$(choose_option "Select personality to switch to:" "${menu_options[@]}")
    
    if [[ "$choice" == "Cancel" ]]; then
        return
    fi
    
    local target_personality=$(echo "$choice" | cut -d' ' -f1)
    
    echo ""
    style_warning "This will:"
    echo "  • Switch active SSH port 2225 to $target_personality"
    echo "  • Move current personality to standby"
    echo "  • Cause 2-3 seconds of SSH interruption"
    echo ""
    
    if gum confirm "Switch to $target_personality?"; then
        # Signal personality switch
        echo "switch-to-$target_personality" > "/coordination/switch-request"
        echo "$(date -u +%s)" > "/coordination/switch-request-time"
        
        style_success "✅ Personality switch requested!"
        echo ""
        style_info "Port forwarding will switch momentarily..."
        style_warning "Your SSH session may disconnect - reconnect to port 2225"
    fi
    
    read -p "Press Enter to continue..." -r
}

# Show all personalities
personality_show_all() {
    style_header "📊 All Personalities"
    
    local personalities_dir="/coordination/personalities"
    local current_personality=$(get_current_personality)
    
    echo ""
    style_info "🎯 Current Active:"
    if [[ "$current_personality" == "default" ]] || [[ "$current_personality" == "v1" ]]; then
        echo "  🟢 Default Personality (Port $(get_personality_port "$current_personality" || echo "2225"))"
    else
        echo "  🟢 $current_personality (Port $(get_personality_port "$current_personality"))"
    fi
    
    echo ""
    style_info "🎭 All Personalities:"
    
    if [[ ! -d "$personalities_dir" ]]; then
        style_dim "  No personalities directory found."
        read -p "Press Enter to continue..." -r
        return
    fi
    
    local found_personalities=false
    while IFS= read -r -d '' personality_dir; do
        local personality_name=$(basename "$personality_dir")
        
        # Skip v1/v2 compatibility entries unless they're the current active
        if [[ "$personality_name" == "v1" ]] || [[ "$personality_name" == "v2" ]]; then
            if [[ "$personality_name" != "$current_personality" ]]; then
                continue
            fi
        fi
        
        found_personalities=true
        local port=$(get_personality_port "$personality_name")
        local status=$(get_personality_status "$personality_name")
        local created=$(cat "$personality_dir/created" 2>/dev/null)
        
        echo ""
        case "$status" in
            "active")
                style_success "  🟢 $personality_name"
                ;;
            "ready")
                style_info "  ⚪ $personality_name"
                ;;
            "building")
                style_warning "  🟡 $personality_name"
                ;;
            "failed")
                style_error "  🔴 $personality_name"
                ;;
            *)
                style_dim "  ⚫ $personality_name"
                ;;
        esac
        
        echo "    Port: $port"
        echo "    Status: $status"
        if [[ -n "$created" ]]; then
            echo "    Created: $(date -d "@$created" 2>/dev/null || echo "Unknown")"
        fi
        
        # Show config file if exists
        local config_file=".devcontainer/personalities/$personality_name.json"
        if [[ -f "$config_file" ]]; then
            echo "    Config: $config_file"
        fi
        
    done < <(find "$personalities_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    
    if [[ "$found_personalities" == "false" ]]; then
        style_dim "  No personalities found."
        style_info "  Use 'Create New Personality' to get started."
    fi
    
    read -p "Press Enter to continue..." -r
}

# Utility functions
get_current_personality() {
    # Check coordination directory for current active personality
    local coord_dir="/coordination"
    local current_active
    
    # First check for personality-based active version
    if [[ -f "$coord_dir/current-active-personality" ]]; then
        current_active=$(cat "$coord_dir/current-active-personality" 2>/dev/null)
    # Fall back to v1/v2 compatibility mode
    elif [[ -f "$coord_dir/current-active-version" ]]; then
        current_active=$(cat "$coord_dir/current-active-version" 2>/dev/null)
    else
        current_active="default"
    fi
    
    echo "$current_active"
}

get_personality_port() {
    local personality_name="$1"
    local personalities_dir="/coordination/personalities"
    
    if [[ -f "$personalities_dir/$personality_name/port" ]]; then
        cat "$personalities_dir/$personality_name/port"
    else
        # Default ports for compatibility
        case "$personality_name" in
            "v1"|"default") echo "2225" ;;
            "v2") echo "2226" ;;
            *) echo "2225" ;;
        esac
    fi
}

get_personality_status() {
    local personality_name="$1"
    local personalities_dir="/coordination/personalities"
    
    if [[ -f "$personalities_dir/$personality_name/status" ]]; then
        cat "$personalities_dir/$personality_name/status"
    else
        # Check legacy status files for v1/v2
        case "$personality_name" in
            "v1") cat "/coordination/devcontainer-v1-status" 2>/dev/null || echo "unknown" ;;
            "v2") cat "/coordination/devcontainer-v2-status" 2>/dev/null || echo "none" ;;
            *) echo "unknown" ;;
        esac
    fi
}

find_next_available_port() {
    local start_port=2226
    local end_port=2235
    local personalities_dir="/coordination/personalities"
    
    # Collect used ports
    local used_ports=("2225") # Reserve 2225 for active
    if [[ -d "$personalities_dir" ]]; then
        while IFS= read -r -d '' port_file; do
            local port=$(cat "$port_file" 2>/dev/null)
            if [[ -n "$port" ]]; then
                used_ports+=("$port")
            fi
        done < <(find "$personalities_dir" -name "port" -print0 2>/dev/null)
    fi
    
    # Find first available port
    for port in $(seq $start_port $end_port); do
        local port_used=false
        for used_port in "${used_ports[@]}"; do
            if [[ "$port" == "$used_port" ]]; then
                port_used=true
                break
            fi
        done
        if [[ "$port_used" == "false" ]]; then
            echo "$port"
            return
        fi
    done
    
    # Default fallback
    echo "2227"
}

# Template creation functions
personality_create_python_config() {
    local personality_name="$1"
    local config_file="$2"
    
    cat > "$config_file" << EOF
{
  "name": "Shellinator-$personality_name",
  "image": "ubuntu:22.04",
  "build": {
    "options": [
      "--cache-from=type=registry,ref=${REGISTRY_URL:-registry.example.com}/shellinator-cache",
      "--cache-to=type=registry,ref=${REGISTRY_URL:-registry.example.com}/shellinator-cache,mode=max"
    ]
  },
  "features": {
    "${REGISTRY_URL:-registry.example.com}/features/001-dev-packages:latest": {},
    "${REGISTRY_URL:-registry.example.com}/features/002-user-setup:latest": {},
    "${REGISTRY_URL:-registry.example.com}/features/babaji-config:latest": {},
    "${REGISTRY_URL:-registry.example.com}/features/system-personality:latest": {
      "type": "dev-workstation"
    },
    "${REGISTRY_URL:-registry.example.com}/features/003-zsh-setup:latest": {},
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/devcontainers/features/sshd:1": {
      "version": "latest"
    },
    "ghcr.io/devcontainers/features/conda:1": {},
    "${REGISTRY_URL:-registry.example.com}/features/ai-tools:latest": {
      "claudeApiKey": "",
      "openCodeConfig": true,
      "enableShellIntegration": true
    },
    "${REGISTRY_URL:-registry.example.com}/features/tmux-neovim-git:latest": {},
    "ghcr.io/devcontainers/features/node:1": {
      "version": "lts"
    }
  },
  "remoteUser": "babaji",
  "containerEnv": {
    "HOME": "/home/babaji",
    "DEVCONTAINER_PERSONALITY": "$personality_name",
    "DEVCONTAINER_ROLE": "active"
  },
  "workspaceMount": "source=\${localWorkspaceFolder},target=/workspaces/shellinator-reloaded,type=bind",
  "workspaceFolder": "/workspaces/shellinator-reloaded",
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind",
    "source=/mnt/o/babaji/projects,target=/home/babaji/projects,type=bind",
    "source=\${localWorkspaceFolder}/local-deployment/coordination,target=/coordination,type=bind"
  ],
  "runArgs": [
    "--cap-add=SYS_ADMIN",
    "--security-opt",
    "apparmor=unconfined",
    "--privileged"
  ],
  "forwardPorts": [2222, 6623],
  "postCreateCommand": "pwd && id && sudo id && sudo chmod 0440 /etc/sudoers.d/babaji && id && if [ -f /etc/skel/.zshrc ]; then sudo cp -r /etc/skel/.zshrc /etc/skel/.oh-my-zsh /etc/skel/.ohmyzsh_source_load_scripts /home/babaji/ 2>/dev/null || true; fi && id && sudo usermod -s /bin/zsh babaji && id && sudo find /home/babaji -maxdepth 3 -type f -exec chown babaji:babaji {} + 2>/dev/null || true && sudo find /home/babaji -maxdepth 3 -type d -exec chown babaji:babaji {} + 2>/dev/null || true && id && sudo rm -f /home/babaji/.npmrc && sudo -u babaji npm config delete prefix && sudo -u babaji npm config delete globalconfig && sudo npm install -g mcp-searxng @playwright/mcp && echo 'postCreateCommand executed successfully' && pwd && cd /home/babaji",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-toolsai.jupyter",
        "github.copilot",
        "continue.continue"
      ]
    }
  },
  "shutdownAction": "none",
  "postStartCommand": "echo 'Dev container started. Welcome to $personality_name personality!'",
  "postAttachCommand": "echo 'Attached to $personality_name personality.'"
}
EOF
}

personality_create_minimal_config() {
    local personality_name="$1"
    local config_file="$2"
    
    cat > "$config_file" << EOF
{
  "name": "Shellinator-$personality_name",
  "image": "ubuntu:22.04",
  "features": {
    "${REGISTRY_URL:-registry.example.com}/features/001-dev-packages:latest": {},
    "${REGISTRY_URL:-registry.example.com}/features/002-user-setup:latest": {},
    "${REGISTRY_URL:-registry.example.com}/features/babaji-config:latest": {},
    "${REGISTRY_URL:-registry.example.com}/features/003-zsh-setup:latest": {},
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/devcontainers/features/sshd:1": {
      "version": "latest"
    }
  },
  "remoteUser": "babaji",
  "containerEnv": {
    "HOME": "/home/babaji",
    "DEVCONTAINER_PERSONALITY": "$personality_name",
    "DEVCONTAINER_ROLE": "active"
  },
  "workspaceMount": "source=\${localWorkspaceFolder},target=/workspaces/shellinator-reloaded,type=bind",
  "workspaceFolder": "/workspaces/shellinator-reloaded",
  "mounts": [
    "source=\${localWorkspaceFolder}/local-deployment/coordination,target=/coordination,type=bind"
  ],
  "forwardPorts": [2222],
  "postCreateCommand": "sudo usermod -s /bin/zsh babaji && sudo chown -R babaji:babaji /home/babaji",
  "shutdownAction": "none",
  "postStartCommand": "echo 'Dev container started. Welcome to $personality_name personality!'",
  "postAttachCommand": "echo 'Attached to $personality_name personality.'"
}
EOF
}

# Placeholder functions for menu completeness
personality_remove_menu() {
    style_warning "🚧 Remove personality functionality coming soon..."
    read -p "Press Enter to continue..." -r
}

personality_edit_menu() {
    style_warning "🚧 Edit personality functionality coming soon..."
    read -p "Press Enter to continue..." -r
}

personality_rebuild_menu() {
    style_warning "🚧 Rebuild personality functionality coming soon..."
    read -p "Press Enter to continue..." -r
}

personality_create_branch() {
    style_warning "🚧 Branch creation functionality coming soon..."
    read -p "Press Enter to continue..." -r
}

personality_manage_branches() {
    style_warning "🚧 Branch management functionality coming soon..."
    read -p "Press Enter to continue..." -r
}

personality_system_settings() {
    style_warning "🚧 System settings functionality coming soon..."
    read -p "Press Enter to continue..." -r
}

personality_create_web_config() {
    personality_create_minimal_config "$1" "$2"
}

personality_create_devops_config() {
    personality_create_minimal_config "$1" "$2"
}

personality_create_ai_config() {
    personality_create_python_config "$1" "$2"
}

personality_create_custom_config() {
    personality_create_minimal_config "$1" "$2"
}