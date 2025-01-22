#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Update system
echo "Updating system..."
apt update
apt upgrade -y

# Install fail2ban
echo "Installing fail2ban..."
apt install fail2ban -y

# Create backup of original configuration
echo "Creating configuration backup..."
if [ -f /etc/fail2ban/jail.local ]; then
    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.backup
fi

# Copy jail.conf to jail.local
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Configure fail2ban
echo "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << EOL
[DEFAULT]
# Ban hosts for 1 hour
bantime = 3600

# Retry interval of 10 minutes
findtime = 600

# Ban after 3 retries
maxretry = 3

# Use IPTables as the banaction
banaction = iptables-multiport

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 600
bantime = 3600

# Additional protection for HTTP/HTTPS (uncomment if needed)
#[http-get-dos]
#enabled = true
#port = http,https
#filter = http-get-dos
#logpath = /var/log/apache2/access.log
#maxretry = 300
#findtime = 300
#bantime = 600
EOL

# Create custom HTTP DOS filter (commented by default)
cat > /etc/fail2ban/filter.d/http-get-dos.conf << EOL
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*
ignoreregex =
EOL

# Restart fail2ban service
echo "Restarting fail2ban service..."
systemctl restart fail2ban
systemctl enable fail2ban

# Verify installation
echo "Verifying installation..."
fail2ban-client status

echo "Fail2ban installation and configuration completed!"
echo "You can check the status using: sudo fail2ban-client status"
echo "View logs using: sudo tail -f /var/log/fail2ban.log"