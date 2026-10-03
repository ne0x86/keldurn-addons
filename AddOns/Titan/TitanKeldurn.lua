-- ============================================================================
-- TitanKeldurn.lua  -  Titan Panel 2.18/2.19 compatibility with Keldurn
--
-- The Keldurn client reimplements the 1.12 interface but is not identical to
-- Blizzard's original: some frames and constants are missing. This file:
--   1. Defines default values for constants that some plugins expect.
--   2. Provides TitanKeldurn_Protect(): wraps a plugin's functions so that,
--      if something fails, it is reported ONCE in chat instead of showing the
--      error window over and over.
--   3. Enables the basic plugins once on the bottom bar.
-- ============================================================================

-- 1) Constants that the original client gets from FrameXML
if (not PERFORMANCEBAR_LOW_LATENCY) then PERFORMANCEBAR_LOW_LATENCY = 300; end
if (not PERFORMANCEBAR_MEDIUM_LATENCY) then PERFORMANCEBAR_MEDIUM_LATENCY = 600; end

-- 2) Plugin function protection
TitanKeldurn_Reported = {};

function TitanKeldurn_Report(name, err)
	if (TitanKeldurn_Reported[name]) then
		return;
	end
	TitanKeldurn_Reported[name] = 1;
	if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff9900Titan (Keldurn):|r error in " .. tostring(name) .. ": " .. tostring(err));
	end
end

local function TitanKeldurn_Wrap(name, func)
	return function(a1, a2, a3, a4, a5, a6, a7, a8)
		local ok, r1, r2, r3, r4, r5, r6, r7, r8 = pcall(func, a1, a2, a3, a4, a5, a6, a7, a8);
		if (ok) then
			return r1, r2, r3, r4, r5, r6, r7, r8;
		end
		TitanKeldurn_Report(name, r1);
	end
end

function TitanKeldurn_Protect(names)
	if (not names) then
		return;
	end
	local env = getfenv(0);
	for i = 1, table.getn(names) do
		local name = names[i];
		local func = env[name];
		if (type(func) == "function") then
			env[name] = TitanKeldurn_Wrap(name, func);
		end
	end
end

-- 3) Plugins shown automatically (once each) on the bottom bar.
--    If you later remove them from the menu, they do not come back.
TITAN_KELDURN_DEFAULT_PLUGINS = { "Performance", "XP", "Coords", "Clock", "Bag", "Money", "Repair", "ItemBonuses" };
local TITAN_KELDURN_FIRST_BATCH = { "Performance", "XP", "Coords", "Clock", "Bag", "Money" };

local function TitanKeldurn_Copy(t)
	local copy = {};
	if (t) then
		for k, v in pairs(t) do
			copy[k] = v;
		end
	end
	return copy;
end

function TitanKeldurn_AddDefaultPlugins()
	if (not TitanPlayerSettings or not TitanPanelSettings) then
		return;
	end

	if (not TitanPlayerSettings.KeldurnAdded) then
		TitanPlayerSettings.KeldurnAdded = {};
		-- The first version only stored a single flag for the first batch
		if (TitanPlayerSettings.KeldurnPluginsAdded) then
			for i = 1, table.getn(TITAN_KELDURN_FIRST_BATCH) do
				TitanPlayerSettings.KeldurnAdded[TITAN_KELDURN_FIRST_BATCH[i]] = 1;
			end
		end
	end
	local done = TitanPlayerSettings.KeldurnAdded;

	-- Do not modify Titan's shared default tables
	TitanPanelSettings.Buttons = TitanKeldurn_Copy(TitanPanelSettings.Buttons);
	TitanPanelSettings.Location = TitanKeldurn_Copy(TitanPanelSettings.Location);

	for i = 1, table.getn(TITAN_KELDURN_DEFAULT_PLUGINS) do
		local id = TITAN_KELDURN_DEFAULT_PLUGINS[i];
		if (not done[id] and TitanUtils_IsPluginRegistered(id)) then
			if (not TitanUtils_TableContainsValue(TitanPanelSettings.Buttons, id)) then
				table.insert(TitanPanelSettings.Buttons, id);
				TitanPanelSettings.Location[table.getn(TitanPanelSettings.Buttons)] = "AuxBar";
			end
			done[id] = 1;
		end
	end

	TitanPlayerSettings.KeldurnPluginsAdded = 1;
end
