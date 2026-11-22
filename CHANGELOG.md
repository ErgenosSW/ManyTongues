# Changelog

## 1.1.0 — 2026-11-22

- Restyle the settings and chooser with Blizzard panel tabs, parchment pages and dark ink text.
- Replace the floating button with a framed spellbook icon and a gold-lettered nameplate, including visible disabled/restricted states.
- Add WoW Forever 1.60.1 support (Interface 16001, reference build 71037).
- Keep Retail 12.1.5 support in the same installable package.
- Read the runtime interface from the client instead of hardcoding Retail.
- Run the full regression suite and ten additional locales for each client profile.
- Retain the existing chat protocol, dictionaries and settings schema.
- Document Forever installation, API provenance and separate client acceptance checks.
- In-game validation remains pending.

## 1.0.1 — 2026-10-25

- Target Retail 12.1.5 (Interface 120105), build 70575.
- Verify the pre-send chat integration and chat API documentation against the
  matching Blizzard UI source mirror; no processing changes are required.
- Refresh the installation version and in-game acceptance target.
- Local syntax, manifest, 25 regression checks and 10 additional locale checks
  pass. In-client acceptance remains pending.

## 1.0 — 2026-09-13

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
