#!/usr/bin/env zsh

# SSH Service Management Module for Babaji Configuration Utility
# Provides SSH service verification, start/restart, and configuration management

# Source common functions
if [ -f "/usr/local/lib/babaji-config/lib/common.sh" ]; then
    source "/usr/local/lib/babaji-config/lib/common.sh"
else
    echo "Error: Cannot find common.sh library"
    exit 1
fi

ssh_menu() {
    while true; do
        show_header "🔐 SSH Service Management" "Secure Shell Service Control"
        
        echo ""
        echo "  1) Check SSH Service Status"
        echo "  2) Start SSH Service"
        echo "  3) Restart SSH Service"
        echo "  4) Stop SSH Service"
        echo "  5) Verify SSH Configuration"
        echo "  6) Reset SSH Configuration"
        echo "  7) View SSH Logs"
        echo "  8) Test SSH Connection"
        echo "  9) Back to Main Menu"
        echo ""
        
        prompt_input "Select an option [1-9]: " choice
        
        case $choice in
            1) ssh_status ;;
            2) ssh_start ;;
            3) ssh_restart ;;
            4) ssh_stop ;;
            5) ssh_verify_config ;;
            6) ssh_reset_config ;;
            7) ssh_view_logs ;;
            8) ssh_test_connection ;;
            9) break ;;
            *) 
                show_error "❌ Invalid option. Please select 1-9."
                pause_for_input
                ;;
        esac
    done
}

ssh_status() {
    show_section "📊 SSH Service Status Check"
    
    echo "🔍 Checking SSH daemon processes..."
    if pgrep -f "sshd.*2222" >/dev/null 2>&1; then
        echo "✅ SSH daemon is running on port 2222"
        ssh_pid=$(pgrep -f "sshd.*2222" | head -1)
        echo "   PID: $ssh_pid"
    else
        echo "❌ SSH daemon is not running on port 2222"
    fi
    
    echo ""
    echo "🔍 Checking SSH port status..."
    if netstat -tlnp 2>/dev/null | grep -q ":2222 "; then
        echo "✅ Port 2222 is listening"
        netstat -tlnp 2>/dev/null | grep ":2222 "
    else
        echo "❌ Port 2222 is not listening"
    fi
    
    echo ""
    echo "🔍 Checking SSH configuration..."
    local runtime_user=$(get_runtime_user)
    if [ -f "/etc/ssh/sshd_config.d/${runtime_user}.conf" ]; then
        echo "✅ SSH configuration exists for user '${runtime_user}'"
    else
        echo "❌ SSH configuration missing for user '${runtime_user}'"
    fi
    
    echo ""
    echo "🔍 Checking SSH host keys..."
    if [ -f /etc/ssh/ssh_host_rsa_key ]; then
        echo "✅ SSH host keys exist"
    else
        echo "❌ SSH host keys missing"
    fi
    
    pause_for_input
}

ssh_start() {
    show_section "🚀 Starting SSH Service"
    
    if pgrep -f "sshd.*2222" >/dev/null 2>&1; then
        echo "✅ SSH service is already running"
        pause_for_input
        return 0
    fi
    
    echo "🔧 Starting SSH daemon on port 2222..."
    
    # Ensure directories exist
    sudo mkdir -p /var/run/sshd
    sudo mkdir -p /var/log
    
    # Ensure SSH host keys exist
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        echo "🔑 Generating SSH host keys..."
        sudo ssh-keygen -A 2>/dev/null || echo "⚠️  SSH key generation failed"
    fi
    
    # Start SSH daemon
    if sudo /usr/sbin/sshd -f /etc/ssh/sshd_config -p 2222 -D & then
        sleep 2
        if pgrep -f "sshd.*2222" >/dev/null 2>&1; then
            echo "✅ SSH service started successfully"
        else
            echo "❌ SSH service failed to start"
        fi
    else
        echo "❌ Failed to start SSH service"
    fi
    
    pause_for_input
}

ssh_restart() {
    show_section "🔄 Restarting SSH Service"
    
    echo "🛑 Stopping existing SSH processes..."
    sudo pkill -f "sshd.*2222" 2>/dev/null || echo "No SSH processes found"
    sleep 1
    
    ssh_start
}

ssh_stop() {
    show_section "🛑 Stopping SSH Service"
    
    if ! pgrep -f "sshd.*2222" >/dev/null 2>&1; then
        echo "✅ SSH service is not running"
        pause_for_input
        return 0
    fi
    
    echo "🛑 Stopping SSH daemon..."
    sudo pkill -f "sshd.*2222"
    sleep 1
    
    if ! pgrep -f "sshd.*2222" >/dev/null 2>&1; then
        echo "✅ SSH service stopped successfully"
    else
        echo "❌ SSH service may still be running"
    fi
    
    pause_for_input
}

ssh_verify_config() {
    show_section "🔍 SSH Configuration Verification"
    
    echo "📝 Testing SSH configuration syntax..."
    if sudo /usr/sbin/sshd -t -f /etc/ssh/sshd_config 2>/dev/null; then
        echo "✅ SSH configuration is valid"
    else
        echo "❌ SSH configuration has errors:"
        sudo /usr/sbin/sshd -t -f /etc/ssh/sshd_config
    fi
    
    echo ""
    local runtime_user=$(get_runtime_user)
    echo "📋 Current SSH configuration for '${runtime_user}':"
    if [ -f "/etc/ssh/sshd_config.d/${runtime_user}.conf" ]; then
        cat "/etc/ssh/sshd_config.d/${runtime_user}.conf"
    else
        echo "❌ SSH configuration not found for user '${runtime_user}'"
    fi
    
    pause_for_input
}

ssh_reset_config() {
    show_section "🔄 Reset SSH Configuration"
    
    prompt_confirm "This will reset SSH configuration to defaults. Continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "❌ SSH configuration reset cancelled"
        pause_for_input
        return 0
    fi
    
    echo "🔧 Resetting SSH configuration..."
    
    local runtime_user=$(get_runtime_user)
    # Create fresh SSH config for runtime user
    sudo tee "/etc/ssh/sshd_config.d/${runtime_user}.conf" >/dev/null << EOF
# Runtime SSH Configuration for ${runtime_user}
Port 2222
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
PidFile /var/run/sshd-${runtime_user}.pid
EOF
    
    echo "✅ SSH configuration reset complete"
    echo "🔄 Restarting SSH service with new configuration..."
    
    ssh_restart
}

ssh_view_logs() {
    show_section "📋 SSH Service Logs"
    
    echo "📄 Recent SSH-related system logs:"
    echo "=================================="
    
    # Try different log locations
    if [ -f /var/log/auth.log ]; then
        tail -20 /var/log/auth.log | grep -i ssh || echo "No SSH entries in auth.log"
    elif [ -f /var/log/secure ]; then
        tail -20 /var/log/secure | grep -i ssh || echo "No SSH entries in secure log"
    else
        echo "⚠️  System logs not available in container environment"
    fi
    
    echo ""
    echo "📄 Current SSH processes:"
    ps aux | grep -E "(sshd|ssh)" | grep -v grep || echo "No SSH processes found"
    
    pause_for_input
}

ssh_test_connection() {
    show_section "🧪 SSH Connection Test"
    
    echo "🔧 Testing SSH connection to localhost..."
    echo "Note: This will test if SSH is accepting connections"
    echo ""
    
    # Test SSH port connectivity
    if timeout 3 bash -c "</dev/tcp/localhost/2222" 2>/dev/null; then
        echo "✅ SSH port 2222 is accepting connections"
    else
        echo "❌ SSH port 2222 is not responding"
    fi
    
    echo ""
    local runtime_user=$(get_runtime_user)
    echo "🧪 Testing SSH authentication (will prompt for password):"
    echo "Username: ${runtime_user}"
    echo "Password: ${runtime_user}"
    echo ""
    
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 "${runtime_user}@localhost" -p 2222 "echo '✅ SSH authentication successful'; whoami; exit" || echo "❌ SSH authentication failed"
    
    pause_for_input
}

# Export functions for external use
export -f ssh_menu ssh_status ssh_start ssh_restart ssh_stop ssh_verify_config ssh_reset_config ssh_view_logs ssh_test_connection