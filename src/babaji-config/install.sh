#!/bin/sh
set -e

# Logging mechanism for debugging
LOG_FILE="/tmp/babaji-config-install.log"
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $*" >> "$LOG_FILE"
}

# Initialize logging
log_debug "=== BABAJI-CONFIG INSTALL STARTED ==="
log_debug "Script path: $0"
log_debug "PWD: $(pwd)"
log_debug "Environment: USER=$USER HOME=$HOME"

# Babaji Configuration Utility - System Install Script
# Installs system tools to /usr/local (immutable) and preserves $HOME/.local for user tools

echo "Installing Babaji Configuration Utility (System Installation)..."
# Token fix test - trigger automation Mon Sep 23 22:14:00 BST 2025

# System installation directories (immutable)
SYSTEM_INSTALL_DIR="/usr/local/lib/babaji-config"
SYSTEM_BIN_DIR="/usr/local/bin"

# User directories (preserved for user tools)
# Handle cases where HOME might not be set during build
if [ -z "$HOME" ]; then
    HOME="/home/babaji"
fi

# Create user's local directory structure but don't install system tools there
mkdir -p "$HOME/.local"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/lib"

# Ensure user's local directories are owned by babaji
if [ "$USER" != "babaji" ] && [ -d "/home/babaji" ]; then
    chown -R babaji:babaji /home/babaji/.local 2>/dev/null || true
fi

# Create system installation directories
mkdir -p "$SYSTEM_INSTALL_DIR"
mkdir -p "$SYSTEM_INSTALL_DIR/lib"
mkdir -p "$SYSTEM_INSTALL_DIR/core"
mkdir -p "$SYSTEM_INSTALL_DIR/modules"

# Copy source files to system installation directory
SCRIPT_DIR="$(dirname "$0")"
if [ -d "$SCRIPT_DIR/src" ]; then
    # Remove existing system installation to avoid conflicts
    rm -rf "$SYSTEM_INSTALL_DIR"
    
    # Recreate clean system directory structure
    mkdir -p "$SYSTEM_INSTALL_DIR"
    mkdir -p "$SYSTEM_INSTALL_DIR/lib"
    mkdir -p "$SYSTEM_INSTALL_DIR/core"
    mkdir -p "$SYSTEM_INSTALL_DIR/modules"
    
    # Copy individual files to avoid recursive issues
    if [ -f "$SCRIPT_DIR/src/babaji-config" ]; then
        cp "$SCRIPT_DIR/src/babaji-config" "$SYSTEM_INSTALL_DIR/"
    fi
    if [ -f "$SCRIPT_DIR/src/babaji-config-dev" ]; then
        cp "$SCRIPT_DIR/src/babaji-config-dev" "$SYSTEM_INSTALL_DIR/"
    fi
    if [ -f "$SCRIPT_DIR/src/health-check" ]; then
        cp "$SCRIPT_DIR/src/health-check" "$SYSTEM_INSTALL_DIR/"
    fi
    if [ -f "$SCRIPT_DIR/src/post-create.sh" ]; then
        cp "$SCRIPT_DIR/src/post-create.sh" "$SYSTEM_INSTALL_DIR/"
    fi
    if [ -f "$SCRIPT_DIR/src/ssh-monitor.sh" ]; then
        cp "$SCRIPT_DIR/src/ssh-monitor.sh" "$SYSTEM_INSTALL_DIR/"
    fi
    
    # Copy directory contents, not directories themselves
    if [ -d "$SCRIPT_DIR/src/lib" ]; then
        cp "$SCRIPT_DIR/src/lib"/* "$SYSTEM_INSTALL_DIR/lib/" 2>/dev/null || true
    fi
    if [ -d "$SCRIPT_DIR/src/core" ]; then
        cp "$SCRIPT_DIR/src/core"/* "$SYSTEM_INSTALL_DIR/core/" 2>/dev/null || true
    fi
    if [ -d "$SCRIPT_DIR/src/modules" ]; then
        cp "$SCRIPT_DIR/src/modules"/* "$SYSTEM_INSTALL_DIR/modules/" 2>/dev/null || true
    fi
    
    echo "System source files copied successfully"
else
    echo "Error: Source directory not found at $SCRIPT_DIR/src"
    exit 1
fi

# Make all shell scripts executable and apply security hardening
find "$SYSTEM_INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
if [ -f "$SYSTEM_INSTALL_DIR/babaji-config" ]; then
    chmod +x "$SYSTEM_INSTALL_DIR/babaji-config"
    echo "Made babaji-config executable"
else
    echo "Error: babaji-config not found after copy"
    exit 1
fi

if [ -f "$SYSTEM_INSTALL_DIR/health-check" ]; then
    chmod +x "$SYSTEM_INSTALL_DIR/health-check"
    echo "Made health-check executable"
fi

if [ -f "$SYSTEM_INSTALL_DIR/post-create.sh" ]; then
    chmod +x "$SYSTEM_INSTALL_DIR/post-create.sh"
    echo "Made post-create.sh executable"
fi

if [ -f "$SYSTEM_INSTALL_DIR/ssh-monitor.sh" ]; then
    chmod +x "$SYSTEM_INSTALL_DIR/ssh-monitor.sh"
    echo "Made ssh-monitor.sh executable"
fi

# Security hardening - make system files immutable and read-only
echo "Applying security hardening to system files..."

# Set strict permissions (read-only for all, executable for scripts)
find "$SYSTEM_INSTALL_DIR" -type f -exec chmod 444 {} \;
find "$SYSTEM_INSTALL_DIR" -type d -exec chmod 555 {} \;

# Make executables executable but still read-only
find "$SYSTEM_INSTALL_DIR" -type f -name "*.sh" -exec chmod 555 {} \;
if [ -f "$SYSTEM_INSTALL_DIR/babaji-config" ]; then
    chmod 555 "$SYSTEM_INSTALL_DIR/babaji-config"
fi
if [ -f "$SYSTEM_INSTALL_DIR/health-check" ]; then
    chmod 555 "$SYSTEM_INSTALL_DIR/health-check"
fi
if [ -f "$SYSTEM_INSTALL_DIR/post-create.sh" ]; then
    chmod 555 "$SYSTEM_INSTALL_DIR/post-create.sh"
fi
if [ -f "$SYSTEM_INSTALL_DIR/ssh-monitor.sh" ]; then
    chmod 555 "$SYSTEM_INSTALL_DIR/ssh-monitor.sh"
fi

# Apply immutable attribute if available (requires e2fsprogs)
if command -v chattr >/dev/null 2>&1; then
    find "$SYSTEM_INSTALL_DIR" -type f -exec chattr +i {} \; 2>/dev/null || true
    echo "Applied immutable attributes to system files"
fi

# Set SELinux context if available
if command -v semanage >/dev/null 2>&1; then
    find "$SYSTEM_INSTALL_DIR" -type f -exec chcon -t bin_t {} \; 2>/dev/null || true
    echo "Applied SELinux security context"
fi

# Install system executables to /usr/local/bin (immutable)
if cp "$SYSTEM_INSTALL_DIR/babaji-config" "$SYSTEM_BIN_DIR/babaji-config"; then
    chmod 555 "$SYSTEM_BIN_DIR/babaji-config"
    # Apply immutable attribute if available
    if command -v chattr >/dev/null 2>&1; then
        chattr +i "$SYSTEM_BIN_DIR/babaji-config" 2>/dev/null || true
    fi
    echo "System executable installed at $SYSTEM_BIN_DIR/babaji-config (immutable)"
else
    echo "Error: Failed to install system executable"
    exit 1
fi


# Install health-check script to system bin (immutable)
if [ -f "$SYSTEM_INSTALL_DIR/health-check" ] && cp "$SYSTEM_INSTALL_DIR/health-check" "$SYSTEM_BIN_DIR/health-check"; then
    chmod 555 "$SYSTEM_BIN_DIR/health-check"
    # Apply immutable attribute if available
    if command -v chattr >/dev/null 2>&1; then
        chattr +i "$SYSTEM_BIN_DIR/health-check" 2>/dev/null || true
    fi
    echo "Health check system executable installed at $SYSTEM_BIN_DIR/health-check (immutable)"
else
    echo "Warning: Failed to install health-check executable"
fi

# Install ssh-monitor script to system bin (immutable)
if [ -f "$SYSTEM_INSTALL_DIR/ssh-monitor.sh" ] && cp "$SYSTEM_INSTALL_DIR/ssh-monitor.sh" "$SYSTEM_BIN_DIR/ssh-monitor"; then
    chmod 555 "$SYSTEM_BIN_DIR/ssh-monitor"
    # Apply immutable attribute if available
    if command -v chattr >/dev/null 2>&1; then
        chattr +i "$SYSTEM_BIN_DIR/ssh-monitor" 2>/dev/null || true
    fi
    echo "SSH monitor system executable installed at $SYSTEM_BIN_DIR/ssh-monitor (immutable)"
else
    echo "Warning: Failed to install ssh-monitor executable"
fi

# Final ownership fix - ensure user's .local directory is owned by babaji (but empty of system tools)
if [ "$USER" != "babaji" ] && [ -d "/home/babaji" ]; then
    # We're running as root during build, set ownership for babaji
    chown -R babaji:babaji /home/babaji/.local 2>/dev/null || true
    echo "Set ownership of user .local directory for babaji user"
fi

echo "Babaji Configuration Utility installed successfully!"
echo ""
echo "📁 System Installation Structure (Immutable):"
echo "   $SYSTEM_BIN_DIR/babaji-config (system executable)"
echo "   $SYSTEM_BIN_DIR/health-check (health check executable)"
echo "   $SYSTEM_INSTALL_DIR/ (immutable system files)"
echo "   ├── lib/common.sh (shared utilities)"
echo "   ├── core/menu.sh (core menu system)"
echo "   └── modules/ (feature modules loaded on-demand)"
echo "       ├── verification.sh (system verification)"
echo "       ├── environment.sh (environment settings)"
echo "       └── system.sh (system information)"
echo ""
echo "� User Workspace (Writable):"
echo "   $HOME/.local/bin/ (user tools - writable)"
echo "   $HOME/.local/lib/ (user libraries - writable)"
echo "   Note: User tools will be lost on container rebuild"
echo ""
echo "🚀 Usage:"
echo "   babaji-config  - Start the configuration utility"
echo "   health-check   - Run container health check (options: -q, -f, -j, -h)"
echo ""
echo "✨ Features:"
echo "   - Immutable system tools: Protected from tampering"
echo "   - User workspace: Available for personal tools"
echo "   - Lazy loading: Modules are only loaded when accessed"
echo "   - Modular design: Each feature is in its own module"
echo "   - Security hardened: System files are read-only and immutable"
echo "   - Auto-service startup: SSH and development services start automatically"
echo ""
echo "🔒 Security Model:"
echo "   - System tools in /usr/local (immutable, tamper-resistant)"
echo "   - User tools in ~/.local (ephemeral, writable)"
echo "   - Clear separation of concerns"

log_debug "=== BABAJI-CONFIG INSTALL COMPLETED ==="
# Auto-trigger build Tue Sep 23 20:02:57 BST 2025
