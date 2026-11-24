# ManyTongues

[![Tests](https://github.com/ErgenosSW/ManyTongues/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/ErgenosSW/ManyTongues/actions/workflows/tests.yml)

A little more character in your chat.

ManyTongues is a roleplay addon for **WoW Retail 12.1.5 and WoW Forever 1.60.1**. Speak different languages, add dialects and speech effects, and choose how much your character understands - all through a rebuilt settings window.

## Install

1. Download `ManyTongues-1.2.1.zip` from the [latest release](https://github.com/ErgenosSW/ManyTongues/releases/latest) and extract it.
2. Put the extracted **Tongues** folder in `_forever_/Interface/AddOns/` for Forever, or `_retail_/Interface/AddOns/` for Retail. The same ZIP supports both clients.
3. Enable **ManyTongues** in the addon list and type `/manytongues` in game.

For Forever, the final path should be:

```text
_forever_/Interface/AddOns/Tongues/Tongues.toc
```

The in-game name is ManyTongues. The technical installation folder remains `Tongues` to preserve existing saved settings. Make sure `Tongues.toc` is directly inside that folder, not inside another extracted subfolder.

## Get talking

Open `/manytongues`, pick a language on the **Speech** page, and start chatting. Use the preview to try out a dialect or effect before sending anything.

The floating button uses a framed spellbook icon, a gold-lettered nameplate and
the current language. Disabled or restricted speech is shown by a desaturated
icon and an explicit status label. The settings window uses Blizzard panel tabs,
a parchment page, dark ink text and the game's standard buttons and sliders.

The button makes switching easy:

- **Left-click** to cycle favorites; when there are none, cycle languages known at 30% fluency or higher.
- **Mouse wheel** to cycle forward or backward.
- **Shift-left-click or middle-click** to open the language list. Use **+** to favorite a language or ***** to remove it.
- **IC/OOC button** beside the language button to toggle outgoing roleplay speech. Incoming translations keep working in OOC.
- **Right-click** to open settings.
- **Drag** to move it. You can hide it in settings, too.

There are four settings pages:

- **Speech** - choose your language, dialect and effects, plus voices for pets, mounts and an optional animal voice for druid forms.
- **Languages** - add or forget languages, set fluency from 0 to 100, and turn on gradual learning.
- **Channels** - choose where to use your language and where to send readable copies.
- **Translators** - choose players who receive readable copies of your speech.

Settings save automatically. You can also open them from **Settings → AddOns → ManyTongues**.

## Handy commands

| Command | What it does |
| --- | --- |
| `/manytongues` | Open settings |
| `/manytongues <language>` | Switch language |
| `/manytongues cycle` | Cycle through favorites, or known languages if none are favorited |
| `/manytongues ic` / `ooc` / `toggle` | Set or toggle outgoing roleplay speech |
| `/manytongues favorites` | Open the language list with favorite controls |
| `/manytongues favorite [language]` | Toggle a favorite; defaults to the selected language |
| `/manytongues doctor` | Print local session diagnostics without message contents |
| `/manytongues add <language> <0-100>` | Add a language or set fluency |
| `/dialect <name>` | Switch dialect |
| `/ps <text>` | Speak as your pet |
| `/ms <text>` | Speak as your mount |
| `/manytongues reset` | Bring the windows back if you lose them |
| `/manytongues help` | Show more commands |

## A few things to know

Automatic translations need another compatible ManyTongues user, and fast conversations can sometimes produce missed or mismatched translations. Your original chat stays visible.

WoW's chat restrictions can temporarily stop addon processing. Chat replacements such as ElvUI still need testing.

Found something broken? Open an issue with what happened, your WoW version, and any Lua error you saw.

## Credits & license

See [third-party notices](THIRD_PARTY_NOTICES.md) for original authors, source attribution and dictionary credits.

The project includes the **GPLv3** license. See [LICENSE](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md) for library licenses, dictionary credits and unresolved inherited licensing details. Bundled components keep their own terms.

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

## Druid animal speech

Entering a druid form keeps your selected language. A second button appears
below the floating language button, offering **Speak: Cat**, **Speak: Bear**,
or the language associated with your form. Click it to use that animal voice;
click again to return to your selected language. Leaving or changing form clears
the temporary choice. Selecting a regular language also returns to normal speech.
The temporary choice is not saved across reloads.

The Speech page option **Offer animal language on the floating button** controls
whether this choice is shown. **Animal language (<None> = form)** lets you
choose the offered language manually. Existing settings no longer cause automatic
animal speech when entering a form.

## IC/OOC and favorite languages

OOC leaves your outgoing text unchanged while incoming translations and language
learning remain available. Your language, dialect, effects and fluency are kept.
Animal speech commands are paused in OOC. The master Enable setting still
controls the entire addon, including receiving. IC/OOC and favorites save per
character; existing characters start in IC when upgrading.

Favorite languages appear first in the quick list and take priority when cycling.
Favoriting is independent of fluency. Removing every favorite restores the previous
30%-fluency cycle. You can still select any language directly.

Optional shortcuts are listed under the game's Key Bindings > AddOns > ManyTongues:
Toggle IC/OOC speech and Next favorite or known language. No keys are assigned
automatically.

## Translation queues and diagnostics

Each outstanding request has its own token, so modern tagged messages can be
answered out of order without replacing another request in the same conversation.
Repeated chat lines use the client's line ID to distinguish separate messages.
The queue expires requests after 20 seconds and is limited to 32 pending requests
per sender and 256 overall. Original chat is always kept visible.

Legacy peers without reply tokens are accepted only when the request can be
unambiguously identified. Overlapping legacy requests are left untranslated rather
than assigned to the wrong line. Matching native speech scrambled by the game
server remains best effort; request tokens cannot recover text absent from the
received message. Neither feature bypasses game communication restrictions.

`/manytongues doctor` reports version, client interface, IC/OOC, chat restrictions
and session counts for requested, received, expired, blocked and ambiguous
translations. It does not print peer names or message contents. A timeout does
not prove a peer has the addon; it may also mean no compatible addon, throttling
or an unavailable communication route.

## Extended automated checks

`python3 tests/check.py` also runs twenty deterministic network scenarios per
client profile. Each scenario loads three isolated addon instances with separate
LibStub, AceComm, ChatThrottleLib, settings and message state. Requests and
complete replies are reordered, multipart replies are reassembled and duplicate
responses must not be displayed twice. WoW's transport fragment order is preserved.
The suite also runs 500 deterministic UI/action transitions per client profile.

Optional local settings migration can be tested without changing the original file:

```sh
python3 tests/check.py --saved-variables "/absolute/path/to/SavedVariables/Tongues.lua"
```

Repeat `--saved-variables` for additional files. Saved settings are evaluated in a
restricted data environment with an instruction limit; they are not copied into
the project, logged, written back or sent to another client. These checks verify
Lua behavior and simulated API interactions, not native UI rendering, server
permissions, real network delivery or compatibility with other running addons.
