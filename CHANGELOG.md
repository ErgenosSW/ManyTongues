# Changelog

## 1.2.1 - 2026-11-24

- Respect the master Enable setting for /ps, /petspeak, /ms and /mountspeak; disabled pet/mount commands no longer send chat or add translation history.
- Cache language-learning requests only after addon communication accepts them, allowing an immediate retry when a blocked request was not sent.
- Add regression tests reproducing both failures; 46 tests pass for each client profile.
- Retain Retail 12.1.5 (Interface 120105) and Forever 1.60.1 (16001) support.
- In-game acceptance checks remain pending.

## 1.2.0 — 2026-11-23

- Queue translation requests individually and validate out-of-order replies by token, sender, channel, frame, language and speech kind.
- Add queue expiry, size limits, chat-line deduplication and conservative handling of overlapping legacy replies.
- Add /manytongues doctor with local session counters and restriction status.
- Add an IC/OOC floating control, commands and optional keybinding; OOC preserves incoming translations and character preferences.
- Add favorite languages, a quick selection list, favorite-first cycling and mouse-wheel navigation.
- Keep the fantasy UI and manual druid animal-language choice.
- Add regression tests for independent translation peers, bursts, duplicates, bounds, mode persistence, favorites and keyboard binding actions.
- Add isolated three-client AceComm/ChatThrottleLib transport tests, randomized message order, duplicate handling, 500-action state checks and optional read-only migration checks against local SavedVariables.
- Real-client acceptance testing remains pending for this version.

## 1.1.1 — 2026-11-22

- Keep the selected language when entering druid forms; offer animal speech through a secondary floating button.
- Clear temporary animal speech on leaving/changing form, selecting a normal language or reloading.

- Use ManyTongues in the addon list, settings category, broker and chat messages.
- Change the main slash command to /manytongues, including help and usage examples.
- Keep original authorship notices in the licensing documentation and source headers.
- Retain the technical folder, saved-variable identifiers and wire protocol for compatibility.

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
