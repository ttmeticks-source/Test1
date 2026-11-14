#!/bin/bash
set -euo pipefail

# Black Hat macOS installer + native .app builder. No Homebrew or Xcode.
# Usage: curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Test1/main/install.sh | bash

APP_HOME="$HOME/Library/Application Support/BlackHat"
SOURCE_HOME="$APP_HOME/source"
SCRIPT="$SOURCE_HOME/blackhat.py"
TOR_HOME="$APP_HOME/TorBundle"
VENV="$APP_HOME/venv"
BUILD_HOME="$APP_HOME/build"
TMP_DIR="$(mktemp -d)"
TOR_VERSION="16.0.1"
RAW_BASE_URL="https://raw.githubusercontent.com/ttmeticks-source/Test1/main"
SOURCE_SHA256="0d31ea110a182c323d3b3f61739af76642168b0b08ab957e547fb1dce1ba07c9"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "ERROR: Black Hat is designed for macOS."
  exit 1
fi

mkdir -p "$APP_HOME" "$SOURCE_HOME"
chmod 700 "$APP_HOME" "$SOURCE_HOME"

# Download and verify the browser source.
echo "[1/7] Downloading Black Hat source..."
SOURCE_ARCHIVE="$TMP_DIR/blackhat.py.gz"
curl -fL --retry 3 --retry-delay 2 "$RAW_BASE_URL/blackhat.py.gz" -o "$SOURCE_ARCHIVE"
ACTUAL_SOURCE_SHA256="$(/usr/bin/shasum -a 256 "$SOURCE_ARCHIVE" | /usr/bin/awk '{print $1}')"
if [[ "$ACTUAL_SOURCE_SHA256" != "$SOURCE_SHA256" ]]; then
  echo "ERROR: Black Hat source SHA-256 verification failed."
  exit 1
fi
/usr/bin/gzip -dc "$SOURCE_ARCHIVE" > "$SCRIPT"

# Select the matching Tor Expert Bundle.
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

# Find Python 3.10+ or download the official universal macOS installer.
PYTHON="$(command -v python3 || true)"
PYTHON_OK=0
if [[ -n "$PYTHON" ]] && "$PYTHON" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,10) else 1)' >/dev/null 2>&1; then
  PYTHON_OK=1
fi
if [[ "$PYTHON_OK" -ne 1 ]]; then
  echo "Python 3.10+ not found. Downloading Python 3.13.17..."
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

# Reuse the existing extracted Tor bundle; otherwise download and verify it.
TOR_BIN="$TOR_HOME/tor/tor"
if [[ ! -f "$TOR_BIN" ]]; then TOR_BIN="$TOR_HOME/tor/tor.real"; fi
if [[ ! -f "$TOR_BIN" ]]; then
  echo "[2/7] Downloading verified Tor Expert Bundle for $ARCH..."
  TOR_ARCHIVE="tor-expert-bundle-macos-$TOR_ARCH-$TOR_VERSION.tar.gz"
  TOR_TARBALL="$TMP_DIR/$TOR_ARCHIVE"
  curl -fL --retry 3 --retry-delay 2 \
    "https://dist.torproject.org/torbrowser/$TOR_VERSION/$TOR_ARCHIVE" \
    -o "$TOR_TARBALL"
  ACTUAL_TOR_SHA256="$(/usr/bin/shasum -a 256 "$TOR_TARBALL" | /usr/bin/awk '{print $1}')"
  if [[ "$ACTUAL_TOR_SHA256" != "$TOR_SHA256" ]]; then
    echo "ERROR: Tor bundle SHA-256 verification failed."
    echo "Expected: $TOR_SHA256"
    echo "Received: $ACTUAL_TOR_SHA256"
    exit 1
  fi
  rm -rf "$TOR_HOME"
  mkdir -p "$TOR_HOME"
  /usr/bin/tar -xzf "$TOR_TARBALL" -C "$TOR_HOME"
fi

TOR_BIN="$TOR_HOME/tor/tor"
if [[ ! -f "$TOR_BIN" ]]; then TOR_BIN="$TOR_HOME/tor/tor.real"; fi
if [[ ! -f "$TOR_BIN" ]]; then
  TOR_BIN="$(/usr/bin/find -L "$TOR_HOME" -type f -name tor -print -quit)"
fi
if [[ -z "$TOR_BIN" || ! -f "$TOR_BIN" ]]; then
  echo "ERROR: Tor daemon was not found. Bundle contents:"
  /usr/bin/find "$TOR_HOME" -maxdepth 4 -print | /usr/bin/head -100
  exit 1
fi
chmod +x "$TOR_BIN"
if ! "$TOR_BIN" --version >/dev/null 2>&1; then
  echo "ERROR: Tor binary did not pass its local launch check."
  "$TOR_BIN" --version 2>&1 || true
  exit 1
fi
echo "Tor binary found and version check passed."

# Install all Python requirements into a private virtual environment.
echo "[3/7] Installing PyQt6, Qt WebEngine, requests and PyInstaller..."
"$PYTHON" -m venv "$VENV"
"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/python" -m pip install --upgrade PyQt6 PyQt6-WebEngine 'requests[socks]' 'pyinstaller>=6.22.3'

# The Tor status display retries more frequently while the circuit bootstraps.
"$VENV/bin/python" - "$SCRIPT" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text(encoding="utf-8")
s = s.replace("time.time() - self._last_ip_check > 60", "time.time() - self._last_ip_check > 15")
p.write_text(s, encoding="utf-8")
PY

# Create a crisp Black Hat icon using Qt's raster painter; no extra tools required.
echo "[4/7] Creating application icon..."
cat > "$TMP_DIR/make_icon.py" <<'PY'
import os, sys
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
from PyQt6.QtCore import Qt, QRectF
from PyQt6.QtGui import QGuiApplication, QImage, QPainter, QColor, QPen, QFont
app = QGuiApplication([])
image = QImage(1024, 1024, QImage.Format.Format_ARGB32_Premultiplied)
image.fill(QColor("#080c0b"))
p = QPainter(image)
p.setRenderHint(QPainter.RenderHint.Antialiasing, True)
p.setBrush(QColor("#101715"))
p.setPen(QPen(QColor("#00ff9d"), 22))
p.drawRoundedRect(QRectF(54, 54, 916, 916), 210, 210)
p.setPen(QColor("#00ff9d"))
font = QFont("Menlo")
font.setBold(True)
font.setPointSize(270)
p.setFont(font)
p.drawText(QRectF(0, 30, 1024, 964), Qt.AlignmentFlag.AlignCenter, "BH")
p.end()
if not image.save(sys.argv[1], "PNG"):
    raise SystemExit("Could not write icon PNG")
PY
"$VENV/bin/python" "$TMP_DIR/make_icon.py" "$TMP_DIR/BlackHat.png"
ICONSET="$TMP_DIR/BlackHat.iconset"
mkdir -p "$ICONSET"
sips -z 16 16 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -z 32 32 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -z 64 64 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -z 256 256 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -z 512 512 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$TMP_DIR/BlackHat.png" --out "$ICONSET/icon_512x512.png" >/dev/null
cp "$TMP_DIR/BlackHat.png" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$TMP_DIR/BlackHat.icns"

# Runtime hook: launch the Tor daemon from inside the .app before Qt starts.
# The hook does not disable Gatekeeper or clear quarantine attributes.
cat > "$TMP_DIR/tor_runtime_hook.py" <<'PY'
import atexit
import os
import socket
import subprocess
import sys
import time
from pathlib import Path

APP_HOME = Path.home() / "Library" / "Application Support" / "BlackHat"
TOR_DATA = APP_HOME / "TorData"
TOR_DATA.mkdir(parents=True, exist_ok=True, mode=0o700)
try:
    TOR_DATA.chmod(0o700)
except OSError:
    pass


def port_is_open(host="127.0.0.1", port=9050):
    try:
        with socket.create_connection((host, port), timeout=0.4):
            return True
    except OSError:
        return False


_owned_tor = None
_log_handle = None
if not port_is_open():
    resources = Path(sys.executable).resolve().parent.parent / "Resources"
    tor_root = resources / "TorBundle"
    candidates = [tor_root / "tor" / "tor", tor_root / "tor" / "tor.real"]
    tor_binary = next((p for p in candidates if p.is_file()), None)
    if tor_binary is None:
        for candidate in tor_root.rglob("tor") if tor_root.exists() else ():
            if candidate.is_file() and candidate.name == "tor":
                tor_binary = candidate
                break
    if tor_binary is not None:
        try:
            tor_binary.chmod(tor_binary.stat().st_mode | 0o111)
            geoip = tor_root / "data" / "geoip"
            geoip6 = tor_root / "data" / "geoip6"
            config = [
                f'DataDirectory "{TOR_DATA}"',
                "SocksPort 127.0.0.1:9050",
                "ControlPort 127.0.0.1:9051",
                "CookieAuthentication 1",
                f'CookieAuthFile "{TOR_DATA / "control_auth_cookie"}"',
                "Log notice stdout",
                "SafeLogging 1",
            ]
            if geoip.is_file():
                config.append(f'GeoIPFile "{geoip}"')
            if geoip6.is_file():
                config.append(f'GeoIPv6File "{geoip6}"')
            torrc = APP_HOME / "torrc"
            torrc.write_text("\n".join(config) + "\n", encoding="utf-8")
            try:
                torrc.chmod(0o600)
            except OSError:
                pass
            check = subprocess.run(
                [str(tor_binary), "-f", str(torrc), "--verify-config"],
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=10, text=True,
            )
            log_path = TOR_DATA / "tor-stdout.log"
            _log_handle = open(log_path, "a", encoding="utf-8")
            _log_handle.write(check.stdout or "")
            _log_handle.flush()
            if check.returncode == 0:
                _owned_tor = subprocess.Popen(
                    [str(tor_binary), "-f", str(torrc)],
                    stdin=subprocess.DEVNULL,
                    stdout=_log_handle,
                    stderr=subprocess.STDOUT,
                    start_new_session=True,
                    close_fds=True,
                )
                for _ in range(120):
                    if _owned_tor.poll() is not None or port_is_open():
                        break
                    time.sleep(0.5)
            else:
                _log_handle.write("Tor config verification failed; inspect tor-stdout.log.\n")
                _log_handle.flush()
        except Exception as exc:
            try:
                (TOR_DATA / "tor-stdout.log").write_text(
                    f"Could not start bundled Tor: {type(exc).__name__}: {exc}\n",
                    encoding="utf-8",
                )
            except OSError:
                pass


def _stop_owned_tor():
    global _owned_tor, _log_handle
    if _owned_tor is not None and _owned_tor.poll() is None:
        try:
            _owned_tor.terminate()
            _owned_tor.wait(timeout=5)
        except Exception:
            try:
                _owned_tor.kill()
            except Exception:
                pass
    _owned_tor = None
    if _log_handle is not None:
        try:
            _log_handle.close()
        except Exception:
            pass
    _log_handle = None


atexit.register(_stop_owned_tor)
PY

# Create a real macOS .app bundle with its own Python/Qt runtime.
echo "[5/7] Building Black Hat.app (this may take several minutes)..."
rm -rf "$BUILD_HOME"
mkdir -p "$BUILD_HOME/dist" "$BUILD_HOME/work" "$BUILD_HOME/spec"
"$VENV/bin/pyinstaller" \
  --noconfirm --clean --windowed --onedir \
  --name "Black Hat" \
  --osx-bundle-identifier "com.ttmeticks.blackhat" \
  --icon "$TMP_DIR/BlackHat.icns" \
  --runtime-hook "$TMP_DIR/tor_runtime_hook.py" \
  --hidden-import socks \
  --hidden-import urllib3.contrib.socks \
  --collect-all PyQt6.QtWebEngineCore \
  --collect-all PyQt6.QtWebEngineWidgets \
  --distpath "$BUILD_HOME/dist" \
  --workpath "$BUILD_HOME/work" \
  --specpath "$BUILD_HOME/spec" \
  "$SCRIPT"

APP_BUILD="$BUILD_HOME/dist/Black Hat.app"
if [[ ! -d "$APP_BUILD/Contents/MacOS" ]]; then
  echo "ERROR: PyInstaller did not produce Black Hat.app."
  exit 1
fi

# Bundle the Tor Expert Bundle into the app so it can start Tor by itself.
echo "[6/7] Embedding Tor and finalizing the app bundle..."
mkdir -p "$APP_BUILD/Contents/Resources"
rm -rf "$APP_BUILD/Contents/Resources/TorBundle"
ditto "$TOR_HOME" "$APP_BUILD/Contents/Resources/TorBundle"
PLIST="$APP_BUILD/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName Black Hat' "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string Black Hat' "$PLIST"
/usr/libexec/PlistBuddy -c 'Set :LSApplicationCategoryType public.app-category.utilities' "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c 'Add :LSApplicationCategoryType string public.app-category.utilities' "$PLIST"
/usr/libexec/PlistBuddy -c 'Set :NSHighResolutionCapable true' "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c 'Add :NSHighResolutionCapable bool true' "$PLIST"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIconFile BlackHat.icns' "$PLIST" 2>/dev/null || /usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string BlackHat.icns' "$PLIST"
cp "$TMP_DIR/BlackHat.icns" "$APP_BUILD/Contents/Resources/BlackHat.icns"

# Apply an ad-hoc local code signature. This is not a Developer ID signature
# and does not count as Apple notarization.
/usr/bin/codesign --force --deep --sign - --timestamp=none "$APP_BUILD"
/usr/bin/codesign --verify --deep --strict "$APP_BUILD"

# Install into the user's Applications folder, without needing admin rights.
echo "[7/7] Installing Black Hat.app into ~/Applications..."
mkdir -p "$HOME/Applications"
APP_DEST="$HOME/Applications/Black Hat.app"
rm -rf "$APP_DEST"
rm -f "$HOME/Applications/Black Hat.command"
ditto "$APP_BUILD" "$APP_DEST"
/usr/bin/codesign --verify --deep --strict "$APP_DEST"

cat > "$APP_HOME/install-info.txt" <<INFO
Application: $APP_DEST
Tor bundle: $APP_DEST/Contents/Resources/TorBundle
Tor data: $APP_HOME/TorData
Tor log: $APP_HOME/TorData/tor-stdout.log
Python environment used for build: $VENV
INFO

printf '\nBLACK HAT APP BUILD COMPLETE\n'
printf 'Application: %s\n' "$APP_DEST"
printf 'Architecture: %s\n' "$ARCH"
printf 'Tor is bundled and launched by the app.\n'
printf 'Opening Black Hat...\n'
open "$APP_DEST"
