# Licensing and third-party notices

Inventory checked on 2026-09-13. Original headers and credits remain in place.
The top-level GPL text is not a blanket relicensing of bundled components.

## Tongues and this modernization

Original authors: Skrull Adams and Aurorablade/Fethas, with contributors credited
in the source and historical ReadMe.txt. Based on Aurorablade/Tongues commit
649fc6c3c52aafec38d5ceb265891a2b1c782e80; its Git history is retained.

The [original CurseForge project](https://www.curseforge.com/wow/addons/tongues)
declares GNU GPL version 3. The imported repository had no top-level license file.
[LICENSE](LICENSE) supplies the full GPLv3 text on the basis of that declaration.
The new modernization code and documentation are provided under GPL-3.0-only;
this does not change third-party rights or resolve the historical issues below.
The dated modernization changes are recorded in CHANGELOG.md and Git history.

## Component inventory

| Paths / component | Authors or credits | License evidence and supplied text |
| --- | --- | --- |
| `libs/AceComm-3.0/AceComm-3.0.lua`, `libs/AceSerializer-3.0/` | Ace3 Development Team | [Ace3 custom BSD-style license](LICENSES/Ace3.txt), including the standalone redistribution restriction; **not standard BSD-3-Clause**. [Upstream text](https://github.com/WoWUIDev/Ace3/blob/master/LICENSE.txt). |
| `Core/CallbackHandler-1.0/`, `libs/CallbackHandler-1.0/` | Ace3 contributors | CallbackHandler is an Ace3 component; see the Ace3 text above. Original copies retained. |
| `libs/AceComm-3.0/ChatThrottleLib.lua` | Mikk and contributors credited in header | Public domain, explicitly declared in the file. |
| All `LibStub` directories, including nested library copies and tests | Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke and header credits | Public-domain declaration retained in each LibStub.lua. |
| `libs/LibBabble-*/LibBabble-3.0.lua` | LibBabble contributors | Explicit public-domain declaration in each file. |
| `libs/LibBabble-Race-3.0/`, `libs/LibBabble-Faction-3.0/`, `libs/LibBabble-CreatureType-3.0/` data modules | ckknight, nevcairiel, Ackis and localization contributors listed in source | MIT in module headers and manifests; [MIT terms](LICENSES/MIT.txt). The separate LibBabble core and LibStub retain their public-domain declarations. |
| `Core/LibDataBroker-1.1.lua` | tekkub and contributors | No license header in bundled file. [Project metadata](https://www.curseforge.com/wow/addons/libdatabroker-1-1) says All Rights Reserved; its description explicitly instructs addon authors to embed it. Retained as that embedded library, with no invented MIT/public-domain grant. |
| `libs/Poncho-2.0/` | Copyright 2011–2023 João Cardoso | Header permits GPL version 3 or later; full GPL text in LICENSE. Header also mentions Lesser GPL without identifying a version; this inventory relies on the explicit GPL option. Unloaded legacy library. |
| `libs/Sushi-3.1/` | Copyright 2008–2023 João Cardoso | Same explicit GPL version 3 or later grant as Poncho; full text in LICENSE. Unloaded legacy library. |
| `libs/ElioteDropDownMenu-1.0/` | Eliote | [Project declares MIT](https://www.curseforge.com/wow/addons/eliotedropdownmenu); [MIT terms](LICENSES/MIT.txt). No standalone copyright year was supplied in the imported module. Unloaded legacy library. |
| `libs/DropDownMenu/` | Blizzard UI source, adapted by upstream library authors | Bundled readme identifies renamed Blizzard UI code; no explicit license grant found in the bundled files. Do not assume GPL or MIT. Unloaded legacy library. |
| `Core/dialects.lua` | I. Marc Carlson; David Crowhurst; other original authors | [Exact inherited notices](LICENSES/Dialect-notices.txt), also preserved in the source. These are custom restrictions, not MIT/GPL declarations. |
| Remaining addon files, `Custom/`, `Tools/`, historical documentation | Original Tongues contributors and modernization contributors | Project-level declaration above, subject to any embedded notices; no additional separate grant identified in these files. |

## Historical issues that remain unresolved

The inherited dialect notice requires attribution and unaltered text and mentions
commercial proceeds. Another notice reserves rights for other authors. The exact
mapping from these notices to individual dictionary entries is not documented.
Keeping these notices does not establish GPL compatibility or clear all rights.
The legacy Blizzard-derived dropdown has no bundled license, and LibDataBroker's
embedding guidance is not a general open-source license. Ace3's standalone clause
is an additional restriction. These issues need clarification with the relevant
rights holders or replacement of the affected components before claiming the
entire distribution is uniformly GPL-compatible. This inventory documents the
actual evidence instead of supplying missing permissions on their behalf.

No Tongues Reforged source code is included in this modernization.
World of Warcraft is a Blizzard Entertainment trademark; this project is an
independent community addon and is not endorsed by Blizzard.
