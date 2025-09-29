#!/bin/bash

# Babaji Configuration Utility - Runtime Security Monitor
# Monitors and protects against tampering attempts

BABAJI_CONFIG_DIR="/usr/local/lib/babaji-config"
BABAJI_BIN_DIR="/usr/local/bin"
WORKSPACE_SOURCE="/workspaces/shellinator-reloaded/.devcontainer/features/babaji-config/src"

# Function to verify file integrity
verify_integrity() {
    local file="$1"
    local expected_hash="$2"
    
    if [ -f "$file" ]; then
        local current_hash=$(sha256sum "$file" | cut -d' ' -f1)
        if [ "$current_hash" != "$expected_hash" ]; then
            echo "SECURITY ALERT: File $file has been tampered with!"
            return 1
        fi
    else
        echo "SECURITY ALERT: File $file is missing!"
        return 1
    fi
    return 0
}

# Function to restore files from source
restore_from_source() {
    echo "SECURITY: Restoring babaji-config from source..."
    
    # Remove any immutable attributes first
    if command -v chattr >/dev/null 2>&1; then
        find "$BABAJI_CONFIG_DIR" -type f -exec chattr -i {} \; 2>/dev/null || true
        chattr -i "$BABAJI_BIN_DIR/babaji-config" 2>/dev/null || true
        chattr -i "$BABAJI_BIN_DIR/connect-nas" 2>/dev/null || true
    fi
    
    # Restore from workspace source
    if [ -d "$WORKSPACE_SOURCE" ]; then
        # Re-run the install script to restore clean state
        cd "$(dirname "$WORKSPACE_SOURCE")"
        sudo ./install.sh
        echo "SECURITY: System files restored from source"
    else
        echo "SECURITY ERROR: Source directory not found at $WORKSPACE_SOURCE"
        exit 1
    fi
}

# Function to check for mount tampering
check_mount_tampering() {
    # Check if any suspicious mounts are overlaying our directories
    if mount | grep -E "(babaji-config|\.local/bin|\.local/lib)" | grep -v "type ext4\|type xfs\|type btrfs"; then
        echo "SECURITY ALERT: Suspicious mount detected over babaji-config directories!"
        echo "Mount information:"
        mount | grep -E "(babaji-config|\.local/bin|\.local/lib)"
        return 1
    fi
    return 0
}

# Function to monitor file changes
monitor_files() {
    # Monitor babaji-config system directories and user workspace separately
    echo "SECURITY: Starting file integrity monitoring..."
    
    # Monitor system files (should never change)
    inotifywait -m -r -e modify,delete,create,move "$BABAJI_CONFIG_DIR" "$BABAJI_BIN_DIR/babaji-config" "$BABAJI_BIN_DIR/connect-nas" 2>/dev/null | while read path action file; do
        echo "SECURITY ALERT: System file change detected: $action on $path$file"
        # Auto-restore on system file tampering
        restore_from_source
    done &
    
    # Monitor user workspace (alert but don't restore)
    if [ -d "$HOME/.local/bin" ]; then
        inotifywait -m -r -e modify,delete,create,move "$HOME/.local/bin" 2>/dev/null | while read path action file; do
            echo "USER ACTIVITY: User workspace change: $action on $path$file"
            # Just log user activity, don't restore
        done &
    fi
    
    echo $! > /tmp/babaji-monitor.pid
}

# Main security check function
security_check() {
    echo "SECURITY: Running babaji-config security check..."
    
    # Check for mount tampering
    if ! check_mount_tampering; then
        echo "SECURITY: Mount tampering detected, restoring files..."
        restore_from_source
    fi
    
    # Verify file permissions
    if [ -f "$BABAJI_BIN_DIR/babaji-config" ]; then
        local perms=$(stat -c "%a" "$BABAJI_BIN_DIR/babaji-config")
        if [ "$perms" != "555" ]; then
            echo "SECURITY: Incorrect permissions on babaji-config ($perms), restoring..."
            restore_from_source
        fi
    fi
    
    # Check for immutable attribute removal
    if command -v lsattr >/dev/null 2>&1; then
        if [ -f "$BABAJI_BIN_DIR/babaji-config" ]; then
            if ! lsattr "$BABAJI_BIN_DIR/babaji-config" | grep -q "i"; then
                echo "SECURITY: Immutable attribute removed, restoring..."
                restore_from_source
            fi
        fi
    fi
    
    echo "SECURITY: Security check completed"
}

# Export functions for use in other scripts
export -f verify_integrity
export -f restore_from_source
export -f check_mount_tampering
export -f security_check

# Run security check if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    security_check
fi
