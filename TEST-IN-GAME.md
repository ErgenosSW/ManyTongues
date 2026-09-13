# Retail acceptance checks — not yet executed in WoW

Target: 12.1.0 / build 69814 reference. Record the result of `/dump GetBuildInfo()` when testing on another live build. A manifest version alone does not establish API compatibility.

Enable Lua error reporting with `/console scriptErrors 1`, then `/reload`. Use two characters with Tongues for translation checks. Tests should first use the default Blizzard chat and Tongues alone, then the normal addon set.

1. **Startup:** log in with no saved Tongues settings; no Lua error; native languages initialize; `/tongues` and Settings → AddOns → Tongues both open the window.
2. **Migration:** repeat with a copy of old SavedVariables. Verify language, fluencies, effect, recipients and positions; change values, `/reload`, confirm persistence.
3. **GUI:** click each tab; scroll every long page; search/select languages and dialects; drag both windows; move sliders to 0/100; add/remove translators; hide/show the floating button; close/reopen with Escape; reset positions; repeat at low resolution and different UI scales. Preview must send no message.
4. **Speech:** native language, non-native language, dialect, each effect, frequency 0/100, Roleplay filter, `(OOC)`, item links, Unicode and near-limit text. Verify exactly one normal outgoing message unless extra translation copies were explicitly enabled.
5. **Channels:** say/yell/whisper, party, raid/leader/warning, guild/officer and instance chat. Readable-channel flags must bypass processing. Sharing must respect chosen recipients and not forward private whispers elsewhere.
6. **Receiving:** two modernized clients; zero/partial/full fluency; rapid messages; the same message in two chat windows; messages from someone without Tongues. Original chat must never disappear. Check both directions with an unmodified legacy peer.
7. **Learning:** enabled/disabled; bounded increases after communication; no repeated skill-ups from one reply; no updates after timeout.
8. **Druid/pets/mounts:** each available druid form; humanoid form with an override configured; no active pet/mount; modern unknown mount; explicit language overrides; pet/mount translation from a second client.
9. **Restrictions:** enter and leave content where chat lockdown applies. No secret-value errors, taint errors or queued regular chat spam. Default chat still behaves as Blizzard permits; processing resumes after restrictions end.
10. **Other addons:** repeat outgoing/receiving checks with ElvUI or other chat replacements. Verify that their editbox emits the supported pre-send event. A replacement that skips this event needs its own supported integration.

For any failure, save the full Lua error (including stack), the reproduction steps, the client build, UI scale and active chat addons. This development build has passed local simulation checks only; these client checks remain pending.
