# Third-party software and licensing

The [MIT license](LICENSE) in this repository covers only the original work of
ne0x86:

- the **KeldurnFrames**, **KeldurnTimers** and **KeldurnSellPrice** addons, and
- the Keldurn compatibility changes made to third-party addons: the files
  `Titan/TitanKeldurn.lua` and `Titan/TitanKeldurnItemBonuses.lua`, and every
  change marked `[Keldurn fix]` in the code
  (`grep -rn "Keldurn fix" AddOns`).

Everything else in `AddOns/` is the work of its original authors and keeps
whatever terms they published. It is redistributed here only with the
compatibility patches needed to run on the Keldurn client. This repository does
not relicense it.

## Included addons

| Addon | Base used here | Original authors | Reference | Terms found |
|---|---|---|---|---|
| **Titan Panel** and its plugins | 2.19.1 (`2.19.1.111000`) | TitanMod, Adsertor (maintainers over the years also include Dark Imakuni and urnati). TitanRepair: lua@lumpn.de / Adsertor, improvements by Archarodim. ItemBonuses / BonusScanner: their original authors. | Package note (`Titan.txt`): `ui.worldofwar.net/ui.php?id=1442`. Project page: [Titan Panel on WoWInterface](https://wowinterface.com/downloads/info8092-TitanPanel.html) | The base package contains no license text. |
| **!OmniCC** | v5126 (package note `!OmniCC v5126.txt`) | Tuller | Package note: `curse-gaming.com/en/wow/addons-3809-1-omni-cooldown-count.html`. Modern OmniCC: [tullamods/OmniCC](https://github.com/tullamods/OmniCC) (MIT) | The base package contains no license text. The MIT license of the modern project does not automatically cover this much older release. |
| **Atlas** (instance map browser) | 1.13.0 | Dan Gilbert, Daviesh, Thandrenn, Asurn, Loather, Rabidmax, Dazerdude, laytya, Lichery | [laytya/Atlas](https://github.com/laytya/Atlas) (backport for 1.12, a fork of [Lulleh/Atlas](https://github.com/Lulleh/Atlas)) | GNU GPL version 2 or later, as stated in the headers of its source files. The license text is included as `Atlas/COPYING`. |
| **AtlasLoot Enhanced** (boss loot tables) | 4.07.01 | Daviesh, laytya, Lichery | [laytya/Atlas](https://github.com/laytya/Atlas) | Its files carry no license header. It is part of the same project as Atlas and AtlasQuest (GPL), but the package does not state it for AtlasLoot itself; terms not verified. |
| **AtlasQuest** (instance quests) | 4.1.3 | Asurn, Thandrenn | [laytya/Atlas](https://github.com/laytya/Atlas) | GNU GPL version 2 or later, as stated in the headers of its source files. The license text is included as `AtlasQuest/COPYING`. |

"No license text" means that none could be found, not that the author has
granted or refused permission.

The Titan Panel base package also bundled plugins that are **not** included
here: TitanBG, TitanBattleTracker, TitanHonorPlus, TitanRider, TitanStanceSets
and TitanZoneSpeed.

The Atlas package also contains `FuBar_AtlasFu`, which is **not** included: it needs
FuBar, which is not shipped, and targets a newer game interface.

## Changes against the base packages

Measured against the original archives:

- **Titan Panel**: 24 files modified and 2 files added
  (`TitanKeldurn.lua`, `TitanKeldurnItemBonuses.lua`); plugins listed above
  removed.
- **!OmniCC**: `OmniCC.lua` changed (+53 / -10 lines). `OmniCC_Min.lua` and the
  package note were not included.
- **Atlas, AtlasLoot Enhanced and AtlasQuest**: none. They are shipped exactly as
  they come, plus a copy of the GPL text in `Atlas/` and `AtlasQuest/`. The files
  match [laytya/Atlas](https://github.com/laytya/Atlas) except for three Spanish
  translation files (`Atlas-esES.lua`, `localization.es.lua`, `locale.es.lua`)
  that differ in wording.

## Removed addons

**SellValue** (a fork of [anzz1/SellValue](https://github.com/anzz1/SellValue) by [DBFBlackbull](https://github.com/DBFBlackbull/SellValue)) was shipped in earlier versions of this repository. Neither upstream repository declares a license, so it was removed, including from the repository history, and replaced by **KeldurnSellPrice**.

KeldurnSellPrice was written from scratch. It uses the same game mechanism (the tooltip's money event, which is how the 1.12 interface exposes the sell price) but contains no code or data from SellValue; in particular it does not ship its price database.

## Takedown and corrections

If you are the author of any of these addons and want it removed, credited
differently or covered by a specific license, please open an
[issue](../../issues) and it will be handled promptly.
