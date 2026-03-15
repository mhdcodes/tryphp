#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail

# Define an info message function
info() {
    local blue_bg="\033[44m"
    local white_text="\033[97m"
    local reset="\033[0m"
    printf " ${blue_bg}${white_text} INFO ${reset} $1"
}

# Define a success message function
success() {
    local green_bg="\033[42m"
    local black_text="\033[30m"
    local reset="\033[0m"
    printf " ${green_bg}${black_text} SUCCESS ${reset} $1 \n"
}

# Define an error message
error() {
    local red_bg="\033[41m"
    local white_text="\033[97m"
    local reset="\033[0m"
    printf " ${red_bg}${white_text} ERROR ${reset} $1 \n"
    exit 1
}

# Function to check if script has sudo access and request it if needed
ensure_sudo() {
    if [ "$EUID" -ne 0 ]; then
        info "This script requires sudo privileges to install FrankenPHP. \n"
        if ! sudo -v; then
            error "Could not acquire sudo privileges"
        fi
    fi
}

# Function to wait until apt package lock is released
wait_for_apt_lock() {
    info "Waiting for apt lock to be released...\n"
    while sudo fuser /var/lib/apt/lists/lock /var/lib/dpkg/lock >/dev/null 2>&1; do
        sleep 3
    done
}

# Function to determine the appropriate shell profile file to modify PATH
get_profile_file() {
    local shell_name
    shell_name=$(basename "$SHELL")
    
    # Set the search order for profile files, based on common conventions
    local profile_files=(".bash_profile" ".bashrc" ".profile" ".zshrc")
    
    # Loop through each profile file, returning the first existing one
    for profile_file in "${profile_files[@]}"; do
        if [[ -f "$HOME/$profile_file" ]]; then
            echo "$HOME/$profile_file"
            return
        fi
    done
    
    # If no common profile file is found, fallback to ~/.profile
    echo "$HOME/.profile"
}

# Function to download and install FrankenPHP binary
install_frankenphp_binary() {
    # Download FrankenPHP using the official installer
    if ! curl -fsSL https://frankenphp.dev/install.sh | sh; then
        error "Failed to download FrankenPHP binary"
    fi
    
    # Move binary to /usr/local/bin
    info "Installing FrankenPHP binary to /usr/local/bin...\n"
    if ! sudo mv frankenphp /usr/local/bin/; then
        error "Failed to move FrankenPHP binary to /usr/local/bin"
    fi
    
    # Make binary executable
    sudo chmod +x /usr/local/bin/frankenphp
    
    success "FrankenPHP binary installed successfully"
}

# Function to create FrankenPHP user and group
create_frankenphp_user() {
    info "Creating FrankenPHP system user and group...\n"
    
    # Create system group
    if ! getent group frankenphp > /dev/null 2>&1; then
        sudo groupadd --system frankenphp
        success "Created frankenphp group"
    else
        info "Group frankenphp already exists\n"
    fi
    
    # Create system user
    if ! id frankenphp > /dev/null 2>&1; then
        sudo useradd --system --gid frankenphp --create-home --home-dir /var/lib/frankenphp --shell /usr/sbin/nologin frankenphp
        success "Created frankenphp user"
    else
        info "User frankenphp already exists\n"
    fi
}

# Function to create FrankenPHP configuration
create_frankenphp_config() {
    info "Creating FrankenPHP configuration directory and Caddyfile...\n"
    
    # Create configuration directory
    sudo mkdir -p /etc/frankenphp
    
    # Create basic Caddyfile
    sudo tee /etc/frankenphp/Caddyfile > /dev/null <<EOF
{
  # Global options
  admin off

  # Default server
  auto_https off
}

:8080 {
  root * /var/www/html
  php_server {
    try_files {path} index.php
  }
}
EOF
    
    # Set proper ownership
    sudo chown -R frankenphp:frankenphp /etc/frankenphp/
    
    success "FrankenPHP configuration created"
}

# Function to create systemd service
create_systemd_service() {
    info "Creating FrankenPHP systemd service...\n"
    
    sudo tee /etc/systemd/system/frankenphp.service > /dev/null <<EOF
[Unit]
Description=FrankenPHP Server
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=frankenphp
Group=frankenphp

# Pre-start validation of the config file
ExecStartPre=/usr/local/bin/frankenphp validate --config /etc/frankenphp/Caddyfile

# Main command to run FrankenPHP with environment variables and config
ExecStart=/usr/local/bin/frankenphp run --environ --config /etc/frankenphp/Caddyfile

# Reload command to reload config without downtime
ExecReload=/usr/local/bin/frankenphp reload --config /etc/frankenphp/Caddyfile --force

# Graceful stop timeout
TimeoutStopSec=5s

# File descriptor limit for high concurrency
LimitNOFILE=1048576

# Isolate temporary files
PrivateTmp=true

# Protect system files from modification
ProtectSystem=full

# Grant necessary capabilities for network and binding ports
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

# Restart on failure
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    sudo systemctl daemon-reload
    sudo systemctl enable frankenphp
    
    success "FrankenPHP systemd service created and enabled"
}

# Function to start FrankenPHP service
start_frankenphp_service() {
    info "Starting FrankenPHP service...\n"
    
    if sudo systemctl start frankenphp; then
        success "FrankenPHP service started successfully"
        
        # Check service status
        if sudo systemctl is-active --quiet frankenphp; then
            success "FrankenPHP is running and active"
        else
            error "FrankenPHP service failed to start properly"
        fi
    else
        error "Failed to start FrankenPHP service"
    fi
}

# Function to create a sample web directory
create_sample_web_directory() {
    info "Creating sample web directory...\n"
    
    # Create web directory
    sudo mkdir -p /var/www/html
    
    # Create a simple PHP info page
    sudo tee /var/www/html/index.php > /dev/null <<EOF
<?php
phpinfo();
?>
EOF
    
    # Set proper ownership
    sudo chown -R frankenphp:frankenphp /var/www/html
    
    success "Sample web directory created at /var/www/html"
}

# Clear screen for readability
clear

# Request sudo access before installation starts
ensure_sudo

# Wait for apt lock to be released before proceeding with installations
wait_for_apt_lock

# Check if /usr/local/bin is already in PATH, and add it if not
PROFILE_FILE=$(get_profile_file)
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    # Add /usr/local/bin to PATH in the identified profile file
    printf '\nexport PATH="/usr/local/bin:$PATH"\n' >> "$PROFILE_FILE"
    
    # Notify user about the PATH modification
    info "/usr/local/bin has been added to your PATH in $PROFILE_FILE\n"
fi

# Main installation process
info "Starting FrankenPHP installation...\n\n"

# Install FrankenPHP binary
install_frankenphp_binary

# Create user and group
create_frankenphp_user

# Create configuration
create_frankenphp_config

# Create systemd service
create_systemd_service

# Create sample web directory
create_sample_web_directory

# Start the service
start_frankenphp_service

# Create uninstall command instructions
UNINSTALL_SCRIPT="sudo systemctl stop frankenphp 2>/dev/null || true
sudo systemctl disable frankenphp 2>/dev/null || true
sudo rm -f /etc/systemd/system/frankenphp.service
sudo systemctl daemon-reload
sudo rm -rf /etc/frankenphp
sudo rm -rf /var/lib/frankenphp
sudo userdel frankenphp 2>/dev/null || true
sudo groupdel frankenphp 2>/dev/null || true
sudo rm -f /usr/local/bin/frankenphp
"

# Retrieve installed FrankenPHP version
FULL_VERSION=$(frankenphp version 2>/dev/null | head -n 1 | tr -d '\n' || echo "FrankenPHP installed")
FRANKENPHP_VERSION=$(echo "$FULL_VERSION" | grep -o 'FrankenPHP v[0-9.]\+' | head -1 || echo "FrankenPHP")
PHP_VERSION=$(echo "$FULL_VERSION" | grep -o 'PHP [0-9.]\+' | head -1 || echo "PHP")

# Display success message with installed versions in a boxed format
printf "\n"
success "FrankenPHP has been installed and configured successfully."
printf "┌─────────────────────────────────────────────────────────┐\n"
printf "│ FrankenPHP: \e[1m%-43s\e[0m │\n" "$FRANKENPHP_VERSION"
printf "│ PHP: \e[1m%-48s\e[0m   │\n" "$PHP_VERSION"
printf "│ Service: \e[1m%-46s\e[0m │\n" "Active and Running"
printf "│ Web Root: \e[1m%-45s\e[0m │\n" "/var/www/html"
printf "│ Config: \e[1m%-47s\e[0m │\n" "/etc/frankenphp/Caddyfile"
printf "│ Default Port: \e[1m%-41s\e[0m │\n" "8080"
printf "└─────────────────────────────────────────────────────────┘\n\n"

info "Please restart your terminal or run \e[1m'source $PROFILE_FILE'\e[0m for the PATH changes to take effect.\n\n"

info "You can now access your PHP application at: \e[1mhttp://your-server-ip:8080\e[0m\n\n"

info "Useful commands:\n"
printf "  • Check status: \e[1msudo systemctl status frankenphp\e[0m\n"
printf "  • View logs: \e[1msudo journalctl -u frankenphp -f\e[0m\n"
printf "  • Restart service: \e[1msudo systemctl restart frankenphp\e[0m\n"
printf "  • Edit config: \e[1msudo nano /etc/frankenphp/Caddyfile\e[0m\n\n"

# Display uninstall instructions for FrankenPHP
info "To completely uninstall FrankenPHP, run the following commands:\n"
printf "$UNINSTALL_SCRIPT\n"
