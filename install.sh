#!/bin/bash
set -e

VERSION="0.0.2"

#region User Variables
PASSWORD_LENGTH=64

SETUP_FIREWALL=true
SETUP_LETSENCRYPT=true
SETUP_MAIL=false
SETUP_DBPANEL=true
SETUP_DBHOST=true

NGINX_SSL=true

DBPANEL_DB="panel"
DBPANEL_USER="pterodactyl"
DBPANEL_PASSWORD=""

DBHOST_USER="pterodactyluser"
DBHOST_PASSWORD=""

DB_ROOT_PASSWORD=""

PHP_VERSION=8.0
#endregion

DB_INSTALLED=false

#region Text Formatting
NC="\033[0m" # Normal Color
RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"

output() {
    echo -e "${NC}${1}${NC}"
}

error() {
    echo
    echo -e "${RED}ERROR: ${1}${NC}"
    echo
}

warning() {
    echo
    echo -e "${YELLOW}WARNING: ${1}${NC}"
    echo
}
#endregion

#region Helper Functions
update_upgrade() {
    apt update -y && apt upgrade -y
}

setup_ufw() {
    apt install -y ufw
    ufw allow 22
    yes | ufw enable
}
#endregion

#region Check if Root
if [ "$EUID" -ne 0 ]; then
    error "Must run the script with root privileges!"
    exit 1
fi
#endregion

#region Check Distribution
dist="$(. /etc/os-release && echo "$ID")"
if [ "$dist" != "debian" ] && [ "$dist" != "ubuntu" ]; then
    error "Unsupported Distribution! Only Debian and Ubuntu are supported."
    exit 1
fi
#endregion

#region Check Architecture
arch="$(uname -m)"
if [ "$arch" != "x86_64" ]; then
    error "Unsupported Architecture! Only x86_64 is supported."
    exit 1
fi
#endregion

#region Check Virtualization
virt="$(systemd-detect-virt)"
if [ "$virt" = "openvz" ] || [ "$virt" = "lxc" ]; then
    warning "Unsupported Virtualization! OpenVZ and LXC will most likely be unable to run Wings."

    output "Are you sure you want to proceed? (y/N): "
    read -r PROCEED_VIRTUALIZATION

    if [[ ! "$PROCEED_VIRTUALIZATION" =~ [Yy] ]]; then
        output "${RED}Installation aborted!"
        exit 1
    fi
fi
#endregion

#region Check for Updates
output "${BLUE}Checking for updates..."

which curl &>/dev/null || sudo apt install -y curl

SCRIPT_LOCATION="${BASH_SOURCE[@]}"
ABS_SCRIPT_PATH=$(readlink -f "$SCRIPT_LOCATION")
TMP_FILE=$(mktemp -p "" "XXXXX.sh")

curl -s -L "https://raw.githubusercontent.com/BAERSERK/Pterodactyl-Installer/develop/install.sh" >"$TMP_FILE"
NEW_VER=$(grep "^VERSION" "$TMP_FILE" | awk -F'[="]' '{print $3}')

if [[ "$VERSION" < "$NEW_VER" ]]; then
    output "${GREEN}Update script from ${RED}v${VERSION} ${GREEN}to ${YELLOW}v${NEW_VER}"
    cp -f "$TMP_FILE" "$ABS_SCRIPT_PATH" || error "Unable to update script!"
else
    output "${GREEN}Already have the latest version."
fi
#endregion

#region Selection Menu
clear -x
echo "Please select an option:"

while true; do
    options=(
        "Install MariaDB"
        "Install Panel"
        "Install Wings"
        "Settings"
        "Quit"
    )

    select option in "${options[@]}"; do
        case $option in
        "Install MariaDB")
            . <(curl -s "https://raw.githubusercontent.com/BAERSERK/Pterodactyl-Installer/develop/scripts/install-mariadb.sh")
            printf "\n\n\nPlease select an option:\n"
            break
            ;;
        "Install Panel")
            . <(curl -s "https://raw.githubusercontent.com/BAERSERK/Pterodactyl-Installer/develop/scripts/install-panel.sh")
            printf "\n\n\nPlease select an option:\n"
            break
            ;;
        "Install Wings")
            . <(curl -s "https://raw.githubusercontent.com/BAERSERK/Pterodactyl-Installer/develop/scripts/install-wings.sh")
            printf "\n\n\nPlease select an option:\n"
            break
            ;;
        "Settings")
            break
            ;;
        "Quit")
            break 2
            ;;
        *)
            break
            ;;
        esac
    done
done
#endregion
