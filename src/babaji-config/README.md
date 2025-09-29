# Babaji Configuration Utility

This feature provides a comprehensive configuration utility for the Shellinator Reloaded devcontainer environment.

## Features

### 📡 NAS Configuration
- Connect to SMB/CIFS shares with interactive browsing
- SSH/SFTP and FTP/FTPS mounting
- Quick mount for standard locations
- Advanced NAS management tools
- Mount/unmount management

### 🔍 System Verification
- Full devcontainer verification
- Individual component checks (development tools, shell config, packages, etc.)
- Network and security tools validation

### ⚙️ Environment Settings
- View and edit environment variables
- PATH management
- Shell theme configuration
- Alias management

### 📊 System Information
- Comprehensive system overview
- Resource usage monitoring
- Shell configuration reloading

## Usage

Run the configuration utility:

```bash
babaji-config
```

### Compatibility

The old `connect-nas` command is still available as a compatibility alias that launches the full babaji-config utility.

## Requirements

- gum (TUI toolkit) - automatically installed
- Standard Linux utilities (mount, umount, etc.)
- Network filesystem support (cifs-utils, sshfs, curlftpfs)

## Navigation

Use the interactive menus to navigate between different configuration areas. Each section provides specific tools and options for managing that aspect of your devcontainer environment.

The utility is designed to be user-friendly with clear visual indicators and confirmation prompts for destructive actions.
