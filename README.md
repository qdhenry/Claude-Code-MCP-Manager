# MCP Manager - Setup and Usage Guide

## Overview

MCP Manager is a comprehensive bash script that helps you manage Model Context Protocol (MCP) configurations for Claude Code. It allows you to easily add, remove, list, and automatically load MCP configurations without manual intervention.

## Features

- **List MCPs** - View all configured MCPs in the correct format
- **Add/Remove MCPs** - Manage your MCP configurations interactively
- **Batch Operations** - Add all MCPs at once without prompts
- **Auto-loading** - Automatically load MCPs when starting Claude Code
- **Import/Export** - Save and restore your MCP configurations
- **Sample Configurations** - Initialize with common MCP setups

## Prerequisites

- **Bash shell** (works with both bash and zsh)
- **jq** - Command-line JSON processor
  - macOS: `brew install jq`
  - Ubuntu/Debian: `sudo apt-get install jq`
  - RHEL/CentOS: `sudo yum install jq`
  - Arch Linux: `sudo pacman -S jq`

## Installation

### Option 1: Direct Download

```bash
# Download the script
curl -O https://raw.githubusercontent.com/qdhenry/Claude-Code-MCP-Manager/main/mcp-manager.sh

# Make it executable
chmod +x mcp-manager.sh

# Move to a location in your PATH (optional)
sudo mv mcp-manager.sh /usr/local/bin/mcp-manager
```

### Option 2: Clone Repository

```bash
# Clone the repository
git clone https://github.com/qdhenry/Claude-Code-MCP-Manager.git

# Navigate to the directory
cd Claude-Code-MCP-Manager

# Make the script executable
chmod +x mcp-manager.sh

# Create a symbolic link (optional)
sudo ln -s $(pwd)/mcp-manager.sh /usr/local/bin/mcp-manager
```

## Quick Start

1. **Initialize with sample MCPs:**
   ```bash
   ./mcp-manager.sh init
   ```

2. **Edit the configuration to add your tokens:**
   ```bash
   nano ~/.config/claude/mcp_config.json
   ```
   Replace `<your-token>` placeholders with actual tokens.

3. **List all MCPs:**
   ```bash
   ./mcp-manager.sh list
   ```

4. **Add all MCPs to Claude:**
   ```bash
   ./mcp-manager.sh add-all
   ```

## Usage

### Basic Commands

```bash
# List all configured MCPs
./mcp-manager.sh list
# or
./mcp-manager.sh ls

# Add a new MCP interactively
./mcp-manager.sh add

# Add all MCPs without prompts
./mcp-manager.sh add-all

# Remove an MCP
./mcp-manager.sh remove <mcp_name>
# or
./mcp-manager.sh rm <mcp_name>

# Show details of a specific MCP
./mcp-manager.sh show <mcp_name>

# Export configurations
./mcp-manager.sh export [filename]

# Import configurations
./mcp-manager.sh import <filename>

# Initialize with sample MCPs
./mcp-manager.sh init

# Set up automatic loading
./mcp-manager.sh setup-auto

# Show help
./mcp-manager.sh help
```

### Configuration File

The configuration is stored in `~/.config/claude/mcp_config.json`. Here's the structure:

```json
{
  "mcps": [
    {
      "name": "supabase",
      "type": "npx",
      "path": "supabase/mcp-server-supabase@latest",
      "options": "--access-token YOUR_TOKEN_HERE"
    },
    {
      "name": "digitalocean",
      "type": "env",
      "path": "DIGITALOCEAN_API_TOKEN=YOUR_TOKEN_HERE",
      "options": "npx -y @digitalocean/mcp"
    }
  ]
}
```

### MCP Types

1. **NPX Type** - For npm packages:
   ```json
   {
     "name": "puppeteer",
     "type": "npx",
     "path": "modelcontextprotocol/server-puppeteer",
     "options": ""
   }
   ```

2. **ENV Type** - For environment variables:
   ```json
   {
     "name": "digitalocean",
     "type": "env",
     "path": "DIGITALOCEAN_API_TOKEN=your-token",
     "options": "npx -y @digitalocean/mcp"
   }
   ```

## Automatic Loading Setup

To automatically load all MCPs when starting Claude Code:

### Method 1: Shell Function (Recommended)

1. Run the setup command:
   ```bash
   ./mcp-manager.sh setup-auto
   ```

2. Reload your shell:
   ```bash
   source ~/.bashrc  # or ~/.zshrc for zsh
   ```

3. Start Claude Code with auto-loaded MCPs:
   ```bash
   claude-code
   # or use the alias
   cc
   ```

### Method 2: Custom Alias

Add to your `.bashrc` or `.zshrc`:

```bash
alias claude-start='/path/to/mcp-manager.sh add-all && claude-code'
```

### Method 3: Wrapper Script

Create a custom launcher script:

```bash
#!/bin/bash
echo "Starting Claude Code with MCPs..."
/path/to/mcp-manager.sh add-all
claude-code "$@"
```

## Examples

### Adding a New MCP

```bash
$ ./mcp-manager.sh add
Add new MCP configuration

MCP Name: github
Type (npx/env): npx
Path/Package: @github/mcp-server@latest
Additional options (press Enter for none): 

Successfully added MCP: github
```

### Batch Import/Export

```bash
# Export current configuration
./mcp-manager.sh export my-mcps-backup.json

# Import from a file
./mcp-manager.sh import team-mcps.json
```

### Setting Up Common MCPs

After running `./mcp-manager.sh init`, you'll get these pre-configured MCPs:

- **Supabase** - Database and authentication
- **DigitalOcean** - Cloud infrastructure management
- **Shopify Dev** - E-commerce development tools
- **Puppeteer** - Browser automation
- **Upstash** - Redis and Kafka services
- **Context7** - Context management
- **Bright Data** - Web scraping and data collection

## Troubleshooting

### Issue: "jq is required but not installed"
**Solution:** Install jq using your package manager (see Prerequisites)

### Issue: "Config file not found"
**Solution:** The script will automatically create the config file. Run any command to initialize it.

### Issue: MCPs not loading automatically
**Solution:** 
1. Ensure the script path is correct in your shell function
2. Check if Claude Code is installed and accessible
3. Verify your shell configuration was reloaded

### Issue: "Permission denied"
**Solution:** Make sure the script is executable:
```bash
chmod +x mcp-manager.sh
```

## Advanced Usage

### Custom Configuration Location

To use a different configuration file location, modify the `CONFIG_FILE` variable in the script:

```bash
CONFIG_FILE="$HOME/.config/custom/mcp_config.json"
```

### Adding Complex MCPs

For MCPs with multiple environment variables:

```json
{
  "name": "complex-mcp",
  "type": "env",
  "path": "VAR1=value1 VAR2=value2",
  "options": "npx -y @complex/mcp-server --port 3000"
}
```

### Conditional Loading

Create a wrapper function that loads different MCPs based on the project:

```bash
claude-project() {
  if [[ $PWD == *"web-project"* ]]; then
    mcp-manager add supabase puppeteer
  elif [[ $PWD == *"data-project"* ]]; then
    mcp-manager add upstash context7
  fi
  claude-code "$@"
}
```

## Best Practices

1. **Keep tokens secure** - Never commit your configuration file with real tokens
2. **Regular backups** - Export your configuration regularly
3. **Version control** - Keep your MCP configurations in a private git repository
4. **Team sharing** - Use import/export to share configurations (without tokens)
5. **Minimal MCPs** - Only load the MCPs you need for better performance

## Contributing

To contribute to the MCP Manager project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is open source and available under the MIT License.

## Support

For issues, questions, or contributions:
- Create an issue on GitHub
- Check existing issues for solutions
- Read the Claude Code documentation for MCP-specific questions

---

**Note:** Remember to replace placeholder tokens with your actual API tokens before using the MCPs.