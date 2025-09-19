#!/bin/bash

# Babaji Configuration Utility - Heartbeat Management Module
# Monitor and manage DevContainer heartbeat communication with manager

# Load common library
source "$BABAJI_CONFIG_DIR/lib/common.sh"

# Configuration
COORDINATION_DIR="${COORDINATION_DIR:-/coordination}"
HEARTBEAT_CLIENT_PATH="/usr/local/bin/heartbeat-client.sh"
HEARTBEAT_INTERVAL="${HEARTBEAT_INTERVAL:-30}"
MANAGER_TIMEOUT="${MANAGER_TIMEOUT:-120}"

# Get current container information
get_container_info() {
    local container_name=$(hostname)
    local image_id=$(docker inspect $(hostname) --format '{{.Image}}' 2>/dev/null | cut -d: -f2 | head -c 12)
    
    # Fallback image ID detection if docker inspect fails
    if [[ -z "$image_id" ]]; then
        image_id=$(cat /proc/self/mountinfo | grep '/docker/containers' | head -1 | sed 's/.*containers\/\([^\/]*\).*/\1/' | head -c 12)
    fi
    
    # Final fallback - use hostname as image ID
    if [[ -z "$image_id" ]]; then
        image_id=$(hostname | head -c 12)
    fi
    
    echo "$container_name:$image_id"
}

# Get current IP address
get_container_ip() {
    # Try to get compose network IP first
    local compose_ip=$(ip route get 172.18.0.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    
    # Fallback to default gateway route
    if [[ -z "$compose_ip" ]]; then
        compose_ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi
    
    # Final fallback to eth0
    if [[ -z "$compose_ip" ]]; then
        compose_ip=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -1)
    fi
    
    echo "$compose_ip"
}

# Check heartbeat status
get_heartbeat_status() {
    local container_info=$(get_container_info)
    local image_id=$(echo "$container_info" | cut -d: -f2)
    local heartbeat_file="$COORDINATION_DIR/container-${image_id}.heartbeat"
    local status_file="$COORDINATION_DIR/manager-${image_id}.status"
    
    local status="inactive"
    local last_heartbeat="never"
    local manager_session="unknown"
    local manager_status="unknown"
    local communication_age=0
    
    # Check heartbeat file
    if [[ -f "$heartbeat_file" ]]; then
        local heartbeat_data=$(cat "$heartbeat_file" 2>/dev/null)
        local heartbeat_timestamp=$(echo "$heartbeat_data" | cut -d: -f2)
        
        if [[ -n "$heartbeat_timestamp" ]]; then
            last_heartbeat=$(date -d "@$heartbeat_timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "invalid")
            local current_time=$(date +%s)
            local heartbeat_age=$((current_time - heartbeat_timestamp))
            
            if [[ $heartbeat_age -lt 60 ]]; then
                status="active"
            elif [[ $heartbeat_age -lt 300 ]]; then
                status="stale"
            else
                status="expired"
            fi
        fi
    fi
    
    # Check manager response
    if [[ -f "$status_file" ]]; then
        local response=$(cat "$status_file" 2>/dev/null)
        local response_timestamp=$(echo "$response" | cut -d: -f1)
        manager_status=$(echo "$response" | cut -d: -f2)
        manager_session=$(echo "$response" | cut -d: -f3)
        
        if [[ -n "$response_timestamp" ]]; then
            local current_time=$(date +%s)
            communication_age=$((current_time - response_timestamp))
        fi
    fi
    
    echo "$status:$last_heartbeat:$manager_session:$manager_status:$communication_age"
}

# Display heartbeat information
show_heartbeat_info() {
    local container_info=$(get_container_info)
    local container_name=$(echo "$container_info" | cut -d: -f1)
    local image_id=$(echo "$container_info" | cut -d: -f2)
    local container_ip=$(get_container_ip)
    local status_info=$(get_heartbeat_status)
    
    local status=$(echo "$status_info" | cut -d: -f1)
    local last_heartbeat=$(echo "$status_info" | cut -d: -f2)
    local manager_session=$(echo "$status_info" | cut -d: -f3)
    local manager_status=$(echo "$status_info" | cut -d: -f4)
    local communication_age=$(echo "$status_info" | cut -d: -f5)
    
    style_subheader "💓 DevContainer Heartbeat Status" "" "#ff6b6b"
    
    echo ""
    style_info "Container Information:"
    echo "  📦 Container Name: $container_name"
    echo "  🆔 Session ID: $image_id"
    echo "  🌐 IP Address: ${container_ip:-unknown}"
    echo ""
    
    style_info "Heartbeat Status:"
    case "$status" in
        "active")
            style_success "  💚 Status: ACTIVE - Communication healthy"
            ;;
        "stale")
            style_warning "  🟡 Status: STALE - Recent but not current"
            ;;
        "expired")
            style_error "  🔴 Status: EXPIRED - Heartbeat too old"
            ;;
        "inactive")
            style_error "  ⚫ Status: INACTIVE - No heartbeat detected"
            ;;
    esac
    echo "  🕐 Last Heartbeat: $last_heartbeat"
    echo ""
    
    style_info "Manager Communication:"
    if [[ "$manager_session" != "unknown" ]]; then
        echo "  🎯 Manager Session: $manager_session"
        echo "  📡 Manager Status: $manager_status"
        if [[ $communication_age -gt 0 ]]; then
            echo "  ⏰ Response Age: ${communication_age}s"
            if [[ $communication_age -lt $MANAGER_TIMEOUT ]]; then
                style_success "  ✅ Manager communication: HEALTHY"
            else
                style_warning "  ⚠️  Manager communication: TIMEOUT RISK"
            fi
        fi
    else
        style_error "  ❌ No manager communication detected"
    fi
    echo ""
    
    style_info "Configuration:"
    echo "  📁 Coordination Dir: $COORDINATION_DIR"
    echo "  ⏱️  Heartbeat Interval: ${HEARTBEAT_INTERVAL}s"
    echo "  ⏰ Manager Timeout: ${MANAGER_TIMEOUT}s"
}

# Check if heartbeat client is installed
check_heartbeat_client() {
    if [[ -f "$HEARTBEAT_CLIENT_PATH" ]]; then
        return 0
    else
        return 1
    fi
}

# Install heartbeat client
install_heartbeat_client() {
    style_subheader "📥 Installing Heartbeat Client" "" "#4ecdc4"
    
    local source_path="/workspaces/shellinator-reloaded/heartbeat-client.sh"
    
    if [[ -f "$source_path" ]]; then
        echo "📋 Copying heartbeat client from workspace..."
        sudo cp "$source_path" "$HEARTBEAT_CLIENT_PATH"
        sudo chmod +x "$HEARTBEAT_CLIENT_PATH"
        style_success "✅ Heartbeat client installed successfully"
    else
        style_error "❌ Source heartbeat client not found at $source_path"
        return 1
    fi
}

# Start heartbeat service
start_heartbeat_service() {
    if ! check_heartbeat_client; then
        style_warning "⚠️  Heartbeat client not found, installing..."
        if ! install_heartbeat_client; then
            return 1
        fi
    fi
    
    # Check if already running
    local existing_pid=$(pgrep -f "heartbeat-client.sh" | head -1)
    if [[ -n "$existing_pid" ]]; then
        style_warning "⚠️  Heartbeat service already running (PID: $existing_pid)"
        return 0
    fi
    
    style_subheader "🚀 Starting Heartbeat Service" "" "#4ecdc4"
    
    echo "📡 Launching heartbeat client in background..."
    nohup "$HEARTBEAT_CLIENT_PATH" > /tmp/heartbeat.log 2>&1 &
    local heartbeat_pid=$!
    
    sleep 2
    
    if kill -0 "$heartbeat_pid" 2>/dev/null; then
        style_success "✅ Heartbeat service started successfully (PID: $heartbeat_pid)"
        echo "📋 Log file: /tmp/heartbeat.log"
    else
        style_error "❌ Failed to start heartbeat service"
        return 1
    fi
}

# Stop heartbeat service
stop_heartbeat_service() {
    style_subheader "🛑 Stopping Heartbeat Service" "" "#ff6b6b"
    
    local pids=$(pgrep -f "heartbeat-client.sh")
    
    if [[ -n "$pids" ]]; then
        echo "🔄 Stopping heartbeat processes: $pids"
        kill $pids 2>/dev/null
        sleep 2
        
        # Force kill if still running
        local remaining=$(pgrep -f "heartbeat-client.sh")
        if [[ -n "$remaining" ]]; then
            echo "🔨 Force killing remaining processes: $remaining"
            kill -9 $remaining 2>/dev/null
        fi
        
        style_success "✅ Heartbeat service stopped"
    else
        style_info "ℹ️  No heartbeat service running"
    fi
}

# Show heartbeat logs
show_heartbeat_logs() {
    style_subheader "📋 Heartbeat Service Logs" "" "#45b7d1"
    
    if [[ -f "/tmp/heartbeat.log" ]]; then
        echo "🔍 Last 20 lines from heartbeat log:"
        echo ""
        tail -20 /tmp/heartbeat.log | while read line; do
            echo "  $line"
        done
    else
        style_info "ℹ️  No log file found at /tmp/heartbeat.log"
    fi
}

# Test heartbeat communication
test_heartbeat_communication() {
    style_subheader "🧪 Testing Heartbeat Communication" "" "#9b59b6"
    
    local container_info=$(get_container_info)
    local image_id=$(echo "$container_info" | cut -d: -f2)
    local container_ip=$(get_container_ip)
    
    if [[ -z "$container_ip" ]]; then
        style_error "❌ Cannot determine container IP address"
        return 1
    fi
    
    echo "📡 Sending test heartbeat..."
    local test_heartbeat="${container_ip}:$(date +%s):test_$(hostname)"
    echo "$test_heartbeat" > "$COORDINATION_DIR/container-${image_id}.heartbeat"
    
    echo "⏳ Waiting for manager response (5 seconds)..."
    sleep 5
    
    local status_file="$COORDINATION_DIR/manager-${image_id}.status"
    if [[ -f "$status_file" ]]; then
        local response=$(cat "$status_file")
        style_success "✅ Manager responded: $response"
    else
        style_warning "⚠️  No manager response detected"
        echo "   This could mean:"
        echo "   • Manager is not running"
        echo "   • Coordination folder not shared"
        echo "   • Manager heartbeat processing disabled"
    fi
}

# Heartbeat management menu
heartbeat_menu() {
    while true; do
        style_subheader "💓 Heartbeat Management" "DevContainer-Manager Communication" "#ff6b6b"
        
        local choice=$(choose_option "Select heartbeat operation:" \
            "📊 Show Heartbeat Status" \
            "🚀 Start Heartbeat Service" \
            "🛑 Stop Heartbeat Service" \
            "📋 View Heartbeat Logs" \
            "🧪 Test Communication" \
            "📥 Install/Update Client" \
            "🔄 Refresh Status" \
            "🔙 Back to Main Menu")
        
        case "$choice" in
            "📊 Show Heartbeat Status")
                show_heartbeat_info
                wait_for_user
                ;;
            "🚀 Start Heartbeat Service")
                start_heartbeat_service
                wait_for_user
                ;;
            "🛑 Stop Heartbeat Service")
                stop_heartbeat_service
                wait_for_user
                ;;
            "📋 View Heartbeat Logs")
                show_heartbeat_logs
                wait_for_user
                ;;
            "🧪 Test Communication")
                test_heartbeat_communication
                wait_for_user
                ;;
            "📥 Install/Update Client")
                install_heartbeat_client
                wait_for_user
                ;;
            "🔄 Refresh Status")
                # Just loop back to refresh the menu
                ;;
            "🔙 Back to Main Menu"|*)
                return 0
                ;;
        esac
    done
}