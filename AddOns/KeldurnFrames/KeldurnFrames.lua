-- ============================================================================
-- Keldurn Frames
--   * Health and mana numbers on the target frame (exact values if the game provides them; otherwise %)
--   * Buffs and debuffs for each party member, next to their frame
--
-- Written for the Keldurn client: it does not replace any game function or frame,
-- it only adds texts and icons on top of the frames that already exist.
--
-- Commands:  /kf  (help)   /kf text   /kf party   /kf buffs   /kf debuffs   /kf test   /kf diag
-- ============================================================================

local KF_FONT = "Fonts\\FRIZQT__.TTF";
local KF_mod = math.mod or math.fmod;
local KF_SOLID = "Interface\\Buttons\\WHITE8X8";

local KF_DEFAULTS = { text = true, partytext = true, buffs = true, debuffs = true };

local KF_MAX_BUFFS = 16;
local KF_MAX_DEBUFFS = 8;
local KF_PER_ROW = 8;
local KF_BUFF_SIZE = 16;
local KF_DEBUFF_SIZE = 18;

local KF_DEBUFF_COLORS = {
	["Magic"]   = { 0.20, 0.60, 1.00 },
	["Curse"]   = { 0.60, 0.00, 1.00 },
	["Disease"] = { 0.60, 0.40, 0.00 },
	["Poison"]  = { 0.00, 0.60, 0.00 },
};
local KF_DEBUFF_NONE = { 0.80, 0.00, 0.00 };

local KF_Target = {};
local KF_Party = {};
local KF_TestMode = false;
local KF_Reported = {};

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------
local function KF_Print(msg)
	if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage) then
		DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffKeldurn Frames:|r " .. msg);
	end
end

-- If something fails, report it once in chat (never error popups)
local KF_ReportCount = 0;
local function KF_Safe(name, func, a1, a2)
	local ok, err = pcall(func, a1, a2);
	if (not ok) then
		local key = name .. "|" .. tostring(err);
		if (not KF_Reported[key] and KF_ReportCount < 10) then
			KF_Reported[key] = 1;
			KF_ReportCount = KF_ReportCount + 1;
			KF_Print("error in " .. name .. ": " .. tostring(err));
		end
	end
end

local function KF_Opt(key)
	if (KeldurnFramesDB and KeldurnFramesDB[key] ~= nil) then
		return KeldurnFramesDB[key];
	end
	return KF_DEFAULTS[key];
end

-- Tells MobInfo2 (if installed) that this addon already draws the target text
local function KF_SyncFlags()
	KeldurnFrames_HandlesTargetText = KF_Opt("text") and true or nil;
end

local function KF_OnOff(value)
	if (value) then return "|cff00ff00enabled|r"; end
	return "|cffff4040disabled|r";
end

-- ---------------------------------------------------------------------------
-- Target health and mana
-- ---------------------------------------------------------------------------
local function KF_MakeBarText(parent, bar, fallbackX, fallbackY, size)
	if (bar and bar.kfText) then
		return bar.kfText;
	end
	local holder = CreateFrame("Frame", nil, parent);
	if (bar) then
		holder:SetAllPoints(bar);
	else
		-- Position of the bars on the original target frame
		holder:SetWidth(119);
		holder:SetHeight(12);
		holder:SetPoint("TOPRIGHT", parent, "TOPRIGHT", fallbackX, fallbackY);
	end
	local level = parent:GetFrameLevel();
	if (bar and bar.GetFrameLevel) then
		level = bar:GetFrameLevel();
	end
	holder:SetFrameLevel(level + 3);

	local text = holder:CreateFontString(nil, "OVERLAY");
	text:SetFont(KF_FONT, size or 12, "OUTLINE");
	text:SetTextColor(1, 1, 1);
	text:SetPoint("CENTER", holder, "CENTER", 0, 0);
	if (bar) then
		bar.kfText = text;
	end
	return text;
end

local function KF_SetupTarget()
	if (KF_Target.health or not TargetFrame) then
		return;
	end
	KF_Target.health = KF_MakeBarText(TargetFrame, getglobal("TargetFrameHealthBar"), -106, -41);
	KF_Target.power  = KF_MakeBarText(TargetFrame, getglobal("TargetFrameManaBar"),   -106, -52);
end

-- In vanilla the server only sends the health % of units outside your group
-- (the maximum arrives as 100). In that case the percentage is shown.
local function KF_IsExact(unit, maxValue)
	if (maxValue ~= 100) then return true; end
	if (UnitIsUnit(unit, "player") or UnitIsUnit(unit, "pet")) then return true; end
	if (UnitInParty and UnitInParty(unit)) then return true; end
	if (UnitInRaid and UnitInRaid(unit)) then return true; end
	return false;
end

local function KF_Format(current, maxValue, exact)
	if (not current or not maxValue or maxValue <= 0) then
		return "";
	end
	if (exact) then
		return current .. " / " .. maxValue;
	end
	return math.floor(current / maxValue * 100 + 0.5) .. "%";
end

local function KF_UpdateTarget()
	KF_SetupTarget();
	if (not KF_Target.health) then
		return;
	end
	local health, power = KF_Target.health, KF_Target.power;

	if (not KF_Opt("text") or not UnitExists("target")) then
		health:SetText("");
		power:SetText("");
		return;
	end

	if (UnitIsGhost("target")) then
		health:SetText("Ghost");
		power:SetText("");
		return;
	elseif (UnitIsDead("target")) then
		health:SetText("Dead");
		power:SetText("");
		return;
	elseif (UnitIsPlayer("target") and UnitIsConnected and not UnitIsConnected("target")) then
		health:SetText("Offline");
		power:SetText("");
		return;
	end

	local hp, hpMax = UnitHealth("target"), UnitHealthMax("target");
	local exact = KF_IsExact("target", hpMax);
	-- If MobInfo2 is installed, use its estimate of the mob's hit points
	if (not exact and MobHealth_GetTargetCurHP and MobHealth_GetTargetMaxHP) then
		local ok, estCur = pcall(MobHealth_GetTargetCurHP);
		local ok2, estMax = pcall(MobHealth_GetTargetMaxHP);
		if (ok and ok2 and type(estCur) == "number" and type(estMax) == "number" and estMax > 0) then
			hp, hpMax, exact = math.floor(estCur + 0.5), math.floor(estMax + 0.5), true;
		end
	end
	health:SetText(KF_Format(hp, hpMax, exact));

	local mp, mpMax = UnitMana("target"), UnitManaMax("target");
	if (mpMax and mpMax > 0) then
		power:SetText(KF_Format(mp, mpMax, KF_IsExact("target", mpMax)));
	else
		power:SetText("");
	end
end

-- ---------------------------------------------------------------------------
-- Party buffs and debuffs
-- ---------------------------------------------------------------------------

-- Reads a buff/debuff without assuming the exact order of what the client returns:
-- 1.12 gives (texture, count, type); other clients give (name, rank, texture,
-- count, type...). We look for the texture, the count right after it, and the type.
local KF_DEBUFF_TYPES = { ["Magic"] = 1, ["Curse"] = 1, ["Disease"] = 1, ["Poison"] = 1 };

local function KF_IsIconPath(value)
	return type(value) == "string" and (string.find(value, "\\", 1, true) or string.find(value, "/", 1, true));
end

local function KF_ReadAura(isDebuff, unit, index)
	local v = {};
	if (isDebuff) then
		v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8] = UnitDebuff(unit, index);
	else
		v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8] = UnitBuff(unit, index);
	end
	if (v[1] == nil) then
		return nil;
	end
	local texIndex, texture;
	for i = 1, 8 do
		if (KF_IsIconPath(v[i])) then
			texIndex, texture = i, v[i];
			break;
		end
	end
	if (not texture) then
		-- icon name without a path (e.g. "Spell_Holy_WordFortitude")
		for i = 1, 8 do
			if (type(v[i]) == "string" and string.find(v[i], "^%a+_[%w_]+$")) then
				texIndex, texture = i, "Interface\\Icons\\" .. v[i];
				break;
			end
		end
	end
	if (not texture) then
		return nil;
	end
	local count = tonumber(v[texIndex + 1]);
	local debuffType;
	for i = 1, 8 do
		if (type(v[i]) == "string" and KF_DEBUFF_TYPES[v[i]]) then
			debuffType = v[i];
			break;
		end
	end
	return texture, count, debuffType;
end

-- Visible frame of each party member. First the classic name
-- (PartyMemberFrameN); if it is not visible, look for a visible frame whose
-- "unit" field is "partyN".
local function KF_FindPartyFrame(i)
	local unit = "party" .. i;
	local named = getglobal("PartyMemberFrame" .. i);
	if (named and named.IsVisible and named:IsVisible()) then
		return named;
	end
	local best, bestWidth;
	for name, obj in pairs(getfenv(0)) do
		if (type(obj) == "table" and type(name) == "string" and rawget(obj, "unit") == unit) then
			local ok, visible = pcall(function() return obj:IsVisible(); end);
			if (ok and visible) then
				local ok2, width = pcall(function() return obj:GetWidth(); end);
				if (ok2 and type(width) == "number" and (not bestWidth or width > bestWidth)) then
					best, bestWidth = obj, width;
				end
			end
		end
	end
	return best;
end

-- Health and mana bars of a frame: by classic name or among its children
local function KF_FindBars(frame)
	if (not frame) then
		return nil, nil;
	end
	local name = frame.GetName and frame:GetName();
	local health = name and getglobal(name .. "HealthBar");
	local power = name and getglobal(name .. "ManaBar");
	if (health and power) then
		return health, power;
	end
	local bars = {};
	if (frame.GetChildren) then
		local children = { frame:GetChildren() };
		for _, child in ipairs(children) do
			local ok, kind = pcall(function() return child:GetObjectType(); end);
			if (ok and kind == "StatusBar") then
				table.insert(bars, child);
			end
		end
	end
	table.sort(bars, function(x, y) return (x:GetTop() or 0) > (y:GetTop() or 0); end);
	return health or bars[1], power or bars[2];
end

local function KF_ShowTooltip(button)
	if (not button.unit or not button.index or not GameTooltip) then
		return;
	end
	GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT");
	if (button.isDebuff) then
		if (GameTooltip.SetUnitDebuff) then GameTooltip:SetUnitDebuff(button.unit, button.index); end
	else
		if (GameTooltip.SetUnitBuff) then GameTooltip:SetUnitBuff(button.unit, button.index); end
	end
	GameTooltip:Show();
end

local function KF_MakeIcon(parent, size, isDebuff)
	local button = CreateFrame("Button", nil, parent);
	button:SetWidth(size);
	button:SetHeight(size);
	button.isDebuff = isDebuff;

	if (isDebuff) then
		local border = button:CreateTexture(nil, "BACKGROUND");
		border:SetTexture(KF_SOLID);
		border:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1);
		border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1);
		button.border = border;
	end

	local icon = button:CreateTexture(nil, "ARTWORK");
	icon:SetAllPoints(button);
	button.icon = icon;

	local count = button:CreateFontString(nil, "OVERLAY");
	count:SetFont(KF_FONT, 9, "OUTLINE");
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -1);
	button.count = count;

	button:EnableMouse(true);
	button:SetScript("OnEnter", function() KF_Safe("tooltip", KF_ShowTooltip, button); end);
	button:SetScript("OnLeave", function() if (GameTooltip) then GameTooltip:Hide(); end end);
	button:Hide();
	return button;
end

local function KF_BuildParty(i)
	local holder = CreateFrame("Frame", "KeldurnFramesParty" .. i, UIParent);
	holder:SetWidth(KF_PER_ROW * (KF_BUFF_SIZE + 1));
	holder:SetHeight(KF_BUFF_SIZE * 2 + KF_DEBUFF_SIZE + 6);
	holder.buffs = {};
	holder.debuffs = {};
	for j = 1, KF_MAX_BUFFS do
		holder.buffs[j] = KF_MakeIcon(holder, KF_BUFF_SIZE, false);
		local row = math.floor((j - 1) / KF_PER_ROW);
		local col = KF_mod(j - 1, KF_PER_ROW);
		holder.buffs[j]:SetPoint("TOPLEFT", holder, "TOPLEFT", col * (KF_BUFF_SIZE + 1), -row * (KF_BUFF_SIZE + 1));
	end
	for j = 1, KF_MAX_DEBUFFS do
		holder.debuffs[j] = KF_MakeIcon(holder, KF_DEBUFF_SIZE, true);
	end
	holder:Hide();
	KF_Party[i] = holder;
	return holder;
end

-- Where each row goes: to the right of each party member's frame.
-- In test mode, row 1 shows YOUR auras below your frame.
local function KF_PlaceParty(i)
	local holder = KF_Party[i] or KF_BuildParty(i);
	local unit = "party" .. i;
	local anchor = KF_FindPartyFrame(i);
	holder:ClearAllPoints();
	holder.texts = nil;
	if (KF_TestMode and i == 1) then
		unit = "player";
		anchor = PlayerFrame;
		holder:SetParent(UIParent);
		holder:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 106, 30);
	elseif (anchor) then
		holder:SetParent(anchor);
		holder:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 2, -2);
		local healthBar, powerBar = KF_FindBars(anchor);
		if (healthBar) then
			holder.texts = {
				health = KF_MakeBarText(anchor, healthBar, 0, 0, 9),
				power = powerBar and KF_MakeBarText(anchor, powerBar, 0, 0, 9),
			};
		end
		holder.healthBar, holder.powerBar = healthBar, powerBar;
	else
		-- In case the client has no party frames with that name
		holder:SetParent(UIParent);
		holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 150, -160 - (i - 1) * 64);
	end
	holder.unit = unit;
	holder.anchor = anchor;
	return holder;
end

local function KF_UpdateParty(i)
	local holder = KF_Party[i];
	if (not holder) then
		return;
	end
	local unit = holder.unit;
	local showBuffs, showDebuffs = KF_Opt("buffs"), KF_Opt("debuffs");

	-- Health and mana numbers over the bars of the party frame
	local texts = holder.texts;
	if (texts and texts.health) then
		local healthText, powerText = "", "";
		if (KF_Opt("partytext") and UnitExists(unit)) then
			if (UnitIsConnected and not UnitIsConnected(unit)) then
				healthText = "Offline";
			elseif (UnitIsGhost(unit)) then
				healthText = "Ghost";
			elseif (UnitIsDead(unit)) then
				healthText = "Dead";
			else
				healthText = KF_Format(UnitHealth(unit), UnitHealthMax(unit), true);
				local mpMax = UnitManaMax(unit);
				if (mpMax and mpMax > 0) then
					powerText = KF_Format(UnitMana(unit), mpMax, true);
				end
			end
		end
		texts.health:SetText(healthText);
		if (texts.power) then
			texts.power:SetText(powerText);
		end
	end

	if (not UnitExists(unit) or (not showBuffs and not showDebuffs)) then
		holder:Hide();
		return;
	end

	-- Buffs
	local shown = 0;
	for j = 1, KF_MAX_BUFFS do
		local button = holder.buffs[j];
		local texture, count;
		if (showBuffs) then
			texture, count = KF_ReadAura(false, unit, j);
		end
		if (texture) then
			button.icon:SetTexture(texture);
			if (type(count) == "number" and count > 1) then button.count:SetText(count); else button.count:SetText(""); end
			button.unit, button.index = unit, j;
			button:Show();
			shown = j;
		else
			button:Hide();
		end
	end

	-- Debuffs, on the row after the last buff row
	local rows = math.ceil(shown / KF_PER_ROW);
	local y = -rows * (KF_BUFF_SIZE + 1) - 2;
	for j = 1, KF_MAX_DEBUFFS do
		local button = holder.debuffs[j];
		local texture, count, debuffType;
		if (showDebuffs) then
			texture, count, debuffType = KF_ReadAura(true, unit, j);
		end
		if (texture) then
			button:ClearAllPoints();
			button:SetPoint("TOPLEFT", holder, "TOPLEFT", (j - 1) * (KF_DEBUFF_SIZE + 3) + 1, y);
			button.icon:SetTexture(texture);
			if (type(count) == "number" and count > 1) then button.count:SetText(count); else button.count:SetText(""); end
			local color = KF_DEBUFF_COLORS[debuffType or ""] or KF_DEBUFF_NONE;
			button.border:SetVertexColor(color[1], color[2], color[3]);
			button.unit, button.index = unit, j;
			button:Show();
		else
			button:Hide();
		end
	end

	holder:Show();
end

local function KF_PlaceAllParty()
	for i = 1, 4 do
		KF_PlaceParty(i);
	end
end

local function KF_UpdateAllParty()
	for i = 1, 4 do
		KF_UpdateParty(i);
	end
end

-- ---------------------------------------------------------------------------
-- Events and refresh
-- ---------------------------------------------------------------------------
local KF = CreateFrame("Frame", "KeldurnFramesCore");

local function KF_Register(event)
	-- Some event names may not exist in Keldurn: that is fine
	pcall(KF.RegisterEvent, KF, event);
end

KF_Register("ADDON_LOADED");
KF_Register("PLAYER_ENTERING_WORLD");
KF_Register("PLAYER_TARGET_CHANGED");
KF_Register("PARTY_MEMBERS_CHANGED");
KF_Register("UNIT_AURA");
KF_Register("PLAYER_AURAS_CHANGED");
KF_Register("UNIT_HEALTH");
KF_Register("UNIT_MAXHEALTH");
KF_Register("UNIT_MANA");
KF_Register("UNIT_MAXMANA");
KF_Register("UNIT_RAGE");
KF_Register("UNIT_ENERGY");
KF_Register("UNIT_FOCUS");
KF_Register("UNIT_DISPLAYPOWER");
KF_Register("UNIT_POWER_UPDATE");
KF_Register("UNIT_MAXPOWER");

KF:SetScript("OnEvent", function(p1, p2, p3)
	-- 1.12 style (event/arg1 globals) or modern style (parameters), depending on the client
	local event, arg1 = event, arg1;
	if (type(p1) == "string") then
		event, arg1 = p1, p2;
	elseif (type(p2) == "string") then
		event, arg1 = p2, p3;
	end
	if (event == "ADDON_LOADED") then
		if (arg1 == "KeldurnFrames") then
			if (type(KeldurnFramesDB) ~= "table") then
				KeldurnFramesDB = {};
			end
			KF_SyncFlags();
		end
		return;
	end
	if (event == "PLAYER_ENTERING_WORLD" or event == "PARTY_MEMBERS_CHANGED") then
		KF_Safe("party", KF_PlaceAllParty);
		KF_Safe("party", KF_UpdateAllParty);
		KF_Safe("target", KF_UpdateTarget);
		return;
	end
	if (event == "UNIT_AURA" or event == "PLAYER_AURAS_CHANGED") then
		KF_Safe("party", KF_UpdateAllParty);
		return;
	end
	if (event == "PLAYER_TARGET_CHANGED" or arg1 == "target") then
		KF_Safe("target", KF_UpdateTarget);
	end
end);

-- Periodic refresh in case some event does not arrive in Keldurn
local KF_TargetTimer, KF_PartyTimer = 0, 0;
KF:SetScript("OnUpdate", function(p1, p2)
	local elapsed = arg1;
	if (type(p2) == "number") then
		elapsed = p2;
	elseif (type(p1) == "number") then
		elapsed = p1;
	end
	if (type(elapsed) ~= "number") then
		elapsed = 0.05;
	end
	KF_TargetTimer = KF_TargetTimer + elapsed;
	KF_PartyTimer = KF_PartyTimer + elapsed;
	if (KF_TargetTimer >= 0.15) then
		KF_TargetTimer = 0;
		KF_Safe("target", KF_UpdateTarget);
	end
	if (KF_PartyTimer >= 0.25) then
		KF_PartyTimer = 0;
		KF_Safe("party", KF_UpdateAllParty);
	end
end);

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------
local function KF_Describe(value)
	if (type(value) == "string") then
		return "\"" .. value .. "\"";
	end
	return tostring(value);
end

local function KF_Diag()
	KF_Print("diagnostics:");
	KF_Print("  target: TargetFrameHealthBar=" .. tostring(getglobal("TargetFrameHealthBar") ~= nil)
		.. " TargetFrameManaBar=" .. tostring(getglobal("TargetFrameManaBar") ~= nil));
	for i = 1, 4 do
		local unit = "party" .. i;
		if (UnitExists(unit)) then
			local named = getglobal("PartyMemberFrame" .. i);
			local frame = KF_FindPartyFrame(i);
			local health, power = KF_FindBars(frame);
			local frameName = frame and frame.GetName and frame:GetName() or (frame and "(unnamed)") or "none";
			KF_Print("  " .. unit .. " (" .. tostring(UnitName(unit)) .. "): PartyMemberFrame" .. i .. "="
				.. (named and ((named:IsVisible() and "visible") or "hidden") or "missing")
				.. ", frame used=" .. frameName
				.. ", bars=" .. tostring(health ~= nil) .. "/" .. tostring(power ~= nil));
			local a1, a2, a3, a4, a5 = UnitBuff(unit, 1);
			KF_Print("    UnitBuff 1 = " .. KF_Describe(a1) .. ", " .. KF_Describe(a2) .. ", " .. KF_Describe(a3) .. ", " .. KF_Describe(a4) .. ", " .. KF_Describe(a5));
			local d1, d2, d3, d4, d5 = UnitDebuff(unit, 1);
			KF_Print("    UnitDebuff 1 = " .. KF_Describe(d1) .. ", " .. KF_Describe(d2) .. ", " .. KF_Describe(d3) .. ", " .. KF_Describe(d4) .. ", " .. KF_Describe(d5));
		end
	end
end

local function KF_Toggle(key)
	if (type(KeldurnFramesDB) ~= "table") then
		KeldurnFramesDB = {};
	end
	KeldurnFramesDB[key] = not KF_Opt(key);
	KF_SyncFlags();
	return KeldurnFramesDB[key];
end

SLASH_KELDURNFRAMES1 = "/kf";
SLASH_KELDURNFRAMES2 = "/keldurnframes";
SlashCmdList["KELDURNFRAMES"] = function(msg)
	msg = string.lower(msg or "");
	if (msg == "text") then
		KF_Print("target health/mana " .. KF_OnOff(KF_Toggle("text")));
	elseif (msg == "party") then
		KF_Print("party health/mana " .. KF_OnOff(KF_Toggle("partytext")));
	elseif (msg == "diag") then
		KF_Safe("diagnostics", KF_Diag);
		return;
	elseif (msg == "buffs") then
		KF_Print("party buffs " .. KF_OnOff(KF_Toggle("buffs")));
	elseif (msg == "debuffs") then
		KF_Print("party debuffs " .. KF_OnOff(KF_Toggle("debuffs")));
	elseif (msg == "test") then
		KF_TestMode = not KF_TestMode;
		KF_Print("test mode " .. KF_OnOff(KF_TestMode) .. " (shows your own buffs/debuffs below your frame)");
	else
		KF_Print("commands:");
		KF_Print("  /kf text - target health/mana: " .. KF_OnOff(KF_Opt("text")));
		KF_Print("  /kf party - party health/mana: " .. KF_OnOff(KF_Opt("partytext")));
		KF_Print("  /kf buffs - party buffs: " .. KF_OnOff(KF_Opt("buffs")));
		KF_Print("  /kf debuffs - party debuffs: " .. KF_OnOff(KF_Opt("debuffs")));
		KF_Print("  /kf test - show your own buffs/debuffs to check that it works");
		KF_Print("  /kf diag - debugging info (if something does not show up)");
		return;
	end
	KF_Safe("party", KF_PlaceAllParty);
	KF_Safe("party", KF_UpdateAllParty);
	KF_Safe("target", KF_UpdateTarget);
end;

KF_SyncFlags();
