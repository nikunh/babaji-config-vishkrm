#!/bin/bash

# Babaji Configuration Utility - Verification Module
# System verification and validation functions

# Verification submenu
verification_menu() {
    while true; do
        style_subheader "🔍 System Verification" "Validate devcontainer setup and features" "#ff8800"
        
        local choice=$(choose_option "Select verification option:" \
            "✅ Run full verification" \
            "⚡ Quick health check" \
            "🔧 Check development tools" \
            "🐚 Check shell configuration" \
            "📦 Check packages" \
            "🌐 Check network tools" \
            "🔐 Check security tools" \
            "⬅️  Back to main menu")
        
        case "$choice" in
            "✅ Run full verification")
                run_full_verification
                ;;
            "⚡ Quick health check")
                quick_health_check
                ;;
            "🔧 Check development tools")
                check_dev_tools
                ;;
            "🐚 Check shell configuration")
                check_shell_config
                ;;
            "📦 Check packages")
                check_packages
                ;;
            "🌐 Check network tools")
                check_network_tools
                ;;
            "🔐 Check security tools")
                check_security_tools
                ;;
            "⬅️  Back to main menu"|*)
                return 0
                ;;
        esac
    done
}

# Quick health check for essential tools
quick_health_check() {
    style_subheader "⚡ Quick Health Check" "Essential tools and services status" "#00aaff"
    
    local status=()
    
    # Core development tools
    echo -e "${BLUE}Core Development Tools${NC}"
    local core_tools=("git" "node" "go" "python3" "docker" "kubectl" "terraform")
    for tool in "${core_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo "✅ $tool"
            status+=("pass")
        else
            echo "❌ $tool"
            status+=("fail")
        fi
    done
    
    # Essential services
    echo -e "\n${BLUE}Essential Services${NC}"
    if pgrep sshd > /dev/null; then
        echo "✅ SSH daemon"
        status+=("pass")
    else
        echo "❌ SSH daemon"
        status+=("fail")
    fi
    
    # Shell environment
    echo -e "\n${BLUE}Shell Environment${NC}"
    if command -v zsh &>/dev/null; then
        echo "✅ Zsh"
        status+=("pass")
    else
        echo "❌ Zsh"
        status+=("fail")
    fi
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "✅ Oh My Zsh"
        status+=("pass")
    else
        echo "❌ Oh My Zsh"
        status+=("fail")
    fi
    
    # PATH check
    if echo "$PATH" | grep -q "/usr/local/go/bin"; then
        echo "✅ Go in PATH"
        status+=("pass")
    else
        echo "❌ Go in PATH"
        status+=("fail")
    fi
    
    # Summary
    local passed=0
    local total=${#status[@]}
    for result in "${status[@]}"; do
        if [ "$result" = "pass" ]; then
            ((passed++))
        fi
    done
    
    local percentage=$((passed * 100 / total))
    echo -e "\n${BLUE}Quick Summary${NC}"
    if [ $percentage -ge 80 ]; then
        style_success "🎉 System Health: GOOD ($passed/$total - $percentage%)"
    elif [ $percentage -ge 60 ]; then
        style_warning "⚠️  System Health: FAIR ($passed/$total - $percentage%)"
    else
        style_error "❌ System Health: POOR ($passed/$total - $percentage%)"
    fi
    
    wait_for_user
}

# Run full verification
run_full_verification() {
    style_subheader "🔍 Comprehensive System Verification" "Checking all devcontainer features and tools" "#00ff00"
    
    local total_checks=0
    local passed_checks=0
    
    # Development Languages
    echo -e "\n${BLUE}🚀 Development Languages${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Node.js
    if command -v node &>/dev/null && command -v npm &>/dev/null; then
        style_success "✅ Node.js: $(node --version) | npm: $(npm --version)"
        ((passed_checks++))
    else
        style_error "❌ Node.js/npm: Not found"
    fi
    ((total_checks++))
    
    # Go - Load user environment fragments first for proper detection
    # Source Go environment fragment if it exists
    if [ -f "/home/babaji/.ohmyzsh_source_load_scripts/.go-env.zshrc" ]; then
        source "/home/babaji/.ohmyzsh_source_load_scripts/.go-env.zshrc" 2>/dev/null || true
    fi

    if command -v go &>/dev/null; then
        style_success "✅ Go: $(go version | cut -d' ' -f3)"
        # Test Go PATH
        if go env GOPATH &>/dev/null; then
            style_success "  └─ GOPATH: $(go env GOPATH)"
        fi
        ((passed_checks++))
    else
        style_error "❌ Go: Not found"
    fi
    ((total_checks++))
    
    # Python and Conda
    if command -v python3 &>/dev/null; then
        style_success "✅ Python: $(python3 --version)"
        ((passed_checks++))
    else
        style_error "❌ Python: Not found"
    fi
    ((total_checks++))
    
    # Note: Conda check removed - conda is temporarily disabled per devcontainer.json
    
    # Container and Cloud Tools
    echo -e "\n${BLUE}🐳 Container & Cloud Tools${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Docker
    if command -v docker &>/dev/null; then
        local docker_version=$(docker --version | cut -d' ' -f3 | sed 's/,//')
        style_success "✅ Docker: $docker_version"
        if docker info &>/dev/null; then
            style_success "  └─ Docker daemon: Running"
        else
            style_warning "  └─ Docker daemon: Not accessible (normal in container)"
        fi
        ((passed_checks++))
    else
        style_error "❌ Docker: Not found"
    fi
    ((total_checks++))
    
    # Kubernetes tools
    if command -v kubectl &>/dev/null; then
        local kubectl_version=$(kubectl version --client --short 2>/dev/null | grep -o 'v[0-9.]*' || echo "installed")
        style_success "✅ kubectl: $kubectl_version"
        ((passed_checks++))
    else
        style_error "❌ kubectl: Not found"
    fi
    ((total_checks++))
    
    if command -v helm &>/dev/null; then
        local helm_version=$(helm version --short | cut -d' ' -f1)
        style_success "✅ Helm: $helm_version"
        ((passed_checks++))
    else
        style_error "❌ Helm: Not found"
    fi
    ((total_checks++))
    
    if command -v k9s &>/dev/null; then
        local k9s_version=$(k9s version --short | grep Version | cut -d: -f2 | xargs)
        style_success "✅ k9s: $k9s_version"
        ((passed_checks++))
    else
        style_error "❌ k9s: Not found"
    fi
    ((total_checks++))
    
    # Terraform
    if command -v terraform &>/dev/null; then
        local tf_version="installed"
        if terraform --version >/dev/null 2>&1; then
            tf_version=$(terraform --version | awk 'NR==1 {print $2; exit}')
        fi
        style_success "✅ Terraform: $tf_version"
        ((passed_checks++))
    else
        style_error "❌ Terraform: Not found"
    fi
    ((total_checks++))
    
    # DevOps and CLI Tools
    echo -e "\n${BLUE}⚙️  DevOps & CLI Tools${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # AWS CLI
    if command -v aws &>/dev/null; then
        local aws_version=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
        style_success "✅ AWS CLI: $aws_version"
        ((passed_checks++))
    else
        style_error "❌ AWS CLI: Not found"
    fi
    ((total_checks++))
    
    # SOPS
    if command -v sops &>/dev/null; then
        local sops_version=$(sops --version | head -1)
        style_success "✅ SOPS: $sops_version"
        ((passed_checks++))
    else
        style_error "❌ SOPS: Not found"
    fi
    ((total_checks++))
    
    # JSON/YAML processors
    local json_tools=("jq" "yq" "fx")
    for tool in "${json_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            # Safer version checking - avoid complex pipes with timeout
            local version="installed"
            case "$tool" in
                "jq")
                    version=$(jq --version 2>/dev/null || echo "installed")
                    ;;
                "yq")
                    # Use safer approach - get version without pipe to head
                    if yq --version >/dev/null 2>&1; then
                        version=$(yq --version 2>/dev/null | awk 'NR==1 {print; exit}')
                    else
                        version="installed"
                    fi
                    ;;
                "fx")
                    version=$(fx --version 2>/dev/null || echo "installed")
                    ;;
            esac
            style_success "✅ $tool: $version"
            ((passed_checks++))
        else
            style_error "❌ $tool: Not found"
        fi
        ((total_checks++))
    done
    
    # Modern CLI Tools
    echo -e "\n${BLUE}✨ Modern CLI Tools${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local modern_tools=("gum" "aider" "nu" "cloudflared")
    for tool in "${modern_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version=""
            case "$tool" in
                "gum") version=$(gum --version | cut -d' ' -f3) ;;
                "aider") version=$(aider --version | cut -d' ' -f2) ;;
                "nu") version=$(nu --version | head -1) ;;
                "cloudflared") version=$(cloudflared --version | cut -d' ' -f3) ;;
                *) version="installed" ;;
            esac
            style_success "✅ $tool: $version"
            ((passed_checks++))
        else
            style_error "❌ $tool: Not found"
        fi
        ((total_checks++))
    done
    
    # Development Environment
    echo -e "\n${BLUE}💻 Development Environment${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Git
    if command -v git &>/dev/null; then
        local git_version=$(git --version | cut -d' ' -f3)
        style_success "✅ Git: $git_version"
        # Check Git LFS
        if command -v git-lfs &>/dev/null; then
            local lfs_version=$(git-lfs --version | cut -d' ' -f1 | cut -d'/' -f2)
            style_success "  └─ Git LFS: $lfs_version"
        fi
        ((passed_checks++))
    else
        style_error "❌ Git: Not found"
    fi
    ((total_checks++))
    
    # Editors
    local editors=("vim" "nvim" "code-server")
    for editor in "${editors[@]}"; do
        if command -v "$editor" &>/dev/null; then
            local version=""
            case "$editor" in
                "vim") version=$(vim --version | head -1 | cut -d' ' -f5) ;;
                "nvim") version=$(nvim --version | head -1 | cut -d' ' -f2) ;;
                "code-server") version=$(code-server --version | head -1) ;;
                *) version="installed" ;;
            esac
            style_success "✅ $editor: $version"
            ((passed_checks++))
        else
            style_error "❌ $editor: Not found"
        fi
        ((total_checks++))
    done
    
    # Terminal multiplexer
    if command -v tmux &>/dev/null; then
        local tmux_version=$(tmux -V | cut -d' ' -f2)
        style_success "✅ tmux: $tmux_version"
        ((passed_checks++))
    else
        style_error "❌ tmux: Not found"
    fi
    ((total_checks++))
    
    # Shell and Environment
    echo -e "\n${BLUE}🐚 Shell & Environment${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Zsh and Oh My Zsh
    if command -v zsh &>/dev/null; then
        style_success "✅ Zsh: $(zsh --version | cut -d' ' -f2)"
        if [ -d "$HOME/.oh-my-zsh" ]; then
            style_success "  └─ Oh My Zsh: Installed"
        else
            style_warning "  └─ Oh My Zsh: Not found"
        fi
        ((passed_checks++))
    else
        style_error "❌ Zsh: Not found"
    fi
    ((total_checks++))
    
    # PowerLevel10k
    if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ] || command -v p10k &>/dev/null; then
        style_success "✅ PowerLevel10k: Installed"
        ((passed_checks++))
    else
        style_error "❌ PowerLevel10k: Not found"
    fi
    ((total_checks++))
    
    # Network and Security
    echo -e "\n${BLUE}🔒 Network & Security${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # SSH
    if command -v ssh &>/dev/null && command -v sshd &>/dev/null; then
        style_success "✅ SSH: $(ssh -V 2>&1 | cut -d'_' -f2 | cut -d',' -f1)"
        # Check SSH service
        if pgrep sshd > /dev/null; then
            style_success "  └─ SSH daemon: Running"
        else
            style_warning "  └─ SSH daemon: Not running"
        fi
        ((passed_checks++))
    else
        style_error "❌ SSH: Not found"
    fi
    ((total_checks++))
    
    # GPG
    if command -v gpg &>/dev/null; then
        local gpg_version=$(gpg --version | head -1 | cut -d' ' -f3)
        style_success "✅ GPG: $gpg_version"
        ((passed_checks++))
    else
        style_error "❌ GPG: Not found"
    fi
    ((total_checks++))
    
    # Network tools
    local net_tools=("curl" "wget" "ping" "netstat" "ss")
    local net_passed=0
    for tool in "${net_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            ((net_passed++))
        fi
        ((total_checks++))
    done
    if [ $net_passed -eq ${#net_tools[@]} ]; then
        style_success "✅ Network tools: All $net_passed tools available"
        ((passed_checks += ${#net_tools[@]}))
    else
        style_warning "⚠️  Network tools: $net_passed/${#net_tools[@]} available"
        ((passed_checks += net_passed))
    fi
    
    # CUDA (if available)
    echo -e "\n${BLUE}🎯 Specialized Tools${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if command -v nvidia-smi &>/dev/null; then
        local cuda_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)
        style_success "✅ NVIDIA CUDA: Driver $cuda_version"
        ((passed_checks++))
    else
        style_info "ℹ️  NVIDIA CUDA: Not available (optional)"
    fi
    ((total_checks++))
    
    # Lua and LuaRocks
    if command -v lua &>/dev/null; then
        local lua_version=$(lua -v | head -1 | cut -d' ' -f2)
        style_success "✅ Lua: $lua_version"
        if command -v luarocks &>/dev/null; then
            local luarocks_version=$(luarocks --version | head -1 | cut -d' ' -f2)
            style_success "  └─ LuaRocks: $luarocks_version"
        fi
        ((passed_checks++))
    else
        style_error "❌ Lua: Not found"
    fi
    ((total_checks++))
    
    # Environment Variables Check
    echo -e "\n${BLUE}🌍 Environment Variables${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local env_vars=("PATH" "HOME" "USER" "SHELL" "GOPATH" "NODE_PATH")
    for var in "${env_vars[@]}"; do
        if [ ! -z "${!var}" ]; then
            case "$var" in
                "PATH")
                    local go_in_path=$(echo "$PATH" | grep -o "/usr/local/go/bin" || echo "")
                    if [ ! -z "$go_in_path" ]; then
                        style_success "✅ $var: Go path included"
                    else
                        style_warning "⚠️  $var: Go path missing"
                    fi
                    ;;
                "GOPATH"|"NODE_PATH")
                    style_success "✅ $var: ${!var}"
                    ;;
                *)
                    style_success "✅ $var: Set"
                    ;;
            esac
            ((passed_checks++))
        else
            style_error "❌ $var: Not set"
        fi
        ((total_checks++))
    done
    
    # Final Summary
    echo -e "\n${BLUE}📊 Verification Summary${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local percentage=$((passed_checks * 100 / total_checks))
    
    if [ $percentage -ge 90 ]; then
        style_success "🎉 EXCELLENT: $passed_checks/$total_checks checks passed ($percentage%)"
        style_success "   Your devcontainer is fully functional!"
    elif [ $percentage -ge 75 ]; then
        style_success "✅ GOOD: $passed_checks/$total_checks checks passed ($percentage%)"
        style_warning "   Most features working, some optional tools missing"
    elif [ $percentage -ge 50 ]; then
        style_warning "⚠️  PARTIAL: $passed_checks/$total_checks checks passed ($percentage%)"
        style_warning "   Core functionality available, missing several features"
    else
        style_error "❌ POOR: $passed_checks/$total_checks checks passed ($percentage%)"
        style_error "   Major issues detected, container needs attention"
    fi
    
    echo -e "\n${GRAY}Run specific checks from the verification menu for detailed analysis.${NC}"
    wait_for_user
}

# Check development tools
check_dev_tools() {
    style_subheader "🔧 Development Tools Check" ""
    
    local tools=("git" "vim" "nvim" "tmux" "curl" "wget" "jq" "docker" "kubectl")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            # Use safer version detection without head pipe
            local version="installed"
            if ${tool} --version >/dev/null 2>&1; then
                version=$(${tool} --version 2>/dev/null | awk 'NR==1 {print; exit}')
            fi
            style_success "✅ $tool: $version"
        else
            style_error "❌ $tool: Not found"
        fi
    done
    
    wait_for_user
}

# Check shell configuration
check_shell_config() {
    style_subheader "🐚 Shell Configuration Check" ""
    
    # Safety check - don't run during container build
    if [ -z "$HOME" ] || [ "$HOME" = "/" ]; then
        style_warning "⚠️ Skipping shell check - running in build environment"
        wait_for_user
        return 0
    fi
    
    # Check Zsh
    if command -v zsh &>/dev/null; then
        style_success "✅ Zsh: $(zsh --version)"
    else
        style_error "❌ Zsh: Not found"
    fi
    
    # Check Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        style_success "✅ Oh My Zsh: Installed"
    else
        style_error "❌ Oh My Zsh: Not found"
    fi
    
    # Check Zsh config
    if [ -f "$HOME/.zshrc" ]; then
        style_success "✅ .zshrc: Present"
    else
        style_error "❌ .zshrc: Missing"
    fi
    
    # Check fragments (with safety)
    if [ -d "$HOME/.ohmyzsh_source_load_scripts" ]; then
        local count=$(find "$HOME/.ohmyzsh_source_load_scripts" -name ".*.zshrc" 2>/dev/null | wc -l || echo "0")
        style_success "✅ Zsh Fragments: $count found"
    else
        style_error "❌ Zsh Fragments: Directory not found"
    fi
    
    wait_for_user
}

# Check packages
check_packages() {
    style_subheader "📦 Package Check" ""
    
    local python_packages=("numpy" "pandas" "requests" "openai" "anthropic")
    
    for pkg in "${python_packages[@]}"; do
        if python3 -c "import $pkg" &>/dev/null; then
            local version=$(python3 -c "import $pkg; print(getattr($pkg, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
            style_success "✅ $pkg: $version"
        else
            style_error "❌ $pkg: Not installed"
        fi
    done
    
    wait_for_user
}

# Check network tools
check_network_tools() {
    style_subheader "🌐 Network Tools Check" ""
    
    local net_tools=("ping" "curl" "wget" "ssh" "scp" "rsync" "netstat" "ss")
    
    for tool in "${net_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            style_success "✅ $tool: Available"
        else
            style_error "❌ $tool: Not found"
        fi
    done
    
    wait_for_user
}

# Check security tools
check_security_tools() {
    style_subheader "🔐 Security Tools Check" ""
    
    local sec_tools=("ssh-keygen" "gpg" "openssl")
    
    for tool in "${sec_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            style_success "✅ $tool: Available"
        else
            style_error "❌ $tool: Not found"
        fi
    done
    
    # Check SSH agent
    if pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
        style_success "✅ SSH Agent: Running"
    else
        style_error "❌ SSH Agent: Not running"
    fi
    
    wait_for_user
}
