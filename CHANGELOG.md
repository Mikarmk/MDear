# Changelog

All notable changes to MDore are documented here.

## 2.0.5 — 2026-08-24

- Removed template-card movement on hover and stabilized hover geometry.
- Added a third structured template, Document Brief, alongside Meeting Notes and Project Plan.
- Fixed native controls and text contrast when switching between light and dark themes.
- Added Japanese, Simplified Chinese, German, French, Portuguese, Hindi, Arabic, and Tatar interface languages.
- Kept the built-in guide current and made the installer sign-off consistent in every existing translation :)

## 2.0.4 — 2026-08-24

- Replaced the legacy lined-document app icon with the new MDore page-mark and coral fold.
- Added a reproducible icon build pipeline from the bundled SVG brand source.

## 2.0.3 — 2026-08-24

- Reworked the DMG installer with a tactile charcoal background and a warm arrow made from Markdown symbols.
- Improved contrast and hierarchy for the drag-to-Applications flow.
- Gave `INSTALL.txt` a dedicated, clearly labeled trilingual area below the main installation action.

## 2.0.2 — 2026-08-24

- Added a focused three-template shelf for blank documents, meeting notes, and project plans.
- Added localized Markdown content for every template in English, Russian, and Spanish.
- Replaced recent-document tiles with a compact list showing name, folder, and modification date.
- Kept all template names, including New Document, on a single line.

## 2.0.1 — 2026-08-24

- Rebuilt the home screen around the adaptive MDore logo, one primary New Document action, and recent documents.
- Added theme-aware logo inversion while preserving the coral brand accent.
- Simplified recent-document rows with clearer paths and restrained hover feedback.
- Moved the built-in guide to the native Help menu to keep the home screen focused.

## 2.0.0 — 2026-08-24

- Added a seamless visual Markdown editor: edit the rendered document without switching to source or a separate preview.
- Added formatting for headings, bold, italic, strike, highlight, underline, inline code, superscript, and subscript.
- Added ordered, unordered, and task lists, quotes, links, dividers, editable tables, and fenced code blocks.
- Added offline MathJax rendering for inline and display LaTeX and offline Mermaid diagram rendering.
- Added syntax highlighting, table of contents, footnotes, front matter, outline navigation, sibling-file navigation, and PDF/HTML export.
- Added automatic saving, external-change conflict handling, and stable reading/caret position between Edit and Read modes.
- Added a document library home screen, recent files, a built-in guide, managed image folders, image resizing, and drag-to-open tabs.
- Added English, Russian, and Spanish interfaces.
- Added custom accent and paper colors, reading width, background photos, focus mode, and typewriter mode.
- Redesigned the DMG installer with a drag-to-Applications layout and trilingual installation instructions.

## 1.1.1 — 2026-08-24

- Added automatic synchronization when an open Markdown file changes on disk.
- Added manual refresh with `⌘R` and a compact sync indicator in the toolbar.
- Preserved the reading position while refreshing document content or appearance.
- Added safe handling for atomic saves and temporarily unavailable files.

## 1.1.0 — 2026-08-24

- Added proper GitHub Flavored Markdown table parsing.
- Added left, center, and right column alignment.
- Redesigned tables with responsive overflow, wider reading space, subtle row separation, and theme-aware hover states.
- Added Setext headings, multiline blockquotes, YAML front matter, hard line breaks, and tilde code fences.
- Added visible language labels to fenced code blocks.
- Added automated renderer regression tests.

## 1.0.0 — 2026-08-24

- Native, read-only Markdown rendering for macOS.
- Multiple documents in a single tab bar.
- Paper, Porcelain, Graphite, and Midnight reading themes.
- In-document search with `⌘F`.
- Distraction-free reading with `⌘⇧R`.
- Automatic interface hiding while scrolling.
- Local Markdown links and images.
- First-launch option to make MDore the default `.md` reader.
- Universal binary for Apple Silicon and Intel Macs.
