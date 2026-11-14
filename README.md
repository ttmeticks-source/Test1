# Black Hat — PyQt6 privacy browser

Black Hat is an open-source macOS browser prototype built with Python 3, PyQt6, and PyQt6-WebEngine. It focuses on defensive privacy controls, request filtering, download quarantine, and an optional Tor connection.

## One-line install (curl only; no Homebrew)

Open Terminal and paste:

```bash
curl -fsSL https://raw.githubusercontent.com/ttmeticks-source/Test1/main/install.sh | bash
```

The installer downloads the compressed Python source from this repository, verifies its SHA-256, expands it locally, installs a Python runtime only when needed, downloads the Tor Expert Bundle for the Mac's CPU architecture, verifies that archive, creates a virtual environment, installs PyQt6 dependencies, and creates `~/Applications/Black Hat.command`.

The first install may ask for the macOS administrator password if Python needs to be installed. No Homebrew or Xcode is used.

## Launch later

```bash
"$HOME/Applications/Black Hat.command"
```

## Download source manually

```bash
curl -fL https://raw.githubusercontent.com/ttmeticks-source/Test1/main/blackhat.py.gz -o blackhat.py.gz
gzip -dc blackhat.py.gz > blackhat.py
```

## Source files

- `blackhat.py.gz` — gzip-compressed, plain-text single-file PyQt6 browser source. The installer expands it to `blackhat.py`.
- `install.sh` — curl-piped macOS installer.
- `LICENSE` — MIT license.

## Security notes

- Uses an unnamed/off-the-record `QWebEngineProfile`; cookies and cache are not persisted by the browser profile.
- Browser traffic is configured to use a local Tor SOCKS5 proxy. The app checks the Tor Project status endpoint before treating the route as verified.
- Plain HTTP requests are blocked or upgraded to HTTPS where possible.
- Domain-level tracker rules are loaded from EasyList/EasyPrivacy when the Tor proxy is available. This is not a complete Adblock Plus parser.
- Downloads are held in a private temporary quarantine directory and hashed with SHA-256. VirusTotal hash lookups are optional and require the user's own `VT_API_KEY`; downloads are not uploaded by the app.
- Unknown files remain unverified. A clean or missing reputation result is not proof that a file is safe.
- Reset Session clears the current in-memory browser profile and requests Tor `SIGNAL NEWNYM` using the local cookie-authenticated ControlPort. Tor may not provide a different exit IP each time.
- This prototype does not guarantee anonymity and is not a replacement for the Tor Browser security model.

## VirusTotal (optional)

```bash
export VT_API_KEY='YOUR_OWN_API_KEY'
"$HOME/Applications/Black Hat.command"
```

The key is read from the environment. The app performs hash reputation lookups; it does not upload downloaded files.

## License

MIT. See `LICENSE`.
