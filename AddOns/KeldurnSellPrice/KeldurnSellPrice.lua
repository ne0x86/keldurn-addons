-- ============================================================================
-- Keldurn Sell Price
--   Shows the vendor sell price of an item in its tooltip: bags, bank, loot,
--   chat links, quest rewards, trade, auction house, mail...
--
--   Nothing is bundled: prices are learned. Every time a vendor window opens,
--   the items in your bags are scanned and their sell price is stored.
--
-- Written for the Keldurn client: it replaces nothing in the game, it only
-- adds a line to tooltips.
--
-- Commands:  /ksp (help)  /ksp scan  /ksp diag  /ksp reset
-- ============================================================================

local KSP_Reported = {};
local KSP_ReportCount = 0;
local KSP_Scanner;
local KSP_LastMoney;
local KSP_MoneyEvents = 0;
local KSP_Hooked = false;

-- ---------------------------------------------------------------------------
-- Utilities
-- ---------------------------------------------------------------------------
local function KSP_Print(msg)
	if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage) then
		DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffKeldurn Sell Price:|r " .. msg);
	end
end

-- If something fails, report it once in the chat (never error windows)
local function KSP_Report(name, err)
	local key = name .. "|" .. tostring(err);
	if (not KSP_Reported[key] and KSP_ReportCount < 10) then
		KSP_Reported[key] = 1;
		KSP_ReportCount = KSP_ReportCount + 1;
		KSP_Print("error in " .. name .. ": " .. tostring(err));
	end
end

local function KSP_Safe(name, func, a1, a2)
	local ok, err = pcall(func, a1, a2);
	if (not ok) then
		KSP_Report(name, err);
	end
end

-- Always read the saved variable through the global: it is replaced when the
-- saved data is loaded, so a reference kept from file load time would be stale.
local function KSP_Prices()
	if (type(KeldurnSellPriceDB) ~= "table") then
		KeldurnSellPriceDB = {};
	end
	if (type(KeldurnSellPriceDB.prices) ~= "table") then
		KeldurnSellPriceDB.prices = {};
	end
	return KeldurnSellPriceDB.prices;
end

local function KSP_Count()
	local total = 0;
	for _ in pairs(KSP_Prices()) do
		total = total + 1;
	end
	return total;
end

local function KSP_ItemID(link)
	if (type(link) ~= "string") then
		return nil;
	end
	local _, _, id = string.find(link, "item:(%d+)");
	return tonumber(id);
end

local function KSP_MoneyText(copper)
	copper = math.floor(copper + 0.5);
	local gold = math.floor(copper / 10000);
	copper = copper - gold * 10000;
	local silver = math.floor(copper / 100);
	copper = copper - silver * 100;
	local text = "";
	if (gold > 0) then
		text = text .. gold .. "|cffffd700g|r ";
	end
	if (gold > 0 or silver > 0) then
		text = text .. silver .. "|cffc7c7cfs|r ";
	end
	return text .. copper .. "|cffeda55fc|r";
end

-- With a vendor window open the game already shows the price by itself
local function KSP_AtVendor()
	return MerchantFrame and MerchantFrame.IsVisible and MerchantFrame:IsVisible();
end

-- ---------------------------------------------------------------------------
-- Learning prices
-- ---------------------------------------------------------------------------

-- Fired by the hidden tooltip whenever the game adds a money line to it. The
-- amount comes as a global (1.12 style) or as a parameter, depending on client.
local function KSP_OnMoney(p1, p2)
	local money = arg1;
	if (type(p1) == "number") then
		money = p1;
	elseif (type(p2) == "number") then
		money = p2;
	end
	if (InRepairMode and InRepairMode()) then
		return; -- in repair mode the money is the repair cost, not the sell price
	end
	if (type(money) == "number") then
		KSP_MoneyEvents = KSP_MoneyEvents + 1;
		KSP_LastMoney = money;
	end
end

local function KSP_GetScanner()
	if (not KSP_Scanner) then
		KSP_Scanner = CreateFrame("GameTooltip", "KeldurnSellPriceScanner", UIParent, "GameTooltipTemplate");
		KSP_Scanner:SetScript("OnTooltipAddMoney", KSP_OnMoney);
	end
	return KSP_Scanner;
end

-- Reads the sell price of every item in the bags. Only meaningful while a
-- vendor window is open: that is when the game puts a money line in the tooltip.
local function KSP_Scan()
	local scanner = KSP_GetScanner();
	local prices = KSP_Prices();
	local learned, updated = 0, 0;
	for bag = 0, (NUM_BAG_FRAMES or 4) do
		for slot = 1, (GetContainerNumSlots(bag) or 0) do
			local id = KSP_ItemID(GetContainerItemLink(bag, slot));
			local _, count = GetContainerItemInfo(bag, slot);
			if (id and type(count) == "number" and count > 0) then
				KSP_LastMoney = nil;
				scanner:SetOwner(WorldFrame, "ANCHOR_NONE");
				scanner:SetBagItem(bag, slot);
				-- The money shown is for the whole stack
				if (KSP_LastMoney and KSP_LastMoney > 0) then
					local unit = math.floor(KSP_LastMoney / count + 0.5);
					if (prices[id] == nil) then
						learned = learned + 1;
					elseif (prices[id] ~= unit) then
						updated = updated + 1;
					end
					prices[id] = unit;
				end
			end
		end
	end
	scanner:Hide();
	return learned, updated;
end

-- ---------------------------------------------------------------------------
-- Tooltips
-- ---------------------------------------------------------------------------
local function KSP_AddPrice(tip, link, count)
	local id = KSP_ItemID(link);
	if (not id) then
		return;
	end
	local unit = KSP_Prices()[id];
	if (not unit or unit <= 0) then
		return;
	end
	count = tonumber(count) or 1;
	if (count < 1) then
		count = 1; -- items with charges report a negative count
	end
	local total = unit * count;
	if (SetTooltipMoney and pcall(SetTooltipMoney, tip, total)) then
		tip:Show();
		return;
	end
	tip:AddLine(KSP_MoneyText(total), 1, 1, 1);
	tip:Show();
end

-- For every tooltip method, how to get the item link and the stack size from
-- the arguments it was called with. Returning nothing means "no price here".
local KSP_Sources = {
	SetBagItem = function(bag, slot)
		if (KSP_AtVendor()) then return nil; end
		local _, count = GetContainerItemInfo(bag, slot);
		return GetContainerItemLink(bag, slot), count;
	end,
	-- Equipped gear (slots 1-19) is left alone; bank and bag slots get a price
	SetInventoryItem = function(unit, slot)
		if (unit ~= "player" or type(slot) ~= "number" or slot <= 19) then return nil; end
		if (KSP_AtVendor()) then return nil; end
		return GetInventoryItemLink(unit, slot), GetInventoryItemCount(unit, slot);
	end,
	SetLootItem = function(slot)
		local _, _, count = GetLootSlotInfo(slot);
		return GetLootSlotLink(slot), count;
	end,
	SetLootRollItem = function(id)
		local _, _, count = GetLootRollItemInfo(id);
		return GetLootRollItemLink(id), count;
	end,
	SetHyperlink = function(link)
		return link, 1;
	end,
	SetQuestItem = function(kind, index)
		if (kind ~= "reward" and kind ~= "choice") then return nil; end
		local _, _, count = GetQuestItemInfo(kind, index);
		return GetQuestItemLink(kind, index), count;
	end,
	SetQuestLogItem = function(kind, index)
		local _, _, count;
		if (kind == "reward") then
			_, _, count = GetQuestLogRewardInfo(index);
		elseif (kind == "choice") then
			_, _, count = GetQuestLogChoiceInfo(index);
		else
			return nil;
		end
		return GetQuestLogItemLink(kind, index), count;
	end,
	SetAuctionItem = function(kind, index)
		local _, _, count = GetAuctionItemInfo(kind, index);
		return GetAuctionItemLink(kind, index), count;
	end,
	SetTradePlayerItem = function(index)
		local _, _, count = GetTradePlayerItemInfo(index);
		return GetTradePlayerItemLink(index), count;
	end,
	SetTradeTargetItem = function(index)
		local _, _, count = GetTradeTargetItemInfo(index);
		return GetTradeTargetItemLink(index), count;
	end,
	SetTradeSkillItem = function(index, reagent)
		if (reagent) then
			if (not GetTradeSkillReagentItemLink) then return nil; end
			local _, _, count = GetTradeSkillReagentInfo(index, reagent);
			return GetTradeSkillReagentItemLink(index, reagent), count;
		end
		return GetTradeSkillItemLink(index), GetTradeSkillNumMade(index);
	end,
	SetCraftItem = function(skill, slot)
		if (not GetCraftReagentItemLink) then return nil; end
		local _, _, count = GetCraftReagentInfo(skill, slot);
		return GetCraftReagentItemLink(skill, slot), count;
	end,
	SetCraftSpell = function(slot)
		return GetCraftItemLink(slot), 1;
	end,
	SetInboxItem = function(mail, index)
		if (not GetInboxItemLink) then return nil; end
		local _, _, count = GetInboxItem(mail, index);
		return GetInboxItemLink(mail, index), count;
	end,
	SetSendMailItem = function(index)
		if (not GetSendMailItemLink) then return nil; end
		local _, _, count = GetSendMailItem(index);
		return GetSendMailItemLink(index), count;
	end,
};

local function KSP_Apply(tip, source, a1, a2, a3)
	local link, count = source(a1, a2, a3);
	KSP_AddPrice(tip, link, count);
end

-- Wraps one tooltip method: the original runs first and its results are
-- returned untouched, then the price line is added (protected, so a failure
-- never breaks the tooltip).
local function KSP_Hook(tip, method, source)
	local original = tip[method];
	if (type(original) ~= "function") then
		return;
	end
	tip[method] = function(self, a1, a2, a3, a4)
		local r1, r2, r3, r4 = original(self, a1, a2, a3, a4);
		local ok, err = pcall(KSP_Apply, self, source, a1, a2, a3);
		if (not ok) then
			KSP_Report(method, err);
		end
		return r1, r2, r3, r4;
	end
end

local function KSP_InstallHooks()
	if (KSP_Hooked) then
		return;
	end
	KSP_Hooked = true;
	-- AtlasLoot creates its tooltip after us, which is why this runs late
	for _, name in ipairs({ "GameTooltip", "ItemRefTooltip", "AtlasLootTooltip" }) do
		local tip = getglobal(name);
		if (tip) then
			for method, source in pairs(KSP_Sources) do
				KSP_Hook(tip, method, source);
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local KSP = CreateFrame("Frame", "KeldurnSellPriceCore");

local function KSP_Register(event)
	pcall(KSP.RegisterEvent, KSP, event);
end

KSP_Register("PLAYER_ENTERING_WORLD");
KSP_Register("MERCHANT_SHOW");

KSP:SetScript("OnEvent", function(p1, p2)
	-- 1.12 style (global event) or modern (parameters), depending on the client
	local event = event;
	if (type(p1) == "string") then
		event = p1;
	elseif (type(p2) == "string") then
		event = p2;
	end
	if (event == "PLAYER_ENTERING_WORLD") then
		KSP_Safe("hooks", KSP_InstallHooks);
	elseif (event == "MERCHANT_SHOW") then
		KSP_Safe("scan", KSP_Scan);
	end
end);

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------
local function KSP_Describe(value)
	if (type(value) == "string") then
		return "\"" .. string.gsub(value, "|", "||") .. "\"";
	end
	return tostring(value);
end

local function KSP_FirstBagItem()
	for bag = 0, (NUM_BAG_FRAMES or 4) do
		for slot = 1, (GetContainerNumSlots(bag) or 0) do
			local id = KSP_ItemID(GetContainerItemLink(bag, slot));
			if (id) then
				return id;
			end
		end
	end
	return nil;
end

local function KSP_Diag()
	KSP_Print("diagnostics:");
	KSP_Print("  known prices: " .. KSP_Count());
	KSP_Print("  SetTooltipMoney=" .. tostring(SetTooltipMoney ~= nil)
		.. " MerchantFrame=" .. tostring(MerchantFrame ~= nil)
		.. " InRepairMode=" .. tostring(InRepairMode ~= nil)
		.. " GetInboxItemLink=" .. tostring(GetInboxItemLink ~= nil));
	KSP_Print("  hooks installed=" .. tostring(KSP_Hooked)
		.. ", scanner created=" .. tostring(KSP_Scanner ~= nil)
		.. ", money events from the scanner=" .. KSP_MoneyEvents
		.. ", last amount=" .. tostring(KSP_LastMoney));
	local id = KSP_FirstBagItem();
	if (not id) then
		KSP_Print("  no items in the bags to inspect");
		return;
	end
	-- Does this client already return a sell price from GetItemInfo? Show
	-- everything it returns for the first item found in the bags.
	local v = {};
	v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9], v[10], v[11], v[12] = GetItemInfo("item:" .. id .. ":0:0:0");
	KSP_Print("  GetItemInfo(item:" .. id .. ") =");
	KSP_Print("    " .. KSP_Describe(v[1]) .. ", " .. KSP_Describe(v[2]) .. ", " .. KSP_Describe(v[3]) .. ", " .. KSP_Describe(v[4]) .. ", " .. KSP_Describe(v[5]) .. ", " .. KSP_Describe(v[6]));
	KSP_Print("    " .. KSP_Describe(v[7]) .. ", " .. KSP_Describe(v[8]) .. ", " .. KSP_Describe(v[9]) .. ", " .. KSP_Describe(v[10]) .. ", " .. KSP_Describe(v[11]) .. ", " .. KSP_Describe(v[12]));
	KSP_Print("  learned price of this item: " .. tostring(KSP_Prices()[id]));
end

SLASH_KELDURNSELLPRICE1 = "/ksp";
SLASH_KELDURNSELLPRICE2 = "/keldurnsellprice";
SlashCmdList["KELDURNSELLPRICE"] = function(msg)
	msg = string.lower(msg or "");
	if (msg == "scan") then
		if (MerchantFrame and MerchantFrame.IsVisible and not MerchantFrame:IsVisible()) then
			KSP_Print("open a vendor window first");
			return;
		end
		local ok, learned, updated = pcall(KSP_Scan);
		if (ok) then
			KSP_Print("learned " .. learned .. " new prices, updated " .. updated .. " (" .. KSP_Count() .. " known)");
		else
			KSP_Report("scan", learned);
		end
	elseif (msg == "diag") then
		KSP_Safe("diagnostics", KSP_Diag);
	elseif (msg == "reset") then
		KeldurnSellPriceDB = {};
		KSP_Print("all learned prices forgotten");
	else
		KSP_Print("commands:");
		KSP_Print("  /ksp scan - read the prices of the items in your bags (vendor window open)");
		KSP_Print("  /ksp diag - debugging info (if prices do not show up)");
		KSP_Print("  /ksp reset - forget all learned prices");
		KSP_Print("  " .. KSP_Count() .. " prices known");
	end
end;
