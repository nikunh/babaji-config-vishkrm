#!/usr/bin/env zsh
# Post-Create Hook for Babaji Configuration Utility
# Automatically starts SSH service and configures environment after container creation

set -e

echo "🚀 Babaji Configuration: Post-create initialization..."

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if running as root or with sudo capability
if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
    SUDO_CMD=""
    if [ "$EUID" -ne 0 ]; then
        SUDO_CMD="sudo"
    fi
else
    log "⚠️  Warning: Cannot run privileged commands, some services may not start automatically"
    SUDO_CMD=""
fi

# 1. SSH Service Configuration and Startup
log "🔧 Configuring SSH service..."

# Ensure SSH directories exist
if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
    $SUDO_CMD mkdir -p /var/run/sshd
    $SUDO_CMD mkdir -p /var/log
    
    # Configure SSH if not already done
    if [ ! -f /etc/ssh/sshd_config.d/babaji.conf ]; then
        $SUDO_CMD tee /etc/ssh/sshd_config.d/babaji.conf >/dev/null << 'EOF'
# Babaji SSH Configuration
Port 2222
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
PidFile /var/run/sshd-babaji.pid
EOF
        log "✅ SSH configuration created"
    fi
    
    # Ensure SSH host keys exist
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        $SUDO_CMD ssh-keygen -A 2>/dev/null || log "⚠️  SSH host key generation failed"
    fi
    
    # Start SSH service with proper configuration
    if $SUDO_CMD /usr/sbin/sshd -t -f /etc/ssh/sshd_config 2>/dev/null; then
        if ! pgrep -f "sshd.*2222" >/dev/null; then
            # Kill any existing SSH processes on port 2222
            pkill -f "sshd.*2222" 2>/dev/null || true
            sleep 1
            # Start SSH daemon with explicit config and proper background process
            $SUDO_CMD /usr/sbin/sshd -f /etc/ssh/sshd_config -p 2222 -D &
            # Wait for SSH to start
            for i in {1..10}; do
                if pgrep -f "sshd.*2222" >/dev/null; then
                    log "✅ SSH service started on port 2222"
                    break
                elif [ $i -eq 10 ]; then
                    log "❌ SSH service failed to start after 10 attempts"
                fi
                sleep 1
            done
        else
            log "✅ SSH service already running on port 2222"
        fi
    else
        log "❌ SSH configuration test failed"
    fi
    
    # Ensure babaji user can SSH
    if id "babaji" >/dev/null 2>&1; then
        # Ensure babaji user has a password set
        if [ -n "$SUDO_CMD" ] || [ "$EUID" -eq 0 ]; then
            # Set babaji password to "babaji" if not already set
            echo "babaji:babaji" | $SUDO_CMD chpasswd 2>/dev/null || log "⚠️  Failed to set babaji password"
            # Ensure babaji user is not locked
            $SUDO_CMD passwd -u babaji 2>/dev/null || log "⚠️  Failed to unlock babaji user"
            # Ensure babaji has proper shell (zsh for P10k compatibility)
            $SUDO_CMD usermod -s /usr/bin/zsh babaji 2>/dev/null || log "⚠️  Failed to set babaji shell"
            log "✅ Babaji user configured for SSH access"
        fi
    else
        log "⚠️  Babaji user not found - SSH may not work properly"
    fi
fi

# 2. Environment Variables Setup
log "🌍 Setting up environment variables..."

# Note: PATH and environment setup is now handled by individual feature fragments
# in ~/.ohmyzsh_source_load_scripts/*.zshrc files to avoid conflicts with zsh setup

# Verify that development tools are properly configured
log "🔍 Verifying development tool availability..."

# Check Go
if [ -d "/usr/local/go/bin" ]; then
    log "✅ Go found at /usr/local/go/bin"
else
    log "⚠️  Go not found at expected location"
fi

# Check Conda
if [ -d "/opt/conda/bin" ] || [ -d "$HOME/miniconda/bin" ]; then
    log "✅ Conda found"
else
    log "⚠️  Conda not found at expected locations"
fi

# Check Node
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version 2>/dev/null || echo "unknown")
    log "✅ Node.js available: $node_version"
else
    log "⚠️  Node.js not found"
fi

# Verify shell configuration fragments are loaded
for user_home in /home/*; do
    if [ -d "$user_home/.ohmyzsh_source_load_scripts" ]; then
        username=$(basename "$user_home")
        fragment_count=$(ls -1 "$user_home/.ohmyzsh_source_load_scripts"/.*zshrc 2>/dev/null | wc -l)
        log "✅ Found $fragment_count shell configuration fragments for user $username"
    fi
done

# 3. Service Status Verification
log "🔍 Verifying service status..."

# Check SSH service
if pgrep -f "sshd.*2222" >/dev/null; then
    ssh_status="✅ RUNNING"
else
    ssh_status="❌ NOT RUNNING"
fi

# Check essential tools
go_status="❌ NOT FOUND"
if command -v go >/dev/null 2>&1; then
    go_version=$(go version 2>/dev/null | cut -d' ' -f3 2>/dev/null || echo "unknown")
    go_status="✅ AVAILABLE ($go_version)"
fi

node_status="❌ NOT FOUND"
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version 2>/dev/null || echo "unknown")
    node_status="✅ AVAILABLE ($node_version)"
fi

# 4. Create service status file for health checks
status_file="/tmp/babaji-services.status"
cat > "$status_file" << EOF
# Babaji Services Status - $(date)
SSH_SERVICE=$ssh_status
GO_TOOL=$go_status
NODE_TOOL=$node_status
POST_CREATE_COMPLETED=✅ $(date)
EOF

log "📊 Service Status Summary:"
log "   SSH Service (port 2222): $ssh_status"
log "   Go Development: $go_status"
log "   Node.js Development: $node_status"

# 5. Run quick health check to verify everything
if command -v health-check >/dev/null 2>&1; then
    log "🏥 Running post-create health check..."
    health-check -q || log "⚠️  Some health check issues detected (this is normal during first startup)"
else
    log "⚠️  Health check tool not available yet"
fi

log "🎉 Babaji Configuration post-create setup completed!"

# Display helpful information
cat << 'EOF'

🔗 Connection Information:
   SSH Access: ssh babaji@<container-ip> -p 2222
   Password: babaji
   
🛠️  Development Tools:
   - Node.js: Available globally
   - Go: Available with GOPATH configured
   - Docker: Available for container operations
   
📋 Quick Commands:
   babaji-config  - Open configuration utility
   health-check -f  - Full system health check
   health-check -q  - Quick essential tools check

EOF

exit 0