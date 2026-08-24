# MDore

[Русская версия](README_RU.md) · [Español](README_ES.md)

[![Build](https://github.com/Mikarmk/MDear/actions/workflows/ci.yml/badge.svg)](https://github.com/Mikarmk/MDear/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/Mikarmk/MDear)](https://github.com/Mikarmk/MDear/releases/latest)
[![License: MIT](https://img.shields.io/badge/license-MIT-black.svg)](LICENSE)

**A quiet, native Markdown editor and reader for macOS.**

MDore opens Markdown as a document, not as code. Write directly on the rendered page, then switch to reading without losing your caret or scroll position.

![MDore reader with multiple tabs](docs/images/reader.png)

## Download

Download the latest installer from [GitHub Releases](https://github.com/Mikarmk/MDear/releases/latest):

- **MDore-macOS.dmg** — recommended installer.
- **MDore-macOS.zip** — portable application archive.

MDore requires macOS 14 or newer and works on both Apple Silicon and Intel Macs.

## Install

1. Download and open `MDore-macOS.dmg`.
2. Drag **MDore** into **Applications**.
3. Read `INSTALL.txt` in the installer if macOS blocks the first launch.
4. On first launch, Control-click MDore and choose **Open**. If needed, use **System Settings → Privacy & Security → Open Anyway**.
5. Choose a language and appearance, then optionally make MDore the default `.md` app.

The first public build is ad-hoc signed but not Apple-notarized, so macOS may require the Control-click → Open step once.

## Features

- Native SwiftUI application with no Electron runtime.
- Visual editing on the rendered document with automatic saving.
- Multiple Markdown files in a compact tab bar.
- Home screen with recent files, new documents, and a built-in guide.
- Four reading themes: Paper, Porcelain, Graphite, and Midnight.
- Automatic live refresh when an open file is saved in another application.
- Interface automatically disappears while scrolling.
- Full-screen reading that respects the MacBook camera area.
- Headers, inline styles, lists, tasks, editable GFM tables, links, images, footnotes, front matter, and table of contents.
- Offline MathJax/LaTeX, Mermaid diagrams, fenced code blocks, and syntax highlighting.
- Outline and sibling-file panels, focus/typewriter modes, image resizing, and PDF/HTML export.
- English, Russian, and Spanish interfaces.
- Custom paper and accent colors, text width, and an optional background photo.
- Managed document folders keep inserted images portable in a local `assets` directory.
- Completely local: no accounts, telemetry, or network requests.

### Tables that belong in the document

MDore 1.1 adds proper GFM tables with alignment, comfortable spacing, theme-aware styling, and contained horizontal scrolling for wide datasets.

![Responsive Markdown tables in MDore](docs/images/tables.png)

## Shortcuts

| Action | Shortcut |
| --- | --- |
| Open one or more files | `⌘O` |
| Close current tab | `⌘W` |
| New document | `⌘N` |
| Save now | `⌘S` |
| Edit mode | `⌘⇧E` |
| Read mode | `⌘⇧P` |
| Refresh current document | `⌘R` |
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

MDore stays deliberately focused: fast launch, excellent typography, local files, and as little permanent interface as possible. It is a document-first Markdown workspace rather than an IDE or collaboration platform.

## License

[MIT](LICENSE)
