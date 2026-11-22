# ManyTongues

[![Tests](https://github.com/ErgenosSW/ManyTongues/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ErgenosSW/ManyTongues/actions/workflows/tests.yml)

A little more character in your chat.

ManyTongues is a continuation of the original **Tongues** roleplay addon for **WoW Retail 12.1.5 and WoW Forever 1.60.1**. Speak different languages, add dialects and speech effects, and choose how much your character understands - all through a rebuilt settings window.

## Install

1. Download `ManyTongues-1.1.0.zip` from the [latest release](https://github.com/ErgenosSW/ManyTongues/releases/latest) and extract it.
2. Put the extracted **Tongues** folder in `_forever_/Interface/AddOns/` for Forever, or `_retail_/Interface/AddOns/` for Retail. The same ZIP supports both clients.
3. Enable **Tongues** in the addon list and type `/tongues` in game.

For Forever, the final path should be:

```text
_forever_/Interface/AddOns/Tongues/Tongues.toc
```

The project is called ManyTongues; the folder and in-game name are still Tongues. Make sure `Tongues.toc` is directly inside the `Tongues` folder, not inside another extracted subfolder.

## Get talking

Open `/tongues`, pick a language on the **Speech** page, and start chatting. Use the preview to try out a dialect or effect before sending anything.

The floating button uses a framed spellbook icon, a gold-lettered nameplate and
the current language. Disabled or restricted speech is shown by a desaturated
icon and an explicit status label. The settings window uses Blizzard panel tabs,
a parchment page, dark ink text and the game's standard buttons and sliders.

The button makes switching easy:

- **Left-click** to cycle through languages you know at 30% fluency or higher.
- **Right-click** to open settings.
- **Drag** to move it. You can hide it in settings, too.

There are four settings pages:

- **Speech** - choose your language, dialect and effects, plus voices for pets, mounts and druid forms.
- **Languages** - add or forget languages, set fluency from 0 to 100, and turn on gradual learning.
- **Channels** - choose where to use your language and where to send readable copies.
- **Translators** - choose players who receive readable copies of your speech.

Settings save automatically. You can also open them from **Settings → AddOns → Tongues**.

## Handy commands

| Command | What it does |
| --- | --- |
| `/tongues` | Open settings |
| `/tongues <language>` | Switch language |
| `/tongues cycle` | Cycle through known languages |
| `/tongues add <language> <0-100>` | Add a language or set fluency |
| `/dialect <name>` | Switch dialect |
| `/ps <text>` | Speak as your pet |
| `/ms <text>` | Speak as your mount |
| `/tongues reset` | Bring the windows back if you lose them |
| `/tongues help` | Show more commands |

## A few things to know

Automatic translations need another compatible Tongues user, and fast conversations can sometimes produce missed or mismatched translations. Your original chat stays visible.

WoW's chat restrictions can temporarily stop addon processing. Chat replacements such as ElvUI still need testing.

Found something broken? Open an issue with what happened, your WoW version, and any Lua error you saw.

## Credits & license

Based on [Tongues by Skrull Adams and Aurorablade/Fethas](https://github.com/Aurorablade/Tongues), with the original dictionaries and contributor credits retained.

The original project declares **GPLv3**. See [LICENSE](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md) for library licenses, dictionary credits and unresolved inherited licensing details. Bundled components keep their own terms.

## Want to tinker?

Run `python3 tests/check.py` with Python 3.9+ and Lua 5.1 installed. The full suite and ten additional locales run under both Retail and Forever build profiles. These tests simulate the WoW API; the [in-game checklist](TEST-IN-GAME.md) covers checks in the actual client. See the [changelog](CHANGELOG.md) for changes.

## Retail compatibility

Target: Retail **12.1.5 / Interface 120105**, installed build **70575**.
The chat integration was compared with the Blizzard UI source mirror at
[`15881d522c44cd106d3d8660106ec9f9d2f44167`](https://github.com/Gethe/wow-ui-source/tree/15881d522c44cd106d3d8660106ec9f9d2f44167),
identified there as `12.1.5 (70575)`, on 2026-10-25. The pre-send editbox
implementation is unchanged from the previous 12.1.0 reference; the chat API
documentation differs only in whitespace. No chat-processing rewrite is needed.
Local simulation checks pass; the in-game acceptance checks remain pending.


## Forever compatibility

Target: **WoW Forever 1.60.1 / Interface 16001**, installed build **71037**.
The shared manifest declares both `120105` and `16001`. Runtime interface
reporting uses `GetBuildInfo()` instead of a hardcoded Retail number.

API reference inspected on 2026-11-22: Blizzard UI source mirror, Forever commit
[`734f065329cff4992835b01a84f210a297db91b6`](https://github.com/Gethe/wow-ui-source/tree/734f065329cff4992835b01a84f210a297db91b6),
identified there as `1.60.1 (71037)`. The pre-send event, message filters,
`C_ChatInfo` messaging/restriction APIs and `C_MountJournal` calls used by
ManyTongues are present. The existing modern chat path is shared by both clients;
there is no fallback to legacy chat hooks.

The same `Tongues2` protocol and SavedVariables schema are retained. Each client
keeps its settings in its own WTF directory; installation does not copy Retail
character settings into Forever. Translation peers must be able to communicate
inside the same game; cross-client/cross-game translation is not provided.
Client acceptance testing remains pending, including two-player translations,
chat restrictions, pets, mounts and druid forms.
