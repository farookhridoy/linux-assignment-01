#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo privileges" >&2
    exit 1
fi

# Get current script directory
script_dir=$(pwd)

# 1. Identify user who executed the script
real_user=${SUDO_USER:-$USER}

# 2. Identify user's shell
user_shell=$(getent passwd "$real_user" | cut -d: -f7)

# 3. Identify shell executable path
shell_path=$(command -v "$user_shell")

# 4. Identify OS information
source /etc/os-release
os_name=$NAME
os_version=$VERSION

# 5. Save user information
cat > "$script_dir/UserInfo.txt" <<EOF
User name: $real_user
Shell name: $user_shell
Shell executable path: $shell_path
OS version: $os_version
OS name: $os_name
EOF

# 6. List home directory files
home_dir=$(getent passwd "$real_user" | cut -d: -f6)
ls -la "$home_dir" > "$script_dir/UserHomeFileList.txt"


# 7. List /var/log contents
ls -laR /var/log > "$script_dir/log.txt"

# 8. Create directory in /opt
mkdir -p /opt/example_dir

# 9. Create symbolic links
ln -sf "$script_dir/UserInfo.txt" /opt/example_dir/UserInfo.txt
ln -sf "$script_dir/UserHomeFileList.txt" /opt/example_dir/UserHomeFileList.txt
ln -sf "$script_dir/log.txt" /opt/example_dir/log.txt

# 10. Install nginx
apt-get update
apt-get install -y nginx

# 11. Get private IP address
ip_address=$(hostname -I | awk '{print $1}')

# Save ip address 
cho -e "\nIP Address: $ip_address" >> "$script_dir/UserInfo.txt"

# 12. Update nginx configuration
sed -i "/server_name /c\    server_name $ip_address;" /etc/nginx/sites-available/default

# 13. Replace default nginx page
cp "$script_dir/UserInfo.txt" /var/www/html/index.nginx-debian.html

# 14. Enable nginx on boot
systemctl enable nginx

# 15. Restart nginx
systemctl restart nginx

echo "Script executed successfully"