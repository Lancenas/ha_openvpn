#!/usr/bin/with-contenv bash
set -e

echo "[INFO] Starting OpenVPN Client..."

OPTIONS="/data/options.json"
OVPN_FILE=$(jq -r '.ovpn_file' "$OPTIONS")
AUTO_CONNECT=$(jq -r '.auto_connect' "$OPTIONS")
USERNAME=$(jq -r '.username' "$OPTIONS")
PASSWORD=$(jq -r '.password' "$OPTIONS")

# Cesta k .ovpn súboru
CONFIG="/config/addons_config/ha_openvpn/${OVPN_FILE}"

# Overenie názvu súboru
if [ -z "$OVPN_FILE" ] || [ "$OVPN_FILE" == "null" ]; then
    echo "[ERROR] ovpn_file not set in options.json"
    exit 1
fi

# Overenie existencie súboru
if [ ! -f "$CONFIG" ]; then
    echo "[ERROR] OVPN file not found at $CONFIG"
    exit 1
fi

echo "[INFO] Found OVPN file at $CONFIG"

# Príprava auth.txt ak sú zadané údaje
AUTH_OPTION=""
if [ -n "$USERNAME" ] && [ "$USERNAME" != "null" ] && [ -n "$PASSWORD" ] && [ "$PASSWORD" != "null" ]; then
    echo "[INFO] Creating temporary auth.txt file..."
    echo "$USERNAME" > /tmp/auth.txt
    echo "$PASSWORD" >> /tmp/auth.txt
    AUTH_OPTION="--auth-user-pass /tmp/auth.txt"
else
    echo "[INFO] No username/password provided. Skipping auth-user-pass."
fi

# Spustenie OpenVPN
if [ "$AUTO_CONNECT" == "true" ]; then
    echo "[INFO] Auto-connect enabled. Starting OpenVPN..."
    openvpn --config "$CONFIG" $AUTH_OPTION --daemon
    echo "[INFO] OpenVPN started in background."
else
    echo "[INFO] Auto-connect disabled. Waiting for manual start."
fi

# Voliteľné: vymazanie auth.txt po štarte (ak si istý, že nebude potrebný neskôr)
sleep 5
rm -f /tmp/auth.txt

# Udržuj kontajner živý
tail -f /dev/null
