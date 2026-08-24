# MDore

[Русская версия](README_RU.md)

[![Build](https://github.com/Mikarmk/MDear/actions/workflows/ci.yml/badge.svg)](https://github.com/Mikarmk/MDear/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/Mikarmk/MDear)](https://github.com/Mikarmk/MDear/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-black.svg)](LICENSE)

**A quiet, native Markdown reader for macOS.**

MDore opens Markdown as a document, not as code. It is designed for specifications, meeting notes, documentation, guides, and README files that deserve a calm reading surface outside an IDE.

![MDore reader with multiple tabs](docs/images/reader.png)

## Download

Download the latest installer from [GitHub Releases](https://github.com/Mikarmk/MDear/releases/latest):

- **MDore-macOS.dmg** — recommended installer.
- **MDore-macOS.zip** — portable application archive.

MDore requires macOS 14 or newer and works on both Apple Silicon and Intel Macs.

## Install

1. Download and open `MDore-macOS.dmg`.
2. Drag **MDore** into **Applications**.
3. On first launch, Control-click MDore and choose **Open**.
4. Choose a reading theme and optionally make MDore the default `.md` reader.

The first public build is ad-hoc signed but not Apple-notarized, so macOS may require the Control-click → Open step once.

![Theme selection and default-reader setup](docs/images/welcome.png)

## Features

- Native SwiftUI application with no Electron runtime.
- Multiple Markdown files in a compact tab bar.
- Four reading themes: Paper, Porcelain, Graphite, and Midnight.
- Interface automatically disappears while scrolling.
- Full-screen reading that respects the MacBook camera area.
- Search, relative Markdown links, local images, task lists, code blocks, and Cyrillic text.
- Read-only by design: MDore never changes the opened document.
- Completely local: no accounts, telemetry, or network requests.

## Shortcuts

| Action | Shortcut |
| --- | --- |
| Open one or more files | `⌘O` |
| Close current tab | `⌘W` |
| Search | `⌘F` |
| Find next | `⌘G` |
| Distraction-free reading | `⌘⇧R` |
| Increase / decrease text | `⌘+` / `⌘−` |
| Reset text size | `⌘0` |

## Build from source

Install Xcode Command Line Tools, then run:

```bash
git clone https://github.com/Mikarmk/MDear.git
cd MDear
make build
```

The build produces:

```text
build/MDore.app
dist/MDore-macOS.zip
dist/MDore-macOS.dmg
```

The executable is a universal `arm64 + x86_64` binary targeting macOS 14 and newer.

## Releasing

Push a semantic version tag such as `v1.0.0`. GitHub Actions builds the universal app and publishes both downloadable artifacts automatically.

## Project principles

MDore stays deliberately small: instant launch, excellent typography, local files, and as little interface as possible. It is a reader rather than an editor, file manager, IDE, or collaboration platform.

## License

[MIT](LICENSE)
