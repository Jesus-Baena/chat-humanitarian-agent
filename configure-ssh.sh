#!/bin/bash

# SSH Configuration Helper
# This script helps you set up the SSH deployment configuration

echo "🔧 SSH Deployment Configuration Helper"
echo "======================================"
echo ""

# Check if .env file exists for SSH config
ENV_FILE=".env.ssh"

if [ -f "$ENV_FILE" ]; then
    echo "📁 Found existing SSH configuration in $ENV_FILE"
    echo "Current settings:"
    cat "$ENV_FILE"
    echo ""
    read -p "Do you want to update these settings? (y/N): " update_config
    if [[ ! $update_config =~ ^[Yy]$ ]]; then
        echo "Using existing configuration..."
        source "$ENV_FILE"
        echo "✅ SSH configuration loaded!"
        exit 0
    fi
fi

echo "Please provide your Docker Swarm SSH connection details:"
echo ""

# Get SSH connection details
read -p "Swarm Host (e.g., your-server.com): " swarm_host
read -p "SSH User (default: root): " swarm_user
swarm_user=${swarm_user:-root}
read -p "SSH Port (default: 22): " swarm_port
swarm_port=${swarm_port:-22}
read -p "SSH Key Path (default: ~/.ssh/id_rsa): " ssh_key
ssh_key=${ssh_key:-~/.ssh/id_rsa}

# Expand tilde in SSH key path
ssh_key="${ssh_key/#\~/$HOME}"

echo ""
echo "🔍 Testing SSH connection..."
echo "Host: $swarm_host"
echo "User: $swarm_user"
echo "Port: $swarm_port"
echo "Key:  $ssh_key"
echo ""

# Test SSH connection
if ssh -i "$ssh_key" -p "$swarm_port" -o ConnectTimeout=10 -o BatchMode=yes "$swarm_user@$swarm_host" "echo 'SSH test successful'" 2>/dev/null; then
    echo "✅ SSH connection successful!"
    
    # Save configuration
    cat > "$ENV_FILE" << EOF
# SSH Configuration for Docker Swarm Deployment
export SWARM_HOST="$swarm_host"
export SWARM_USER="$swarm_user"
export SWARM_PORT="$swarm_port"
export SSH_KEY="$ssh_key"
EOF
    
    echo "💾 Configuration saved to $ENV_FILE"
    echo ""
    echo "🚀 You can now run the deployment with:"
    echo "   source $ENV_FILE && ./ssh-deploy.sh"
    echo "   OR"
    echo "   ./ssh-deploy.sh (it will load the config automatically)"
    
else
    echo "❌ SSH connection failed!"
    echo ""
    echo "💡 Please check:"
    echo "  - Is the host correct and reachable?"
    echo "  - Is the SSH key correct and has proper permissions?"
    echo "  - Does the user have access to the host?"
    echo "  - Is the port correct?"
    echo ""
    echo "🔧 Common fixes:"
    echo "  chmod 600 $ssh_key"
    echo "  ssh-add $ssh_key"
    exit 1
fi