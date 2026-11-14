# Black Hat — macOS privacy browser

Black Hat is an open-source macOS browser prototype built with Python 3, PyQt6, and PyQt6-WebEngine. It focuses on defensive privacy controls, request filtering, download quarantine, and routing browser traffic through a locally bundled Tor daemon.

## Install and build the native `.app` (curl only)

Open Terminal and paste:

```bash
curl -fsSL "https://raw.githubusercontent.com/ttmeticks-source/Test1/main/install.sh" | bash
```

No Homebrew or Xcode is used. The installer uses `curl`, the official Python macOS installer if needed, a checksum-verified Tor Expert Bundle, pip, and PyInstaller. It builds a normal macOS application bundle at:

```text
~/Applications/Black Hat.app
```

You can open it from Finder, Spotlight, Launchpad, or Terminal:

```bash
open "$HOME/Applications/Black Hat.app"
```

The app bundle contains the PyInstaller-packaged Python/Qt application and the Tor Expert Bundle in `Contents/Resources/TorBundle`. A PyInstaller runtime hook starts Tor on localhost before the browser opens. The app stops only the Tor process it started when the browser exits.

## What the installer does

1. Downloads `blackhat.py.gz` from this repository and verifies its SHA-256.
2. Installs Python 3.10+ only if there is no suitable Python already installed.
3. Downloads the correct Tor Expert Bundle for Apple Silicon or Intel and verifies its SHA-256, or reuses the already extracted bundle.
4. Installs PyQt6, PyQt6-WebEngine, requests with SOCKS support, and PyInstaller in a private virtual environment.
5. Builds and code-signs the local app bundle with an ad-hoc signature, verifies the signature, and copies it to `~/Applications`.
6. Opens Black Hat.

## Tor status

The app does not fake the Tor status. It displays `TOR: VERIFIED` only when the Tor Project check endpoint confirms the exit. A reachable local SOCKS port alone is not enough; while Tor is bootstrapping or the verification endpoint is unreachable, the display can remain `TOR: VERIFYING` or `TOR: UNVERIFIED`.

The bundled Tor daemon listens only on `127.0.0.1:9050` (SOCKS) and `127.0.0.1:9051` (ControlPort). The ControlPort uses cookie authentication. Reset Session asks Tor for a new circuit; Tor does not guarantee a different exit IP for every request.

## macOS signing and Gatekeeper

The installer applies an **ad-hoc** signature so the local app bundle has a consistent code signature. Ad-hoc signing is not a Developer ID identity and is not Apple notarization. A Developer ID signature and notarization require the publisher's Apple developer credentials; this project does not remove quarantine attributes or turn off Gatekeeper. If macOS presents a first-open approval dialog, use the normal Finder **Control-click → Open** flow only after reviewing that you installed this project from the repository above.

## Security notes

- Uses an unnamed/off-the-record `QWebEngineProfile`; browser cookies and HTTP cache are not persisted by the profile.
- Browser navigation is blocked until the configured proxy is verified as a Tor exit.
- Plain HTTP requests are blocked; HTTPS is required.
- The filter implementation uses domain-level EasyList/EasyPrivacy rules, not every advanced cosmetic or contextual rule.
- Downloads remain in a private temporary quarantine, are hashed with SHA-256, and may receive an optional VirusTotal hash reputation lookup if `VT_API_KEY` is set. Files are not uploaded by the app.
- Unknown results remain quarantined. A missing report or zero detections is not proof that a file is safe.
- This prototype does not guarantee anonymity and is not a replacement for Tor Browser or a security audit.

## Source files

- `blackhat.py.gz` — compressed single-file PyQt6 browser source.
- `install.sh` — one-command macOS installer and `.app` builder.
- `LICENSE` — MIT license.

## License

MIT. See `LICENSE`.
