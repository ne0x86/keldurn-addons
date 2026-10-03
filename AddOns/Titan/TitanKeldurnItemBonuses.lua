-- ============================================================================
-- TitanKeldurnItemBonuses.lua
-- Texts and patterns needed by ItemBonuses (standalone version with BonusScanner
-- built in). The original package shipped them in its own Localization.lua, which
-- got lost when it was merged with Titan's. The patterns read the item text in
-- English (the language of the Keldurn client), and the displayed names are in
-- English too.
-- ============================================================================

-- Displayed names (display labels only)
TITAN_ITEMBONUSES_DISPLAY_NONE = "Display none";
TITAN_ITEMBONUSES_SHORTDISPLAY = "Brief label text";

TITAN_ITEMBONUSES_CAT_ATT   = "Attributes";
TITAN_ITEMBONUSES_CAT_RES   = "Resistance";
TITAN_ITEMBONUSES_CAT_SKILL = "Skills";
TITAN_ITEMBONUSES_CAT_BON   = "Melee and ranged combat";
TITAN_ITEMBONUSES_CAT_SBON  = "Spells";
TITAN_ITEMBONUSES_CAT_OBON  = "Life and mana";

TITAN_ITEMBONUSES_STR   = "Strength";
TITAN_ITEMBONUSES_AGI   = "Agility";
TITAN_ITEMBONUSES_STA   = "Stamina";
TITAN_ITEMBONUSES_INT   = "Intellect";
TITAN_ITEMBONUSES_SPI   = "Spirit";
TITAN_ITEMBONUSES_ARMOR = "Armor";

TITAN_ITEMBONUSES_ARCANERES = "Arcane Resist";
TITAN_ITEMBONUSES_FIRERES   = "Fire Resist";
TITAN_ITEMBONUSES_NATURERES = "Nature Resist";
TITAN_ITEMBONUSES_FROSTRES  = "Frost Resist";
TITAN_ITEMBONUSES_SHADOWRES = "Shadow Resist";

TITAN_ITEMBONUSES_DEFENSE   = "Defense";
TITAN_ITEMBONUSES_MINING    = "Mining";
TITAN_ITEMBONUSES_HERBALISM = "Herbalism";
TITAN_ITEMBONUSES_SKINNING  = "Skinning";
TITAN_ITEMBONUSES_FISHING   = "Fishing";

TITAN_ITEMBONUSES_ATTACKPOWER       = "Attack Power";
TITAN_ITEMBONUSES_CRIT              = "Crit";
TITAN_ITEMBONUSES_BLOCK             = "Block";
TITAN_ITEMBONUSES_DODGE             = "Dodge";
TITAN_ITEMBONUSES_PARRY             = "Parry";
TITAN_ITEMBONUSES_TOHIT             = "To Hit";
TITAN_ITEMBONUSES_RANGEDATTACKPOWER = "Ranged Attack Power";
TITAN_ITEMBONUSES_RANGEDCRIT        = "Ranged Crit";

TITAN_ITEMBONUSES_DMG        = "Spell Damage";
TITAN_ITEMBONUSES_HEAL       = "Healing";
TITAN_ITEMBONUSES_HOLYCRIT   = "Holy Crit";
TITAN_ITEMBONUSES_SPELLCRIT  = "Spell Crit";
TITAN_ITEMBONUSES_SPELLTOHIT = "Spell Hit";
TITAN_ITEMBONUSES_ARCANEDMG  = "Arcane Damage";
TITAN_ITEMBONUSES_FIREDMG    = "Fire Damage";
TITAN_ITEMBONUSES_FROSTDMG   = "Frost Damage";
TITAN_ITEMBONUSES_HOLYDMG    = "Holy Damage";
TITAN_ITEMBONUSES_NATUREDMG  = "Nature Damage";
TITAN_ITEMBONUSES_SHADOWDMG  = "Shadow Damage";

TITAN_ITEMBONUSES_HEALTH    = "Health";
TITAN_ITEMBONUSES_HEALTHREG = "Health Regen";
TITAN_ITEMBONUSES_MANA      = "Mana";
TITAN_ITEMBONUSES_MANAREG   = "Mana Regen";

-- Patterns to read the (English) item text
TITAN_ITEMBONUSES_EQUIP_PREFIX = "Equip: ";
TITAN_ITEMBONUSES_SET_PREFIX   = "Set: ";

-- Lines like "+10 Stamina" or "Fire Resistance +5": name -> effect
TITAN_ITEMBONUSES_TOKEN_EFFECT = {
	["Strength"]                  = "STR",
	["Agility"]                   = "AGI",
	["Stamina"]                   = "STA",
	["Intellect"]                 = "INT",
	["Spirit"]                    = "SPI",
	["All Stats"]                 = { "STR", "AGI", "STA", "INT", "SPI" },
	["Armor"]                     = "ARMOR",
	["Reinforced Armor"]          = "ARMOR",

	["All Resistances"]           = { "ARCANERES", "FIRERES", "FROSTRES", "NATURERES", "SHADOWRES" },

	["Defense"]                   = "DEFENSE",
	["Increased Defense"]         = "DEFENSE",
	["Mining"]                    = "MINING",
	["Herbalism"]                 = "HERBALISM",
	["Skinning"]                  = "SKINNING",
	["Fishing"]                   = "FISHING",

	["Attack Power"]              = "ATTACKPOWER",
	["Ranged Attack Power"]       = "RANGEDATTACKPOWER",
	["ranged Attack Power"]       = "RANGEDATTACKPOWER",
	["Dodge"]                     = "DODGE",
	["Block"]                     = "BLOCK",
	["Hit"]                       = "TOHIT",

	["Healing"]                   = "HEAL",
	["Healing Spells"]            = "HEAL",
	["Spell Damage"]              = "DMG",
	["Spell Damage and Healing"]  = { "DMG", "HEAL" },
	["Healing and Spell Damage"]  = { "DMG", "HEAL" },
	["Damage and Healing Spells"] = { "DMG", "HEAL" },

	["Health"]                    = "HEALTH",
	["HP"]                        = "HEALTH",
	["Mana"]                      = "MANA",
};

-- School + type combinations ("Fire Resistance" -> FIRE..RES, "Shadow Spell Damage" -> SHADOW..DMG)
TITAN_ITEMBONUSES_S1 = {
	{ pattern = "Arcane", effect = "ARCANE" },
	{ pattern = "Fire",   effect = "FIRE" },
	{ pattern = "Frost",  effect = "FROST" },
	{ pattern = "Holy",   effect = "HOLY" },
	{ pattern = "Nature", effect = "NATURE" },
	{ pattern = "Shadow", effect = "SHADOW" },
};
TITAN_ITEMBONUSES_S2 = {
	{ pattern = "Resist", effect = "RES" },
	{ pattern = "Spell Damage", effect = "DMG" },
};

-- "Equip: ..." and "Set: ..." lines
TITAN_ITEMBONUSES_EQUIP_PATTERNS = {
	{ pattern = "Increases damage and healing done by magical spells and effects by up to (%d+)", effect = { "DMG", "HEAL" } },
	{ pattern = "Increases healing done by spells and effects by up to (%d+)", effect = "HEAL" },
	{ pattern = "Increases damage done by Arcane spells and effects by up to (%d+)", effect = "ARCANEDMG" },
	{ pattern = "Increases damage done by Fire spells and effects by up to (%d+)", effect = "FIREDMG" },
	{ pattern = "Increases damage done by Frost spells and effects by up to (%d+)", effect = "FROSTDMG" },
	{ pattern = "Increases damage done by Holy spells and effects by up to (%d+)", effect = "HOLYDMG" },
	{ pattern = "Increases damage done by Nature spells and effects by up to (%d+)", effect = "NATUREDMG" },
	{ pattern = "Increases damage done by Shadow spells and effects by up to (%d+)", effect = "SHADOWDMG" },
	{ pattern = "Improves your chance to get a critical strike with spells by (%d+)%%", effect = "SPELLCRIT" },
	{ pattern = "Increases the critical effect chance of your Holy spells by (%d+)%%", effect = "HOLYCRIT" },
	{ pattern = "Improves your chance to get a critical strike with missile weapons by (%d+)%%", effect = "RANGEDCRIT" },
	{ pattern = "Improves your chance to get a critical strike by (%d+)%%", effect = "CRIT" },
	{ pattern = "Improves your chance to hit with spells by (%d+)%%", effect = "SPELLTOHIT" },
	{ pattern = "Improves your chance to hit by (%d+)%%", effect = "TOHIT" },
	{ pattern = "Increases your chance to dodge an attack by (%d+)%%", effect = "DODGE" },
	{ pattern = "Increases your chance to parry an attack by (%d+)%%", effect = "PARRY" },
	{ pattern = "Increases your chance to block attacks with a shield by (%d+)%%", effect = "BLOCK" },
	{ pattern = "Increased Defense %+(%d+)", effect = "DEFENSE" },
	{ pattern = "%+(%d+) Attack Power%.?$", effect = "ATTACKPOWER" },
	{ pattern = "%+(%d+) ranged Attack Power%.?$", effect = "RANGEDATTACKPOWER" },
	{ pattern = "Restores (%d+) mana per 5 sec", effect = "MANAREG" },
	{ pattern = "Restores (%d+) health per 5 sec", effect = "HEALTHREG" },
	{ pattern = "Increased Fishing %+(%d+)", effect = "FISHING" },
	{ pattern = "Increased Mining %+(%d+)", effect = "MINING" },
	{ pattern = "Increased Herbalism %+(%d+)", effect = "HERBALISM" },
	{ pattern = "Increased Skinning %+(%d+)", effect = "SKINNING" },
};

-- Other lines (enchantments, base armor...)
TITAN_ITEMBONUSES_OTHER_PATTERNS = {
	{ pattern = "Mana Regen (%d+) per 5 sec", effect = "MANAREG" },
	{ pattern = "Health Regen (%d+) per 5 sec", effect = "HEALTHREG" },
	{ pattern = "(%d+) mana every 5 sec", effect = "MANAREG" },
	{ pattern = "(%d+) health every 5 sec", effect = "HEALTHREG" },
	{ pattern = "(%d+) Armor$", effect = "ARMOR" },
};
