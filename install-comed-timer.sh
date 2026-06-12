#!/usr/bin/env bash
# =============================================================================
# install-comed-timer.sh
#
# Installs the comed-5min-price systemd service + timer for the current user,
# baking in the hostname (for the MQTT topic) and the install directory
# (for the script path) so the service file doesn't need to call `hostname`
# or rely on a fixed path at runtime.
#
# Usage:
#   ./install-comed-timer.sh [install_dir]
#
# install_dir defaults to the directory this script is run from, and should
# contain 5min-prices-json.sh.
#
# This installs user-level systemd units (~/.config/systemd/user/).
# To use system-wide units instead, adjust DEST and drop --user from
# the systemctl commands, then run as root.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${1:-$SCRIPT_DIR}"
HOSTNAME_VAL="$(hostname)"

DEST="$HOME/.config/systemd/user"
mkdir -p "$DEST"

sed -e "s|__INSTALL_DIR__|${INSTALL_DIR}|g" \
    -e "s|__HOSTNAME__|${HOSTNAME_VAL}|g" \
    "${SCRIPT_DIR}/comed-5min-price.service" > "${DEST}/comed-5min-price.service"

cp "${SCRIPT_DIR}/comed-5min-price.timer" "${DEST}/comed-5min-price.timer"

echo "Installed:"
echo "  ${DEST}/comed-5min-price.service"
echo "  ${DEST}/comed-5min-price.timer"
echo
echo "Hostname baked in: ${HOSTNAME_VAL}"
echo "Script path: ${INSTALL_DIR}/5min-prices-json.sh"
echo
echo "Next steps:"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now comed-5min-price.timer"
echo
echo "To check status / logs:"
echo "  systemctl --user list-timers comed-5min-price.timer"
echo "  journalctl --user -u comed-5min-price.service -f"
echo
echo "Note: for the timer to run when you're not logged in, enable lingering:"
echo "  loginctl enable-linger \$USER"
