# ManyTongues

[![Tests](https://github.com/ErgenosSW/ManyTongues/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ErgenosSW/ManyTongues/actions/workflows/tests.yml)

A little more character in your chat.

ManyTongues is a continuation of the original **Tongues** roleplay addon for **WoW Retail 12.1.5**. Speak different languages, add dialects and speech effects, and choose how much your character understands - all through a rebuilt settings window.

## Install

1. Download `ManyTongues-1.0.1.zip` from the [latest release](https://github.com/ErgenosSW/ManyTongues/releases/latest) and extract it.
2. Put the extracted **Tongues** folder in `_retail_/Interface/AddOns/`.
3. Enable **Tongues** in the addon list and type `/tongues` in game.

The final path should be:

```text
_retail_/Interface/AddOns/Tongues/Tongues.toc
```

The project is called ManyTongues; the folder and in-game name are still Tongues. Make sure `Tongues.toc` is directly inside the `Tongues` folder, not inside another extracted subfolder.

## Get talking

Open `/tongues`, pick a language on the **Speech** page, and start chatting. Use the preview to try out a dialect or effect before sending anything.

The small button on your screen makes switching easy:

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

Run `python3 tests/check.py` with Python 3.9+ and Lua 5.1 installed. These tests simulate the WoW API; the [in-game checklist](TEST-IN-GAME.md) covers checks in the actual client. See the [changelog](CHANGELOG.md) for changes.

## Retail compatibility

Target: Retail **12.1.5 / Interface 120105**, installed build **70575**.
The chat integration was compared with the Blizzard UI source mirror at
[`15881d522c44cd106d3d8660106ec9f9d2f44167`](https://github.com/Gethe/wow-ui-source/tree/15881d522c44cd106d3d8660106ec9f9d2f44167),
identified there as `12.1.5 (70575)`, on 2026-10-25. The pre-send editbox
implementation is unchanged from the previous 12.1.0 reference; the chat API
documentation differs only in whitespace. No chat-processing rewrite is needed.
Local simulation checks pass; the in-game acceptance checks remain pending.
