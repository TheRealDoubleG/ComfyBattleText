# ComfyBattleText

**Version 0.6 – Beta**  
**Target: World of Warcraft: Forever 1.60.1 / Interface 16001**

Customizable scrolling combat text for damage, healing, combat events and notifications on WoW Forever.

ComfyBattleText is developed specifically for **WoW: Forever**. Retail/Modern WoW, Midnight and WoW Classic are not compatibility targets.

## 0.6 Beta

- Separate **Incoming**, **Outgoing** and **Notifications** scroll areas.
- Incoming damage, healing and misses/avoidance.
- Outgoing player and optional pet damage, healing and misses.
- Critical-hit scaling.
- Optional spell names and spell icons.
- Optional spell-school colors for outgoing damage.
- Compact number formatting.
- Successful interrupt and dispel/spell-steal notifications.
- Optional combat text attached to Blizzard nameplates.
- Unlockable and draggable scroll-area anchors.
- Configurable font size, direction, lifetime, speed and message limits.
- Quick presets: **Minimal**, **Standard**, **PvP** and **Everything**.
- Spam filters with separate minimum values for incoming/outgoing damage and healing.
- Per-spell ignore list accepting spell names or spell IDs.
- Configurable rapid-hit merge window to reduce burst/DoT text spam.
- Custom font path and RGB hex colors for incoming damage, healing, outgoing damage, misses, interrupts and dispels.
- Searchable settings categories.
- Scroll areas register with ComfyHub's shared Suite edit mode when ComfyHub is available; standalone anchor controls still work without it.
- Optional suppression of periodic damage and periodic healing text.
- Built-in test mode and copyable WoW Forever combat-log debug report.
- Character/account/custom profile support through the shared Comfy Suite UI.
- Native Blizzard AddOns settings entry.

## Commands

- `/comfybattletext`
- `/cbt`
- `/cbt test`
- `/cbt anchors`
- `/cbt reset`

## Forever notes

The beta deliberately filters combat-log output to events involving the player or the player's current pet. Combat-log payload positions are guarded, but the exact Forever runtime behavior still needs in-game testing.

The public feature sets of established scrolling combat text addons were useful as architecture references. ComfyBattleText uses original Comfy Suite code and Blizzard UI assets.
