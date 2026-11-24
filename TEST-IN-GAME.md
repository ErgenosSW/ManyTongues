# Retail and Forever acceptance checks — not yet executed in WoW

Targets: Forever 1.60.1 / build 71037 / Interface 16001 and Retail 12.1.5 / build 70575 / Interface 120105. Run the checklist independently in each client. Record the result of `/dump GetBuildInfo()` when testing on another live build. A manifest version alone does not establish API compatibility.

Enable Lua error reporting with `/console scriptErrors 1`, then `/reload`. Use two characters with ManyTongues for translation checks. Tests should first use the default Blizzard chat and ManyTongues alone, then the normal addon set.

0. **Client selection:** install the same package into `_forever_/Interface/AddOns/Tongues` or `_retail_/Interface/AddOns/Tongues`. Confirm the addon loads without enabling out-of-date addons. `/dump ManyTongues.Version, ManyTongues.TargetInterface` should show `1.2.1` and `16001` in Forever, or `120105` in Retail.
1. **Startup:** log in with no saved ManyTongues settings; no Lua error; native languages initialize; `/manytongues` and Settings → AddOns → ManyTongues both open the window.
2. **Migration:** repeat with a copy of old SavedVariables. Verify language, fluencies, effect, recipients and positions; change values, `/reload`, confirm persistence.
3. **GUI:** click each tab; scroll every long page; search/select languages and dialects; drag both windows; move sliders to 0/100; add/remove translators; hide/show the floating button; close/reopen with Escape; reset positions; repeat at low resolution and different UI scales. Preview must send no message.
4. **Speech:** native language, non-native language, dialect, each effect, frequency 0/100, Roleplay filter, `(OOC)`, item links, Unicode and near-limit text. Verify exactly one normal outgoing message unless extra translation copies were explicitly enabled.
5. **Channels:** say/yell/whisper, party, raid/leader/warning, guild/officer and instance chat. Readable-channel flags must bypass processing. Sharing must respect chosen recipients and not forward private whispers elsewhere.
6. **Receiving:** two modernized clients; zero/partial/full fluency; rapid messages; the same message in two chat windows; messages from someone without ManyTongues. Original chat must never disappear. Check both directions with an unmodified legacy peer.
7. **Learning:** enabled/disabled; bounded increases after communication; no repeated skill-ups from one reply; no updates after timeout.
8. **Druid/pets/mounts:** enter a form and confirm the selected language stays active; use the secondary floating button to opt into animal speech, then click again to return; leave, change or re-enter a form and confirm normal speech; check a configured animal-language override, disabling the offered choice, and `/reload` while opted in; no active pet/mount; modern unknown mount; explicit language overrides; pet/mount translation from a second client.
9. **Restrictions:** enter and leave content where chat lockdown applies. No secret-value errors, taint errors or queued regular chat spam. Default chat still behaves as Blizzard permits; processing resumes after restrictions end.
10. **Other addons:** repeat outgoing/receiving checks with ElvUI or other chat replacements. Verify that their editbox emits the supported pre-send event. A replacement that skips this event needs its own supported integration.

For any failure, save the full Lua error (including stack), the reproduction steps, the client build, UI scale and active chat addons. This development build has passed local simulation checks only; these client checks remain pending.

## 1.2.0 acceptance checks (pending in the actual clients)

11. **IC/OOC:** use the floating control and /manytongues ic, ooc and toggle. In OOC, native/custom language and dialect/effect choices must not change outgoing text or forward readable copies. Continue receiving translations from a second client. Restore IC and confirm preferences are unchanged. Reload and confirm the saved mode.
12. **Favorites:** Shift-left-click or middle-click the floating button; add/remove favorites with +/*, search, select a language and confirm favorites are first. Cycle with left-click and the wheel in both directions, with zero, one and several favorites. Check that dialect/effect selection lists have no favorite controls. Reload and confirm favorites persist.
13. **Bindings:** assign unused keys under Key Bindings > AddOns > ManyTongues. Toggle IC/OOC and cycle favorites, then unassign those keys if only testing.
14. **Translation burst:** with two current clients, send several different tagged-language lines, repeated identical lines, and pet/mount speech; verify each readable translation belongs to its original line and window. Repeat with an old peer; ambiguous tokenless replies may be omitted, but original chat must remain. Native server-scrambled speech still has the documented matching limitation.
15. **Diagnostics:** run /manytongues doctor before/after receiving translations and after a no-peer timeout. Verify local counts and restriction indicators; no message contents or recipient names are included in the report.
16. **Layout:** check IC/OOC and druid controls near screen edges, language-list favorite controls, long localized names and hover states at different UI scales.

## 1.2.1 fixes (pending in the actual clients)

17. **Disabled animal speech:** turn off Enable ManyTongues while in IC, then run /ps and /ms with an active pet/mount. Confirm a local explanation appears and no emote is sent. Enable the addon again and confirm both commands work normally. Repeat in OOC and under chat restrictions.
18. **Learning retry:** with two compatible clients, set fluency below 100 and enable gradual learning. If outgoing addon communication is temporarily blocked, the failed attempt must not consume the 20-second learning-request cooldown. Confirm a new eligible message can request learning once communication is available again. Normal cooldown and one-reply consumption must still apply.
