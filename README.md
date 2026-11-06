# NoomiMod

A small, native macOS cosmetic-preview companion inspired by NoomiClone. Choose an original free cape style, switch between built-in backgrounds, import an image from your Mac, and export your design as a PNG.

> NoomiMod is an independent fan-made companion. It does not modify the NoomiClone game, connect to player accounts, change save data, or unlock paid in-game items or currency. Its cape styles and previews are local to this app.

## Install on a Mac

Open Terminal and run:

```sh
curl -fL https://raw.githubusercontent.com/ttmeticks-source/Test1/main/install.sh -o /tmp/NoomiMod-install.sh && bash /tmp/NoomiMod-install.sh
```

The installer downloads the source from this repository, builds `NoomiMod.app` on your Mac, and installs it in `/Applications` (or `~/Applications` when needed). It does not require the full Xcode app. It does require Apple's Swift compiler from the standalone Command Line Tools.

## Build manually

```sh
./build.sh
open dist/NoomiMod.app
```

The app supports macOS 12 or later and builds for the Mac's current processor architecture. Imported backgrounds are copied into `~/Library/Application Support/NoomiMod/Backgrounds/`. Selected cape and background settings are remembered locally.

## Features

- Five original free cape palettes: Ember, Ocean, Violet, Mint, and Rose.
- Four built-in backgrounds: Clear Sky, Sunset, Aurora, and Midnight.
- Import a custom image background from your Mac.
- Export the current preview as a PNG.
- Local preferences; no account, network connection, or in-game data access.

## Project files

- `NoomiMod.swift` — native AppKit application.
- `Info.plist` — macOS app bundle metadata.
- `build.sh` — creates `dist/NoomiMod.app` with `swiftc`.
- `install.sh` — curl-friendly source installer.
