-- ============================================================================
-- Keldurn Timers
--   Timer bars for:
--     * Spell casts and channels (spells, Hearthstone, mounts, eating...)
--     * Melee swings (time until the next swing)
--     * Ranged / wand shots (Shoot, Auto Shot, Throw)
--
-- Written for the Keldurn client: it replaces nothing in the game, it only
-- creates its own bars.
--
-- Commands:  /kt (help)  /kt move  /kt test  /kt cast  /kt melee
--            /kt ranged  /kt hide  /kt reset
-- ============================================================================

local KT_FONT = "Fonts\\FRIZQT__.TTF";
local KT_BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar";
local KT_SOLID = "Interface\\Buttons\\WHITE8X8";

local KT_WIDTH = 220;
local KT_HEIGHT = 14;
local KT_GAP = 4;

local KT_DEFAULTS = { cast = true, melee = true, ranged = true, hideDefault = false };

local KT_COLORS = {
	cast     = { 1.00, 0.70, 0.00 },
	channel  = { 0.30, 0.80, 0.30 },
	success  = { 0.00, 1.00, 0.00 },
	failed   = { 1.00, 0.10, 0.10 },
	melee    = { 0.85, 0.85, 0.85 },
	ranged   = { 0.40, 0.60, 1.00 },
};

-- "On next swing" attacks: they restart the melee timer
local KT_NEXT_SWING = { ["Heroic Strike"] = 1, ["Cleave"] = 1, ["Raptor Strike"] = 1, ["Maul"] = 1 };
-- Automatic ranged attacks
local KT_RANGED = { ["Shoot"] = 1, ["Auto Shot"] = 1, ["Throw"] = 1 };

local KT_Bars = {};
local KT_Unlocked = false;
local KT_Testing = false;
local KT_Reported = {};
local KT_Anchor;

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------
local function KT_Print(msg)
	if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage) then
		DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffKeldurn Timers:|r " .. msg);
	end
end

local function KT_Safe(name, func, a1, a2, a3)
	local ok, err = pcall(func, a1, a2, a3);
	if (not ok and not KT_Reported[name]) then
		KT_Reported[name] = 1;
		KT_Print("error in " .. name .. ": " .. tostring(err));
	end
end

local function KT_Opt(key)
	if (KeldurnTimersDB and KeldurnTimersDB[key] ~= nil) then
		return KeldurnTimersDB[key];
	end
	return KT_DEFAULTS[key];
end

local function KT_OnOff(value)
	if (value) then return "|cff00ff00enabled|r"; end
	return "|cffff4040disabled|r";
end

local function KT_Speed(which)
	if (which == "ranged") then
		local speed = UnitRangedDamage and UnitRangedDamage("player");
		if (type(speed) == "number" and speed > 0) then return speed; end
		return 2.0;
	end
	local main, off = 2.0, nil;
	if (UnitAttackSpeed) then
		main, off = UnitAttackSpeed("player");
	end
	if (type(main) ~= "number" or main <= 0) then main = 2.0; end
	return main, off;
end

-- ---------------------------------------------------------------------------
-- Bars
-- ---------------------------------------------------------------------------
local function KT_MakeBar(key, index)
	local bar = CreateFrame("Frame", "KeldurnTimersBar_" .. key, KT_Anchor);
	bar:SetWidth(KT_WIDTH);
	bar:SetHeight(KT_HEIGHT);
	bar:SetPoint("TOP", KT_Anchor, "TOP", 0, -(index - 1) * (KT_HEIGHT + KT_GAP));

	local border = bar:CreateTexture(nil, "BACKGROUND");
	border:SetTexture(KT_SOLID);
	border:SetVertexColor(0, 0, 0, 0.8);
	border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1);
	border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1);

	local bg = bar:CreateTexture(nil, "BORDER");
	bg:SetTexture(KT_BAR_TEXTURE);
	bg:SetVertexColor(0.15, 0.15, 0.15, 0.8);
	bg:SetAllPoints(bar);

	local fill = bar:CreateTexture(nil, "ARTWORK");
	fill:SetTexture(KT_BAR_TEXTURE);
	fill:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0);
	fill:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0);
	fill:SetWidth(1);
	bar.fill = fill;

	local label = bar:CreateFontString(nil, "OVERLAY");
	label:SetFont(KT_FONT, 10, "OUTLINE");
	label:SetPoint("LEFT", bar, "LEFT", 4, 0);
	label:SetJustifyH("LEFT");
	bar.label = label;

	local timer = bar:CreateFontString(nil, "OVERLAY");
	timer:SetFont(KT_FONT, 10, "OUTLINE");
	timer:SetPoint("RIGHT", bar, "RIGHT", -4, 0);
	timer:SetJustifyH("RIGHT");
	bar.timer = timer;

	bar.key = key;
	bar.active = false;
	bar:Hide();
	KT_Bars[key] = bar;
	return bar;
end

local function KT_SetFill(bar, fraction)
	if (fraction < 0) then fraction = 0; end
	if (fraction > 1) then fraction = 1; end
	local width = KT_WIDTH * fraction;
	if (width < 1) then width = 1; end
	bar.fill:SetWidth(width);
end

local function KT_SetColor(bar, color)
	bar.fill:SetVertexColor(color[1], color[2], color[3]);
end

-- Starts a bar: duration in seconds. drain = the bar empties (channel)
local function KT_Start(key, label, duration, color, drain)
	local bar = KT_Bars[key];
	if (not bar or not duration or duration <= 0) then
		return;
	end
	bar.startTime = GetTime();
	bar.endTime = bar.startTime + duration;
	bar.duration = duration;
	bar.drain = drain;
	bar.delay = 0;
	bar.active = true;
	bar.fadeUntil = nil;
	bar.label:SetText(label or "");
	KT_SetColor(bar, color);
	bar:SetAlpha(1);
	bar:Show();
end

-- Ends a bar showing a state (success or failure) for a moment
local function KT_Finish(key, color, text)
	local bar = KT_Bars[key];
	if (not bar or not bar.active) then
		return;
	end
	bar.active = false;
	KT_SetColor(bar, color);
	if (text) then
		bar.label:SetText(text);
		KT_SetFill(bar, 1);
	elseif (not bar.drain) then
		KT_SetFill(bar, 1);
	end
	bar.timer:SetText("");
	bar.fadeUntil = GetTime() + 0.5;
end

local function KT_UpdateBar(bar, now)
	if (bar.active) then
		local remaining = bar.endTime - now;
		if (remaining <= 0) then
			if (bar.key == "cast") then
				-- The server should report the end; if it does not arrive, close anyway
				KT_Finish("cast", KT_COLORS.success);
			else
				bar.active = false;
				bar:Hide();
			end
			return;
		end
		local elapsed = now - bar.startTime;
		local total = bar.endTime - bar.startTime;
		if (bar.drain) then
			KT_SetFill(bar, remaining / total);
		else
			KT_SetFill(bar, elapsed / total);
		end
		local text = string.format("%.1f", remaining);
		if (bar.key == "cast") then
			text = string.format("%.1f / %.1f", remaining, bar.duration);
			if (bar.delay and bar.delay > 0) then
				text = "|cffff4040+" .. string.format("%.1f", bar.delay) .. "|r  " .. text;
			end
		end
		bar.timer:SetText(text);
	elseif (bar.fadeUntil) then
		local left = bar.fadeUntil - now;
		if (left <= 0) then
			bar.fadeUntil = nil;
			bar:Hide();
		else
			bar:SetAlpha(left / 0.5);
		end
	elseif (not KT_Unlocked) then
		bar:Hide();
	end
end

-- ---------------------------------------------------------------------------
-- Casts
-- ---------------------------------------------------------------------------
local function KT_CastEvent(event, a1, a2)
	if (not KT_Opt("cast")) then
		return;
	end
	local bar = KT_Bars.cast;
	if (event == "SPELLCAST_START") then
		local ms = tonumber(a2);
		if (ms and ms > 0) then
			bar.mode = "cast";
			KT_Start("cast", a1, ms / 1000, KT_COLORS.cast, false);
		end
	elseif (event == "SPELLCAST_DELAYED") then
		local ms = tonumber(a1);
		if (bar.active and bar.mode == "cast" and ms) then
			bar.endTime = bar.endTime + ms / 1000;
			bar.delay = (bar.delay or 0) + ms / 1000;
		end
	elseif (event == "SPELLCAST_STOP") then
		if (bar.active and bar.mode == "cast") then
			KT_Finish("cast", KT_COLORS.success);
		end
	elseif (event == "SPELLCAST_FAILED") then
		if (bar.active and bar.mode == "cast") then
			KT_Finish("cast", KT_COLORS.failed, "Failed");
		end
	elseif (event == "SPELLCAST_INTERRUPTED") then
		if (bar.active) then
			KT_Finish("cast", KT_COLORS.failed, "Interrupted");
		end
	elseif (event == "SPELLCAST_CHANNEL_START") then
		local ms = tonumber(a1);
		if (ms and ms > 0) then
			bar.mode = "channel";
			KT_Start("cast", a2, ms / 1000, KT_COLORS.channel, true);
		end
	elseif (event == "SPELLCAST_CHANNEL_UPDATE") then
		local ms = tonumber(a1);
		if (bar.active and bar.mode == "channel" and ms) then
			if (ms <= 0) then
				KT_Finish("cast", KT_COLORS.channel);
			else
				bar.endTime = GetTime() + ms / 1000;
			end
		end
	elseif (event == "SPELLCAST_CHANNEL_STOP") then
		if (bar.active and bar.mode == "channel") then
			KT_Finish("cast", KT_COLORS.channel);
		end
	end
end

-- ---------------------------------------------------------------------------
-- Melee and ranged hits (read from the combat log)
-- ---------------------------------------------------------------------------
local function KT_StartMelee()
	if (not KT_Opt("melee")) then
		return;
	end
	local main, off = KT_Speed("melee");
	local bar = KT_Bars.melee;
	-- With two weapons, a hit that arrives while the bar is still far from done
	-- is usually from the off hand: do not restart the main hand bar.
	if (off and bar.active and (bar.endTime - GetTime()) > 0.3) then
		return;
	end
	KT_Start("melee", "Melee", main, KT_COLORS.melee, false);
end

local function KT_StartRanged(name)
	if (not KT_Opt("ranged")) then
		return;
	end
	local label = "Ranged";
	if (name == "Shoot") then label = "Wand"; elseif (name == "Auto Shot") then label = "Auto Shot"; elseif (name == "Throw") then label = "Throw"; end
	KT_Start("ranged", label, KT_Speed("ranged"), KT_COLORS.ranged, false);
end

local function KT_SpellSelf(msg)
	if (type(msg) ~= "string") then
		return;
	end
	local _, _, spell = string.find(msg, "^Your (.-) [hcmwfi][a-z]+");
	if (not spell) then
		return;
	end
	if (KT_RANGED[spell]) then
		KT_StartRanged(spell);
	elseif (KT_NEXT_SWING[spell]) then
		KT_StartMelee();
	end
end

local function KT_CombatSelf(msg)
	if (type(msg) ~= "string") then
		return;
	end
	if (string.find(msg, "^Your ")) then
		-- Some clients log the auto shot here ("Your Auto Shot hits...")
		KT_SpellSelf(msg);
		return;
	end
	if (string.find(msg, "^You hit ") or string.find(msg, "^You crit ")
			or string.find(msg, "^You miss ") or string.find(msg, "^You attack")) then
		KT_StartMelee();
	end
end

-- ---------------------------------------------------------------------------
-- Default cast bar (optional: hide it)
-- ---------------------------------------------------------------------------
local KT_ForcedHidden = false;

local function KT_ApplyDefaultCastBar()
	if (not CastingBarFrame or not CastingBarFrame.SetAlpha) then
		return;
	end
	if (KT_Opt("hideDefault")) then
		if (CastingBarFrame:GetAlpha() > 0) then
			CastingBarFrame:SetAlpha(0);
		end
	elseif (KT_ForcedHidden) then
		CastingBarFrame:SetAlpha(1);
	end
	KT_ForcedHidden = KT_Opt("hideDefault");
end

-- ---------------------------------------------------------------------------
-- Position and move mode
-- ---------------------------------------------------------------------------
local function KT_ApplyPosition()
	KT_Anchor:ClearAllPoints();
	local pos = KeldurnTimersDB and KeldurnTimersDB.pos;
	if (pos and pos.x and pos.y) then
		KT_Anchor:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y);
	else
		KT_Anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200);
	end
end

local function KT_SavePosition()
	local x, y = KT_Anchor:GetCenter();
	if (x and y) then
		if (type(KeldurnTimersDB) ~= "table") then KeldurnTimersDB = {}; end
		KeldurnTimersDB.pos = { x = x, y = y };
	end
end

local function KT_SetUnlocked(unlocked)
	KT_Unlocked = unlocked;
	KT_Anchor:EnableMouse(unlocked);
	for _, key in ipairs({ "cast", "melee", "ranged" }) do
		local bar = KT_Bars[key];
		if (unlocked) then
			bar.active = false;
			bar.fadeUntil = nil;
			bar:SetAlpha(1);
			KT_SetFill(bar, 0.6);
			KT_SetColor(bar, KT_COLORS[key == "cast" and "cast" or key]);
			bar.label:SetText("Drag to move");
			bar.timer:SetText(key);
			bar:Show();
		else
			bar:Hide();
		end
	end
	if (KT_Anchor.handle) then
		if (unlocked) then KT_Anchor.handle:Show(); else KT_Anchor.handle:Hide(); end
	end
end

-- ---------------------------------------------------------------------------
-- Creation
-- ---------------------------------------------------------------------------
KT_Anchor = CreateFrame("Frame", "KeldurnTimersAnchor", UIParent);
KT_Anchor:SetWidth(KT_WIDTH);
KT_Anchor:SetHeight(3 * KT_HEIGHT + 2 * KT_GAP);
KT_Anchor:SetMovable(true);
KT_Anchor:SetClampedToScreen(true);
KT_Anchor:EnableMouse(false);
KT_Anchor:SetScript("OnMouseDown", function() if (KT_Unlocked) then KT_Anchor:StartMoving(); end end);
KT_Anchor:SetScript("OnMouseUp", function() KT_Anchor:StopMovingOrSizing(); if (KT_Unlocked) then KT_SavePosition(); end end);

local handle = KT_Anchor:CreateTexture(nil, "BACKGROUND");
handle:SetTexture(KT_SOLID);
handle:SetVertexColor(0.2, 0.6, 1.0, 0.25);
handle:SetPoint("TOPLEFT", KT_Anchor, "TOPLEFT", -4, 4);
handle:SetPoint("BOTTOMRIGHT", KT_Anchor, "BOTTOMRIGHT", 4, -4);
handle:Hide();
KT_Anchor.handle = handle;

KT_MakeBar("cast", 1);
KT_MakeBar("melee", 2);
KT_MakeBar("ranged", 3);
KT_ApplyPosition();

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local KT = CreateFrame("Frame", "KeldurnTimersCore");

local function KT_Register(event)
	pcall(KT.RegisterEvent, KT, event);
end

KT_Register("ADDON_LOADED");
KT_Register("PLAYER_ENTERING_WORLD");
KT_Register("SPELLCAST_START");
KT_Register("SPELLCAST_STOP");
KT_Register("SPELLCAST_FAILED");
KT_Register("SPELLCAST_INTERRUPTED");
KT_Register("SPELLCAST_DELAYED");
KT_Register("SPELLCAST_CHANNEL_START");
KT_Register("SPELLCAST_CHANNEL_UPDATE");
KT_Register("SPELLCAST_CHANNEL_STOP");
KT_Register("CHAT_MSG_COMBAT_SELF_HITS");
KT_Register("CHAT_MSG_COMBAT_SELF_MISSES");
KT_Register("CHAT_MSG_SPELL_SELF_DAMAGE");
KT_Register("PLAYER_LEAVE_COMBAT");
KT_Register("STOP_AUTOREPEAT_SPELL");

KT:SetScript("OnEvent", function(p1, p2, p3, p4)
	-- 1.12 style (globals event/arg1/arg2) or modern (parameters), depending on the client
	local event, a1, a2 = event, arg1, arg2;
	if (type(p1) == "string" and string.find(p1, "^[A-Z_]+$")) then
		event, a1, a2 = p1, p2, p3;
	elseif (type(p2) == "string" and string.find(p2, "^[A-Z_]+$")) then
		event, a1, a2 = p2, p3, p4;
	end

	if (event == "ADDON_LOADED") then
		if (a1 == "KeldurnTimers") then
			if (type(KeldurnTimersDB) ~= "table") then KeldurnTimersDB = {}; end
			KT_ApplyPosition();
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		KT_ApplyPosition();
	elseif (string.find(event, "^SPELLCAST_")) then
		KT_Safe("cast", KT_CastEvent, event, a1, a2);
	elseif (event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_COMBAT_SELF_MISSES") then
		KT_Safe("melee", KT_CombatSelf, a1);
	elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE") then
		KT_Safe("ranged", KT_SpellSelf, a1);
	elseif (event == "PLAYER_LEAVE_COMBAT") then
		if (KT_Bars.melee.active) then KT_Bars.melee.active = false; KT_Bars.melee:Hide(); end
	elseif (event == "STOP_AUTOREPEAT_SPELL") then
		-- Let the shot in progress finish; do not restart it
	end
end);

local KT_TestNext = 0;
KT:SetScript("OnUpdate", function()
	local now = GetTime();
	if (KT_Testing and now >= KT_TestNext) then
		KT_TestNext = now + 3.5;
		KT_Bars.cast.mode = "cast";
		KT_Start("cast", "Hearthstone (test)", 3, KT_COLORS.cast, false);
		KT_Start("melee", "Melee (test)", 2.6, KT_COLORS.melee, false);
		KT_Start("ranged", "Wand (test)", 1.6, KT_COLORS.ranged, false);
	end
	for _, bar in pairs(KT_Bars) do
		KT_Safe("bars", KT_UpdateBar, bar, now);
	end
	KT_Safe("default cast bar", KT_ApplyDefaultCastBar);
end);

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------
local function KT_Toggle(key)
	if (type(KeldurnTimersDB) ~= "table") then KeldurnTimersDB = {}; end
	KeldurnTimersDB[key] = not KT_Opt(key);
	return KeldurnTimersDB[key];
end

SLASH_KELDURNTIMERS1 = "/kt";
SLASH_KELDURNTIMERS2 = "/keldurntimers";
SlashCmdList["KELDURNTIMERS"] = function(msg)
	msg = string.lower(msg or "");
	if (msg == "move") then
		KT_Testing = false;
		KT_SetUnlocked(not KT_Unlocked);
		if (KT_Unlocked) then
			KT_Print("drag the bars with the mouse. Type /kt move again to lock them.");
		else
			KT_SavePosition();
			KT_Print("position saved.");
		end
	elseif (msg == "test") then
		if (KT_Unlocked) then KT_SetUnlocked(false); end
		KT_Testing = not KT_Testing;
		KT_TestNext = 0;
		KT_Print("test mode " .. KT_OnOff(KT_Testing));
	elseif (msg == "cast") then
		KT_Print("cast bar " .. KT_OnOff(KT_Toggle("cast")));
	elseif (msg == "melee") then
		KT_Print("melee bar " .. KT_OnOff(KT_Toggle("melee")));
	elseif (msg == "ranged") then
		KT_Print("ranged/wand bar " .. KT_OnOff(KT_Toggle("ranged")));
	elseif (msg == "hide") then
		local hidden = KT_Toggle("hideDefault");
		if (hidden) then
			KT_Print("default cast bar |cffff4040hidden|r");
		else
			KT_Print("default cast bar |cff00ff00visible|r");
		end
	elseif (msg == "reset") then
		if (type(KeldurnTimersDB) == "table") then KeldurnTimersDB.pos = nil; end
		KT_ApplyPosition();
		KT_Print("position reset.");
	else
		KT_Print("commands:");
		KT_Print("  /kt move - unlock/lock the bars to move them");
		KT_Print("  /kt test - show the bars running so you can position them");
		KT_Print("  /kt cast - cast bar: " .. KT_OnOff(KT_Opt("cast")));
		KT_Print("  /kt melee - melee bar: " .. KT_OnOff(KT_Opt("melee")));
		KT_Print("  /kt ranged - ranged/wand bar: " .. KT_OnOff(KT_Opt("ranged")));
		KT_Print("  /kt hide - hide/show the default cast bar");
		KT_Print("  /kt reset - back to the initial position");
	end
end;
