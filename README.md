# Keldurn Addons

Addons for the Windows client of **[Keldurn](https://play.keldurn.com/)** (WoW 1.12.1), ready to copy and play.

The Keldurn client is a reimplementation of the 1.12 interface, and some classic addons fail on it because they expect functions or frames from the original client. This repository has three addons written from scratch for Keldurn and two classic addons patched so they run without errors.

## What's included

| Addon | What it does | Origin |
|---|---|---|
| **KeldurnFrames** | Numeric health and mana on the target frame and the party frames, plus buffs/debuffs of each party member. | New |
| **KeldurnTimers** | Timer bars for casts (spells, Hearthstone, etc.), melee swings and ranged/wand shots, in the style of Attack Bar Timer. | New |
| **KeldurnSellPrice** | Vendor sell price in item tooltips (bags, bank, loot, chat links, quest rewards, trade, auction house). Prices are learned when you open a vendor window. | New |
| **Titan** (Titan Panel 2.19.1) | Information bars at the top/bottom of the screen. Enabled by default: Performance (FPS/latency/memory), XP, Coordinates, Clock, Bags, Money, Repair (durability) and ItemBonuses. Also available: Ammo, Loot Type and Regeneration. | Patched |
| **!OmniCC** | Remaining-time numbers on icons that are on cooldown. | Patched |

## Installation

1. Download `Keldurn-Addons-<version>.zip` from the [latest release](../../releases/latest).
2. Open the Keldurn addons folder: press `Win + R`, paste this and press Enter:
   ```
   %LOCALAPPDATA%\Keldurn\settings\AddOns
   ```
3. Extract the zip there: the addon folders (KeldurnFrames, KeldurnTimers, KeldurnSellPrice, Titan, !OmniCC) go directly inside that folder. If you do not want all of them, every addon is also available as its own zip on the same page.
   - If you already had one of these addons installed, **delete its old folder first**. Some Titan versions ship extra subfolders (TitanBG, TitanItemBonuses, TitanHonorPlus…) that are loaded as separate addons and cause errors.
4. Start the game and, on the character selection screen, open **AddOns** and check that they are enabled.

## Commands

**KeldurnFrames** (`/kf`)

| Command | What it does |
|---|---|
| `/kf text` | Toggle health and mana on the target |
| `/kf party` | Toggle health and mana on the party frames |
| `/kf buffs` | Toggle party buffs |
| `/kf debuffs` | Toggle party debuffs |
| `/kf test` | Show your own buffs/debuffs under your frame, to check it works without a party |
| `/kf diag` | Diagnostic information if something does not show |

**KeldurnTimers** (`/kt`)

| Command | What it does |
|---|---|
| `/kt move` | Unlock the bars so you can drag them; repeat it to lock them |
| `/kt test` | Show the bars running, to position them |
| `/kt cast` | Toggle the cast bar |
| `/kt melee` | Toggle the melee bar |
| `/kt ranged` | Toggle the ranged/wand bar |
| `/kt hide` | Hide/show the game's own cast bar |
| `/kt reset` | Return to the default position |

**KeldurnSellPrice** (`/ksp`)

| Command | What it does |
|---|---|
| `/ksp scan` | Read the sell prices of the items in your bags (needs a vendor window open) |
| `/ksp diag` | Diagnostic information if prices do not show up |
| `/ksp reset` | Forget all learned prices |

**Titan Panel**: right-click the bar to add or remove modules.

## What was changed in the classic addons

The changes are compatibility fixes; behavior is the same as the original. If a function fails, the addon reports it **once** in the chat with an orange message (for example `Titan (Keldurn): error in …`) instead of opening the error window over and over.

- **Titan Panel**
  - Protection against Blizzard frames that Keldurn does not have (`TutorialFrameParent` and others) when the interface is repositioned.
  - Menus: the game's own dropdown menu is used (Keldurn only has 2 levels), so the server submenu in *Settings* is disabled.
  - Module texts are created as `FontString`s because Keldurn does not support `<NormalText>`.
  - Modules enabled by default on first load (`TitanKeldurn.lua`).
  - Performance: fixed the `gcThreshold` error (Keldurn returns a single memory value).
  - Regeneration: mana no longer shows 0 all the time (Keldurn uses `UNIT_POWER_UPDATE` instead of `UNIT_MANA`).
  - Repair and ItemBonuses adapted (`TitanKeldurnItemBonuses.lua`, protected popup windows).
- **!OmniCC**: no longer replaces the game's cooldown function, it hooks into it; protected against `SetSequence`, which Keldurn does not have.

The exact changes can be reviewed as a plain diff: the first commit of this repository contains the original, unmodified third-party files, and the second one holds the Keldurn patches.

## Notes

KeldurnTimers reads the English combat log and ItemBonuses reads English item tooltips, so an English game client is assumed.

KeldurnSellPrice ships no price database: it starts empty and learns each item's sell price the first time that item is in your bags while a vendor window is open. Until then an item shows no price. Prices are stored per account in `KeldurnSellPriceDB`.

## Not included

**MetaMap** and **MobInfo2** were tested, but they depend too much on parts of the map and interface that Keldurn implements differently, so they are not included.

## Issues

Open an [issue](../../issues) with a screenshot of the error message (or of the orange chat message) and the list of addons you have enabled.

## Credits

- **KeldurnFrames**, **KeldurnTimers** and **KeldurnSellPrice**: ne0x86.
- **Titan Panel**: TitanMod / Adsertor. TitanRepair: lua@lumpn.de / Adsertor, with improvements by Archarodim. ItemBonuses/BonusScanner and the rest of the modules: their original authors.
- **OmniCC**: Tuller.

The classic addons belong to their authors; they are only distributed here with the compatibility patches for Keldurn. If you are the author of one of them and prefer it not to be here, open an issue and it will be removed.

## License

The original code (KeldurnFrames, KeldurnTimers, KeldurnSellPrice and the compatibility changes) is published under the MIT license: see [LICENSE](LICENSE). Third-party addons keep the terms of their original authors; the origin, version and license status of each one are in [THIRD_PARTY.md](THIRD_PARTY.md).
