# Tongues — Retail modernization

A community continuation of the Tongues roleplay addon for World of Warcraft.
Speak fictional languages, apply dialects and speech effects, and configure
character fluency through a rebuilt graphical interface.

Development build `2.0.0-dev`, targeting **Retail 12.1.0 / Interface 120100**.
This supersedes the installation and configuration sections of the historical `ReadMe.txt`.

## Install and open

1. Close WoW and keep a copy of the existing `Interface/AddOns/Tongues` folder and Tongues SavedVariables if upgrading.
2. For a GitHub source download, rename the extracted repository folder to `Tongues`. Install it so that `_retail_/Interface/AddOns/Tongues/Tongues.toc` exists, without an additional nested Tongues folder.
3. Enable Tongues and log in. Enter `/tongues` or open **Settings → AddOns → Tongues**.
4. The floating button cycles languages on left-click and opens settings on right-click. Drag it to move it.

Existing character fluency, selected language, dialect, speech effect, filter, translation recipients, channel preferences and window positions are migrated in place. Malformed values receive defaults. Position migration removes frame references from SavedVariables. The schema remains in `Tongues_Character`; `Tongues_Global` is preserved.

## Settings

- **Speech:** enable/disable processing; select a language, dialect, effect and effect frequency; choose the Roleplay filter; configure druid/pet/mount language overrides; hide the floating button; preview `/say` text locally.
- **Languages:** searchable selection, fluency from 0 to 100, forget a language, choose the spoken language and enable gradual learning. Changes save immediately. Languages at 30% or more enter the button cycle.
- **Channels:** choose which channels remain readable and which recipients receive extra readable copies. Group/guild destinations require membership; raid warnings require leadership/assist. Personal whispers are not copied to the translator list or other channels.
- **Translators:** add and remove `Name-Realm` recipients.

The main window, language chooser and longer pages scroll. Escape closes windows. `/tongues reset` restores positions. The UI scales down to fit smaller screens. UI captions are English; the original language data localization is retained (including repaired French/esMX selection).

Commands: `/tongues [language]`, `opt`, `cycle`, `add <language> <0-100>`, `remove <language>`, `dialect <name>`, `affect <name> [0-100]`, `roleplay`, `shapeshift [true|false]`, `translate <Name-Realm>`, `reset`, `list`, `help`. Multiword names are accepted. `/dialect`, `/petspeak` (`/ps`) and `/mountspeak` (`/ms`) remain available.

Unknown mount/pet families use the chosen language unless an explicit override is selected. Automatic druid selection uses form spell IDs; custom barber appearances can be assigned an explicit form language.

## Integration and changed behavior

- Outgoing text uses Blizzard's `ChatFrame.OnEditBoxPreSendText` event. No global chat sender or frame handler is replaced. The normal Blizzard chat path performs the actual send.
- Incoming text uses `ChatFrameUtil.AddMessageEventFilter`; complete trailing event arguments survive filtering.
- Links, texture/atlas markup and UTF-8 text are kept intact. An overlong transformed message is sent unchanged with a local explanation instead of cutting its bytes or splitting protected links.
- Native language IDs are read from the client. Non-native languages use the existing dictionaries and `[Language]` tags.
- During chat messaging lockdown or when event values are secret, processing and new addon communication requests are skipped. This is required by the game; the addon does not bypass restrictions.
- `Tongues2` requests/replies retain their legacy field positions. Additional wire-text/request tokens correlate replies between modernized clients. Invalid, unsolicited and expired replies are discarded. Learning increments are bounded and cooldowns expire.
- Original incoming messages stay visible. Translations appear as additional labeled lines, so a missing, delayed or older peer cannot swallow chat.
- For native languages scrambled by the server, and legacy peers without correlation fields, reply matching is best effort against recent speech. Rapid successive messages can therefore remain untranslated or receive the latest available translation; this old protocol has no server message identifier.
- Compatibility with third-party chat replacements (including ElvUI) requires an in-client check: addons that bypass Blizzard's pre-send event are not intercepted.
- Legacy unused UI libraries and historical files remain in the source tree but are not in the active manifest.

## Verification

Run `python3 tests/check.py` with Python 3.9+ and Lua 5.1 tools installed.

The checks load the actual manifest and embedded libraries under a WoW API mock that intentionally omits removed global APIs. They exercise lifecycle, migration, every dictionary/dialect/effect, commands, native/custom speech, links, long words, secrets and lockdown, translations, malformed packets, request correlation, private-recipient checks, learning, pet/mount behavior and GUI callbacks. Ten additional client locales run bootstrap/data checks. These are **simulation tests**, not a WoW client or visual rendering test. They cannot certify secure execution, layout, throttling or interoperability in the real client.

A user has reported a successful fresh installation and working UI; this is a smoke-test report, not completion of the full acceptance matrix.

Before considering the build fully verified, run the acceptance steps in `TEST-IN-GAME.md`.

## Source and attribution

Based on Aurorablade/Tongues commit `649fc6c3c52aafec38d5ceb265891a2b1c782e80`. Original dictionaries and their authorship notices are retained. The original project declares GPLv3 on CurseForge. See [LICENSE](LICENSE) for the full text and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for library licenses, inherited dictionary notices and unresolved historical licensing questions. Bundled components are not all covered by one license.

API reference: Blizzard UI source mirror, `Gethe/wow-ui-source` live commit `4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59`, described by upstream as `12.1.0 (69814)`, inspected 2026-09-13.

- [Pre-send event](https://github.com/Gethe/wow-ui-source/blob/4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua)
- [Message filters](https://github.com/Gethe/wow-ui-source/blob/4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameFilters.lua)
- [Chat restrictions](https://github.com/Gethe/wow-ui-source/blob/4e3cbb8c5609e4bfc332c0aebbfa4d79731fab59/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua)

AceComm (minor 14), ChatThrottleLib (32) and AceSerializer were refreshed from WoWUIDev/Ace3 master, inspected at `88e0a1733fcfc8b8f09dd86ae71eee7a780c2980`. Library headers remain intact. LibStub, CallbackHandler, LibDataBroker and LibBabble retain their bundled upstream versions and notices.

## Tongues Reforged

This is an independent continuation of the original Tongues source. Reforged code
is not included. Our addon uses the `Tongues2` communication prefix; Reforged
1.0.3 uses `TonguesReforged`. Automatic peer translations and peer learning do not
currently interoperate between them. Normal chat remains visible.

## Project layout

- `Tongues.toc`: load order and client version.
- `Tongues.lua`, `comm.lua`: lifecycle, commands and peer communication.
- `Core/Engine.lua`, `Core/UI.lua`: speech processing and settings interface.
- Other `Core/` data files and `locales.lua`: inherited dictionaries and localization.
- `libs/`: embedded dependencies, including retained inactive legacy libraries.
- `tests/`, `TEST-IN-GAME.md`: automated checks and client acceptance checklist.
- `LICENSE`, `LICENSES/`, `THIRD_PARTY_NOTICES.md`: terms and provenance.

## Reporting problems

Include your game version, addon version, client language, reproduction steps,
and the Lua error text if available. For UI issues, include the screen resolution
and UI scale. Do not include private chat logs or account information.
