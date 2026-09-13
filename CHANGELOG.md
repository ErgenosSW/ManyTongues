# Changelog

## 2.0.0-dev — 2026-09-13

- Target Retail 12.1.0 (Interface 120100).
- Rebuild speech processing, lifecycle, commands and translation communication.
- Replace the settings UI with four scrolling pages and searchable selections.
- Use a compact 130 × 36 floating language button.
- Preserve and migrate existing character settings and retain original dictionaries.
- Update AceComm, AceSerializer and ChatThrottleLib.
- Respect chat restrictions, validate peer packets and preserve private recipients.
- Add automated Lua/API simulation tests and an in-game acceptance checklist.
- Document installation, upstream provenance, component licenses and unresolved
  inherited licensing questions.

Modified modernization files: Tongues.lua, comm.lua, Core/libs.lua, Core/UI.lua,
locales.lua, Tongues.toc; new engine: Core/Engine.lua. Updated library files:
libs/AceComm-3.0/AceComm-3.0.lua, libs/AceComm-3.0/ChatThrottleLib.lua,
libs/AceSerializer-3.0/AceSerializer-3.0.lua. Original Git history is retained.
