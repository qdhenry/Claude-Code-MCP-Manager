#!/bin/bash

# MCP Manager Script
# A comprehensive tool to manage Model Context Protocol (MCP) configurations

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file (adjust path as needed)
CONFIG_FILE="$HOME/.config/claude/mcp_config.json"

# Ensure config directory exists
mkdir -p "$(dirname "$CONFIG_FILE")"

# Function to display usage
usage() {
    echo -e "${BLUE}MCP Manager - Manage your Model Context Protocol configurations${NC}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list, ls          List all configured MCPs"
    echo "  add               Add a new MCP configuration interactively"
    echo "  add-all           Add all MCPs from config to Claude (no prompts)"
    echo "  remove, rm        Remove an MCP configuration"
    echo "  show              Show details of a specific MCP"
    echo "  export            Export current configurations"
    echo "  import            Import configurations from file"
    echo "  init              Initialize with sample MCPs"
    echo "  setup-auto        Setup automatic MCP loading for new sessions"
    echo "  help, -h, --help  Show this help message"
    echo ""
}

# Function to check if config file exists
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}Config file not found. Creating new configuration...${NC}"
        echo '{"mcps": []}' > "$CONFIG_FILE"
    fi
}

# Function to list all MCPs
list_mcps() {
    check_config
    echo -e "${BLUE}Configured MCPs:${NC}"
    echo ""
    
    # Parse JSON and display MCPs
    if command -v jq &> /dev/null; then
        jq -r '.mcps[] | "\(.name) -- \(.type) -y @\(.path) --\(.options // "")"' "$CONFIG_FILE" 2>/dev/null | while read -r line; do
            echo "claude mcp add $line"
        done
    else
        echo -e "${RED}Error: jq is required but not installed. Please install jq.${NC}"
        exit 1
    fi
}

# Function to add all MCPs automatically
add_all_mcps() {
    check_config
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Adding all MCPs to Claude...${NC}"
    echo ""
    
    # Count total MCPs
    total=$(jq '.mcps | length' "$CONFIG_FILE")
    current=0
    
    # Process each MCP
    jq -r '.mcps[] | @json' "$CONFIG_FILE" | while read -r mcp_json; do
        current=$((current + 1))
        
        # Parse MCP details
        name=$(echo "$mcp_json" | jq -r '.name')
        type=$(echo "$mcp_json" | jq -r '.type')
        path=$(echo "$mcp_json" | jq -r '.path')
        options=$(echo "$mcp_json" | jq -r '.options // ""')
        
        # Build the command
        if [ "$type" == "npx" ]; then
            if [ -n "$options" ]; then
                cmd="claude mcp add \"$name\" -- npx -y @$path $options"
            else
                cmd="claude mcp add \"$name\" -- npx -y @$path"
            fi
        elif [ "$type" == "env" ]; then
            if [ -n "$options" ]; then
                cmd="claude mcp add \"$name\" -- env $path $options"
            else
                cmd="claude mcp add \"$name\" -- env $path"
            fi
        else
            echo -e "${YELLOW}Warning: Unknown type '$type' for MCP '$name'${NC}"
            continue
        fi
        
        # Execute the command
        echo -e "${GREEN}[$current/$total]${NC} Adding $name..."
        echo "  Command: $cmd"
        
        # Actually run the command
        eval "$cmd"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✓ Successfully added $name${NC}"
        else
            echo -e "${RED}  ✗ Failed to add $name${NC}"
        fi
        
        # Small delay to avoid overwhelming the system
        sleep 0.5
    done
    
    echo ""
    echo -e "${GREEN}Finished adding MCPs!${NC}"
}

# Function to add a new MCP interactively
add_mcp() {
    check_config
    
    echo -e "${BLUE}Add new MCP configuration${NC}"
    echo ""
    
    # Get MCP details
    read -p "MCP Name: " mcp_name
    read -p "Type (npx/env): " mcp_type
    read -p "Path/Package: " mcp_path
    read -p "Additional options (press Enter for none): " mcp_options
    
    # Validate input
    if [ -z "$mcp_name" ] || [ -z "$mcp_type" ] || [ -z "$mcp_path" ]; then
        echo -e "${RED}Error: Name, type, and path are required.${NC}"
        return 1
    fi
    
    # Add to config using jq
    if command -v jq &> /dev/null; then
        # Create the new MCP object
        new_mcp=$(jq -n \
            --arg name "$mcp_name" \
            --arg type "$mcp_type" \
            --arg path "$mcp_path" \
            --arg options "$mcp_options" \
            '{name: $name, type: $type, path: $path, options: $options}')
        
        # Add to the config
        jq ".mcps += [$new_mcp]" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        
        echo -e "${GREEN}Successfully added MCP: $mcp_name${NC}"
        echo "Command: claude mcp add $mcp_name -- $mcp_type -y @$mcp_path $mcp_options"
    else
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        return 1
    fi
}

# Function to remove an MCP
remove_mcp() {
    check_config
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please specify the MCP name to remove.${NC}"
        echo "Usage: $0 remove <mcp_name>"
        return 1
    fi
    
    mcp_name="$1"
    
    # Remove from config using jq
    if command -v jq &> /dev/null; then
        # Check if MCP exists
        exists=$(jq --arg name "$mcp_name" '.mcps[] | select(.name == $name)' "$CONFIG_FILE" 2>/dev/null)
        
        if [ -z "$exists" ]; then
            echo -e "${RED}Error: MCP '$mcp_name' not found.${NC}"
            return 1
        fi
        
        # Remove the MCP
        jq --arg name "$mcp_name" '.mcps |= map(select(.name != $name))' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        
        echo -e "${GREEN}Successfully removed MCP: $mcp_name${NC}"
    else
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        return 1
    fi
}

# Function to show details of a specific MCP
show_mcp() {
    check_config
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please specify the MCP name to show.${NC}"
        echo "Usage: $0 show <mcp_name>"
        return 1
    fi
    
    mcp_name="$1"
    
    if command -v jq &> /dev/null; then
        details=$(jq --arg name "$mcp_name" '.mcps[] | select(.name == $name)' "$CONFIG_FILE" 2>/dev/null)
        
        if [ -z "$details" ]; then
            echo -e "${RED}Error: MCP '$mcp_name' not found.${NC}"
            return 1
        fi
        
        echo -e "${BLUE}MCP Details for: $mcp_name${NC}"
        echo "$details" | jq .
    else
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        return 1
    fi
}

# Function to export configurations
export_config() {
    check_config
    
    if [ -z "$1" ]; then
        output_file="mcp_export_$(date +%Y%m%d_%H%M%S).json"
    else
        output_file="$1"
    fi
    
    cp "$CONFIG_FILE" "$output_file"
    echo -e "${GREEN}Configurations exported to: $output_file${NC}"
}

# Function to import configurations
import_config() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please specify the import file.${NC}"
        echo "Usage: $0 import <file>"
        return 1
    fi
    
    import_file="$1"
    
    if [ ! -f "$import_file" ]; then
        echo -e "${RED}Error: Import file '$import_file' not found.${NC}"
        return 1
    fi
    
    # Validate JSON
    if command -v jq &> /dev/null; then
        if ! jq . "$import_file" &> /dev/null; then
            echo -e "${RED}Error: Invalid JSON in import file.${NC}"
            return 1
        fi
        
        # Backup current config
        if [ -f "$CONFIG_FILE" ]; then
            cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
            echo -e "${YELLOW}Current config backed up to: $CONFIG_FILE.backup${NC}"
        fi
        
        # Import the config
        cp "$import_file" "$CONFIG_FILE"
        echo -e "${GREEN}Configurations imported successfully.${NC}"
    else
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        return 1
    fi
}

# Function to setup automatic MCP loading
setup_auto() {
    echo -e "${BLUE}Setting up automatic MCP loading...${NC}"
    echo ""
    
    # Get the current script path
    script_path=$(realpath "$0")
    
    # Create the wrapper function
    wrapper_function='
# Claude Code MCP Auto-loader
claude-code() {
    # Check if mcp-manager exists and has add-all command
    if [ -f "'$script_path'" ]; then
        echo "Starting Claude Code with auto-loaded MCPs..."
        
        # Start Claude Code in background
        command claude-code "$@" &
        CLAUDE_PID=$!
        
        # Wait a moment for Claude Code to initialize
        sleep 2
        
        # Add all MCPs
        "'$script_path'" add-all
        
        # Bring Claude Code back to foreground
        wait $CLAUDE_PID
    else
        # Fallback to regular claude-code if script not found
        command claude-code "$@"
    fi
}

# Alias for shorter command
alias cc="claude-code"
'
    
    # Determine shell config file
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
        shell_name="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        shell_config="$HOME/.bashrc"
        shell_name="bash"
    else
        echo -e "${RED}Error: Unsupported shell. Please add the function manually.${NC}"
        return 1
    fi
    
    # Check if function already exists
    if grep -q "Claude Code MCP Auto-loader" "$shell_config" 2>/dev/null; then
        echo -e "${YELLOW}Auto-loader already configured in $shell_config${NC}"
        echo "To update, remove the existing configuration first."
        return 0
    fi
    
    # Add to shell config
    echo "" >> "$shell_config"
    echo "$wrapper_function" >> "$shell_config"
    
    echo -e "${GREEN}✓ Auto-loader added to $shell_config${NC}"
    echo ""
    echo "To use it:"
    echo "  1. Reload your shell: source $shell_config"
    echo "  2. Start Claude Code with: claude-code (or cc)"
    echo ""
    echo "Your MCPs will be automatically loaded every time!"
    
    # Also create a standalone launcher script
    launcher_script="$HOME/.local/bin/claude-code-mcp"
    mkdir -p "$HOME/.local/bin"
    
    cat > "$launcher_script" << EOF
#!/bin/bash
# Claude Code with auto-loaded MCPs

echo "Starting Claude Code with auto-loaded MCPs..."

# Start Claude Code
claude-code "\$@" &
CLAUDE_PID=\$!

# Wait for initialization
sleep 2

# Add all MCPs
"$script_path" add-all

# Wait for Claude Code to finish
wait \$CLAUDE_PID
EOF
    
    chmod +x "$launcher_script"
    
    echo ""
    echo -e "${GREEN}✓ Also created standalone launcher: $launcher_script${NC}"
    echo "Add ~/.local/bin to your PATH to use it anywhere."
}

# Function to initialize sample MCPs based on the image
init_samples() {
    check_config
    
    echo -e "${BLUE}Initializing sample MCPs based on common configurations...${NC}"
    
    cat > "$CONFIG_FILE" << 'EOF'
{
  "mcps": [
    {
      "name": "supabase",
      "type": "npx",
      "path": "supabase/mcp-server-supabase@latest",
      "options": "--access-token <your-access-token>"
    },
    {
      "name": "digitalocean",
      "type": "env",
      "path": "DIGITALOCEAN_API_TOKEN=<your-token>",
      "options": "npx -y <package-name>"
    },
    {
      "name": "shopify-dev-mcp",
      "type": "npx",
      "path": "shopify/dev-mcp@latest",
      "options": ""
    },
    {
      "name": "puppeteer",
      "type": "npx",
      "path": "modelcontextprotocol/server-puppeteer",
      "options": ""
    },
    {
      "name": "upstash",
      "type": "npx",
      "path": "upstash/mcp-server",
      "options": "run incomestreamsurfer@gmail.com"
    },
    {
      "name": "context7",
      "type": "env",
      "path": "DEFAULT_MINIMUM_TOKENS=6000",
      "options": "npx -y @upstash/context7"
    },
    {
      "name": "Bright Data",
      "type": "env",
      "path": "API_TOKEN=<your-token>",
      "options": "npx -y @brightdata/<package-name>"
    }
  ]
}
EOF
    
    echo -e "${GREEN}Sample MCPs initialized. Please update the tokens and paths as needed.${NC}"
    echo "Edit the config file: $CONFIG_FILE"
}

# Main script logic
case "$1" in
    list|ls)
        list_mcps
        ;;
    add)
        add_mcp
        ;;
    add-all)
        add_all_mcps
        ;;
    remove|rm)
        remove_mcp "$2"
        ;;
    show)
        show_mcp "$2"
        ;;
    export)
        export_config "$2"
        ;;
    import)
        import_config "$2"
        ;;
    init)
        init_samples
        ;;
    setup-auto)
        setup_auto
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        if [ -z "$1" ]; then
            list_mcps
        else
            echo -e "${RED}Unknown command: $1${NC}"
            usage
            exit 1
        fi
        ;;
esac