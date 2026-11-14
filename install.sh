#!/bin/bash
set -euo pipefail

# Black Hat macOS installer. Uses curl + built-in macOS utilities only.
# Usage: curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Test1/main/install.sh | bash

APP_HOME="$HOME/Library/Application Support/BlackHat"
SOURCE_HOME="$APP_HOME/source"
SCRIPT="$SOURCE_HOME/blackhat.py"
TOR_HOME="$APP_HOME/TorBundle"
TOR_DATA="$APP_HOME/TorData"
VENV="$APP_HOME/venv"
TMP_DIR="$(mktemp -d)"
TOR_VERSION="16.0.1"
RAW_BASE_URL="https://raw.githubusercontent.com/ttmeticks-source/Test1/main"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: Black Hat is designed for macOS."
  exit 1
fi

mkdir -p "$APP_HOME" "$SOURCE_HOME" "$TOR_DATA"
chmod 700 "$APP_HOME" "$SOURCE_HOME" "$TOR_DATA"

echo "Downloading Black Hat Python source from GitHub..."
SOURCE_ARCHIVE="$TMP_DIR/blackhat.py.gz"
curl -fL --retry 3 --retry-delay 2 "$RAW_BASE_URL/blackhat.py.gz" -o "$SOURCE_ARCHIVE"
EXPECTED_SOURCE_SHA256="0d31ea110a182c323d3b3f61739af76642168b0b08ab957e547fb1dce1ba07c9"
ACTUAL_SOURCE_SHA256="$(/usr/bin/shasum -a 256 "$SOURCE_ARCHIVE" | /usr/bin/awk '{print $1}')"
if [[ "$ACTUAL_SOURCE_SHA256" != "$EXPECTED_SOURCE_SHA256" ]]; then
  echo "ERROR: Black Hat source SHA-256 verification failed."
  exit 1
fi
/usr/bin/gzip -dc "$SOURCE_ARCHIVE" > "$SCRIPT"

ARCH="$(uname -m)"
case "$ARCH" in
  arm64)
    TOR_ARCH="aarch64"
    TOR_SHA256="0b7d022017c31e3f972d06465bcd7ac50feb66ac825547419a934914fe4bb156"
    ;;
  x86_64)
    TOR_ARCH="x86_64"
    TOR_SHA256="15464d99adc3bb4de1308260d79878336b04a1ac1aeff83e10f192de7d235946"
    ;;
  *)
    echo "ERROR: Unsupported Mac architecture: $ARCH"
    exit 1
    ;;
esac

# Use an installed Python 3.10+ when available. Otherwise fetch Python's
# latest macOS installer build from the 3.13 line (3.13.17 was the last PKG build).
PYTHON="$(command -v python3 || true)"
PYTHON_OK=0
if [[ -n "$PYTHON" ]] && "$PYTHON" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)' >/dev/null 2>&1; then
  PYTHON_OK=1
fi
if [[ "$PYTHON_OK" -ne 1 ]]; then
  echo "Python 3.10+ not found. Downloading the official Python 3.13.17 macOS installer..."
  PYTHON_PKG="$TMP_DIR/python-3.13.17-macos11.pkg"
  PYTHON_SHA256="3053592af66128269efab37fe7851a4894920b27c442aeec99ce4d34d17c07e3"
  curl -fL --retry 3 --retry-delay 2 \
    "https://www.python.org/ftp/python/3.13.17/python-3.13.17-macos11.pkg" \
    -o "$PYTHON_PKG"
  ACTUAL_PYTHON_SHA256="$(/usr/bin/shasum -a 256 "$PYTHON_PKG" | /usr/bin/awk '{print $1}')"
  if [[ "$ACTUAL_PYTHON_SHA256" != "$PYTHON_SHA256" ]]; then
    echo "ERROR: Python installer SHA-256 verification failed."
    exit 1
  fi
  sudo /usr/sbin/installer -pkg "$PYTHON_PKG" -target /
  PYTHON="/Library/Frameworks/Python.framework/Versions/3.13/bin/python3"
  if [[ ! -x "$PYTHON" ]]; then PYTHON="/usr/local/bin/python3"; fi
fi
if [[ ! -x "$PYTHON" ]]; then
  echo "ERROR: Python installation could not be located."
  exit 1
fi

# Reuse the Tor bundle already extracted by a previous run, if present.
# Otherwise download the official Expert Bundle and verify its SHA-256 digest.
TOR_BIN="$TOR_HOME/tor/tor"
if [[ ! -f "$TOR_BIN" ]]; then
  TOR_BIN="$TOR_HOME/tor/tor.real"
fi

if [[ ! -f "$TOR_BIN" ]]; then
  TOR_ARCHIVE="tor-expert-bundle-macos-$TOR_ARCH-$TOR_VERSION.tar.gz"
  TOR_URL="https://dist.torproject.org/torbrowser/$TOR_VERSION/$TOR_ARCHIVE"
  TOR_TARBALL="$TMP_DIR/$TOR_ARCHIVE"
  echo "Downloading Tor Expert Bundle for $ARCH..."
  curl -fL --retry 3 --retry-delay 2 "$TOR_URL" -o "$TOR_TARBALL"
  ACTUAL_TOR_SHA256="$(/usr/bin/shasum -a 256 "$TOR_TARBALL" | /usr/bin/awk '{print $1}')"
  if [[ "$ACTUAL_TOR_SHA256" != "$TOR_SHA256" ]]; then
    echo "ERROR: Tor bundle SHA-256 verification failed."
    echo "Expected: $TOR_SHA256"
    echo "Received: $ACTUAL_TOR_SHA256"
    exit 1
  fi

  echo "Tor checksum verified; extracting..."
  rm -rf "$TOR_HOME"
  mkdir -p "$TOR_HOME"
  /usr/bin/tar -xzf "$TOR_TARBALL" -C "$TOR_HOME"
  TOR_BIN="$TOR_HOME/tor/tor"
  if [[ ! -f "$TOR_BIN" ]]; then
    TOR_BIN="$TOR_HOME/tor/tor.real"
  fi
fi

if [[ ! -f "$TOR_BIN" ]]; then
  TOR_BIN="$(/usr/bin/find -L "$TOR_HOME" -type f -name tor -print -quit)"
fi
if [[ -z "$TOR_BIN" || ! -f "$TOR_BIN" ]]; then
  echo "ERROR: Tor executable was not found. Extracted bundle contents:"
  /usr/bin/find "$TOR_HOME" -maxdepth 3 -print | /usr/bin/head -80
  exit 1
fi
chmod +x "$TOR_BIN"
if ! "$TOR_BIN" --version >/dev/null 2>&1; then
  echo "ERROR: The extracted Tor binary could not run on this Mac."
  "$TOR_BIN" --version 2>&1 || true
  exit 1
fi
GEOIP_FILE="$(/usr/bin/find -L "$TOR_HOME" -type f -name geoip -print -quit)"
GEOIP6_FILE="$(/usr/bin/find -L "$TOR_HOME" -type f -name geoip6 -print -quit)"

TORRC="$APP_HOME/torrc"
{
  printf 'DataDirectory "%s"\n' "$TOR_DATA"
  printf 'SocksPort 127.0.0.1:9050\n'
  printf 'ControlPort 127.0.0.1:9051\n'
  printf 'CookieAuthentication 1\n'
  printf 'CookieAuthFile "%s/control_auth_cookie"\n' "$TOR_DATA"
  if [[ -n "$GEOIP_FILE" ]]; then printf 'GeoIPFile "%s"\n' "$GEOIP_FILE"; fi
  if [[ -n "$GEOIP6_FILE" ]]; then printf 'GeoIPv6File "%s"\n' "$GEOIP6_FILE"; fi
  printf 'Log notice file "%s/tor.log"\n' "$TOR_DATA"
} > "$TORRC"
chmod 600 "$TORRC"
"$TOR_BIN" -f "$TORRC" --verify-config

if ! /usr/bin/nc -z 127.0.0.1 9050 >/dev/null 2>&1; then
  echo "Starting Tor on localhost (SOCKS 9050; ControlPort 9051)..."
  nohup "$TOR_BIN" -f "$TORRC" >> "$TOR_DATA/tor-stdout.log" 2>&1 </dev/null &
  echo $! > "$TOR_DATA/tor.pid"
fi
TOR_READY=0
for _ in $(/usr/bin/seq 1 60); do
  if /usr/bin/nc -z 127.0.0.1 9050 >/dev/null 2>&1; then TOR_READY=1; break; fi
  /bin/sleep 1
done
if [[ "$TOR_READY" -ne 1 ]]; then
  echo "ERROR: Tor did not open 127.0.0.1:9050. Check $TOR_DATA/tor.log"
  exit 1
fi

# Create an isolated Python environment and install the browser dependencies.
"$PYTHON" -m venv "$VENV"
"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/python" -m pip install PyQt6 PyQt6-WebEngine 'requests[socks]'

# A reusable launcher starts Tor again after a Mac restart, if necessary.
LAUNCHER="$HOME/Applications/Black Hat.command"
mkdir -p "$HOME/Applications"
cat > "$LAUNCHER" <<LAUNCH
#!/bin/bash
set -euo pipefail
TOR_BIN='$TOR_BIN'
TORRC='$TORRC'
TOR_DATA='$TOR_DATA'
VENV='$VENV'
SCRIPT='$SCRIPT'
if ! /usr/bin/nc -z 127.0.0.1 9050 >/dev/null 2>&1; then
  mkdir -p "\$TOR_DATA"
  nohup "\$TOR_BIN" -f "\$TORRC" >> "\$TOR_DATA/tor-stdout.log" 2>&1 </dev/null &
  for _ in {1..60}; do
    /usr/bin/nc -z 127.0.0.1 9050 >/dev/null 2>&1 && break
    /bin/sleep 1
  done
fi
exec "\$VENV/bin/python" "\$SCRIPT"
LAUNCH
chmod +x "$LAUNCHER"

cat > "$APP_HOME/install-info.txt" <<INFO
Black Hat source: $SCRIPT
Tor binary: $TOR_BIN
Tor config: $TORRC
Python environment: $VENV
Launcher: $LAUNCHER
INFO

printf '\nBLACK HAT INSTALLATION COMPLETE\n'
printf 'Tor SOCKS proxy: 127.0.0.1:9050\n'
printf 'Tor ControlPort: 127.0.0.1:9051 (cookie authentication)\n'
printf 'Python: %s\n' "$("$VENV/bin/python" --version 2>&1)"
printf 'Launcher: %s\n\n' "$LAUNCHER"
printf 'Starting Black Hat now...\n'
exec "$VENV/bin/python" "$SCRIPT"
