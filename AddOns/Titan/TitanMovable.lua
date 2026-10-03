TITAN_PANEL_PLACE_TOP = 1;
TITAN_PANEL_PLACE_BOTTOM = 2;

-- [Keldurn fix] The Keldurn client does not create every frame of the original
-- Blizzard interface (e.g. TutorialFrameParent). These helpers avoid errors
-- when a frame does not exist: if it is missing, it is simply not moved.
local function TitanMovable_IsShown(frame)
	return frame and frame.IsVisible and frame:IsVisible();
end

local function TitanMovable_SetPoint(frame, point, relativeTo, relativePoint, x, y)
	if (frame and frame.SetPoint) then
		frame:SetPoint(point, relativeTo, relativePoint, x, y);
	end
end

local function TitanMovable_Height(frame)
	if (frame and frame.GetHeight) then
		return frame:GetHeight() or 0;
	end
	return 0;
end

TitanMovable = {};
TitanMovableData = {
	PlayerFrame = {frameName = "PlayerFrame", frameArchor = "TOPLEFT", xArchor = "LEFT", y = -4, position = TITAN_PANEL_PLACE_TOP},
	TargetFrame = {frameName = "TargetFrame", frameArchor = "TOPLEFT", xArchor = "LEFT", y = -4, position = TITAN_PANEL_PLACE_TOP},
	PartyMemberFrame1 = {frameName = "PartyMemberFrame1", frameArchor = "TOPLEFT", xArchor = "LEFT", y = -128, position = TITAN_PANEL_PLACE_TOP},
	TicketStatusFrame = {frameName = "TicketStatusFrame", frameArchor = "TOPRIGHT", xArchor = "RIGHT", y = 0, position = TITAN_PANEL_PLACE_TOP},
	TemporaryEnchantFrame = {frameName = "TemporaryEnchantFrame", frameArchor = "TOPRIGHT", xArchor = "RIGHT", y = -13, position = TITAN_PANEL_PLACE_TOP},
	MinimapCluster = {frameName = "MinimapCluster", frameArchor = "TOPRIGHT", xArchor = "RIGHT", y = 0, position = TITAN_PANEL_PLACE_TOP},
	WorldStateAlwaysUpFrame = {frameName = "WorldStateAlwaysUpFrame", frameArchor = "TOP", xArchor = "CENTER", y = -15, position = TITAN_PANEL_PLACE_TOP},
	MainMenuBar = {frameName = "MainMenuBar", frameArchor = "BOTTOM", xArchor = "CENTER", y = 0, position = TITAN_PANEL_PLACE_BOTTOM},
	MultiBarRight = {frameName = "MultiBarRight", frameArchor = "BOTTOMRIGHT", xArchor = "RIGHT", y = 98, position = TITAN_PANEL_PLACE_BOTTOM},
	CT_PlayerFrame_Drag = {frameName = "CT_PlayerFrame_Drag", frameArchor = "TOPLEFT", xArchor = "LEFT", y = -25, position = TITAN_PANEL_PLACE_TOP},
	CT_TargetFrame_Drag = {frameName = "CT_TargetFrame_Drag", frameArchor = "TOPLEFT", xArchor = "LEFT", y = -25, position = TITAN_PANEL_PLACE_TOP},
	Gypsy_PlayerFrameCapsule = {frameName = "Gypsy_PlayerFrameCapsule", frameArchor = "TOPLEFT", xArchor = "LEFT", y = 14, position = TITAN_PANEL_PLACE_TOP},
	Gypsy_TargetFrameCapsule = {frameName = "Gypsy_TargetFrameCapsule", frameArchor = "TOPLEFT", xArchor = "LEFT", y = 16, position = TITAN_PANEL_PLACE_TOP},
}

function TitanMovableFrame_OnLoad()
	-- Overwrite Blizzard Frame positioning functions
	WoW_TicketStatusFrame_OnEvent = TicketStatusFrame_OnEvent;
	TicketStatusFrame_OnEvent = Titan_TicketStatusFrame_OnEvent;	

	WoW_FCF_UpdateDockPosition = FCF_UpdateDockPosition;
	FCF_UpdateDockPosition = Titan_FCF_UpdateDockPosition;	
	
	WoW_FCF_UpdateCombatLogPosition = FCF_UpdateCombatLogPosition;
	FCF_UpdateCombatLogPosition = Titan_FCF_UpdateCombatLogPosition;
	
	if TitanPanelGetVar("CastingBar") then
		WoW_CastingBarFrame_UpdatePosition = CastingBarFrame_UpdatePosition;
		CastingBarFrame_UpdatePosition = Titan_CastingBarFrame_UpdatePosition;		
	end

	WoW_UIParent_ManageRightSideFrames = UIParent_ManageRightSideFrames;
	UIParent_ManageRightSideFrames = Titan_UIParent_ManageRightSideFrames;
end

function TitanMovableFrame_CheckFrames(position)
	local top, bottom, panelYOffset, frameTop;
	
	TitanMovable = {};
		
	if (position == TITAN_PANEL_PLACE_TOP) then
	
		panelYOffset = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_TOP, TitanPanelGetVar("BothBars"));
		
		-- Move PlayerFrame
		if (CT_PlayerFrame_Drag) then
			frameTop = TitanMovableFrame_GetOffset(CT_PlayerFrame_Drag, "TOP");
			top = -25 + panelYOffset;
			TitanMovableFrame_CheckTopFrame(frameTop, top, CT_PlayerFrame_Drag:GetName());
		elseif (Gypsy_PlayerFrameCapsule) then
			frameTop = TitanMovableFrame_GetOffset(Gypsy_PlayerFrameCapsule, "TOP");
			top = 14 + panelYOffset;
			TitanMovableFrame_CheckTopFrame(frameTop, top, Gypsy_PlayerFrameCapsule:GetName());
		elseif (PlayerFrame) then
			frameTop = TitanMovableFrame_GetOffset(PlayerFrame, "TOP");
			top = -4 + panelYOffset;
			TitanMovableFrame_CheckTopFrame(frameTop, top, PlayerFrame:GetName())
		end
	
		-- Move TargetFrame
		if (CT_TargetFrame_Drag) then
			frameTop = TitanMovableFrame_GetOffset(CT_TargetFrame_Drag, "TOP");
			top = -25 + panelYOffset;
			TitanMovableFrame_CheckTopFrame(frameTop, top, CT_TargetFrame_Drag:GetName());
		elseif (Gypsy_TargetFrameCapsule) then
			frameTop = TitanMovableFrame_GetOffset(Gypsy_TargetFrameCapsule, "TOP");
			top = 14 + panelYOffset;
			TitanMovableFrame_CheckTopFrame(frameTop, top, Gypsy_TargetFrameCapsule:GetName());
		elseif (TargetFrame) then
			frameTop = TitanMovableFrame_GetOffset(TargetFrame, "TOP");
			top = -4 + panelYOffset;
			TitanMovableFrame_CheckTopFrame(frameTop, top, TargetFrame:GetName())
		end

		-- Move PartyMemberFrame
		if (not CT_MovableParty1_Drag and not Gypsy_PartyFrameCapsule and PartyMemberFrame1) then
			frameTop = TitanMovableFrame_GetOffset(PartyMemberFrame1, "TOP");
			top = -128 + panelYOffset;
			TitanMovableFrame_CheckTopFrame(frameTop, top, PartyMemberFrame1:GetName())
		end

		-- Move TicketStatusFrame
		if (TicketStatusFrame) then
		frameTop = TitanMovableFrame_GetOffset(TicketStatusFrame, "TOP");
		top = 0 + panelYOffset;
		TitanMovableFrame_CheckTopFrame(frameTop, top, TicketStatusFrame:GetName())
		end

		-- Move TemporaryEnchantFrame
		if (TemporaryEnchantFrame) then
		frameTop = TitanMovableFrame_GetOffset(TemporaryEnchantFrame, "TOP");
		if (TitanMovable_IsShown(TicketStatusFrame)) then
			top = 0 - TicketStatusFrame:GetHeight() + panelYOffset;
		else
			top = -13 + panelYOffset;
		end
		TitanMovableFrame_CheckTopFrame(frameTop, top, TemporaryEnchantFrame:GetName())
		end
	
		-- Move MinimapCluster
		if (not CleanMinimap and MinimapCluster) then
		frameTop = TitanMovableFrame_GetOffset(MinimapCluster, "TOP");
		top = 0 + panelYOffset; 		
		TitanMovableFrame_CheckTopFrame(frameTop, top, MinimapCluster:GetName())
		end
		
		-- Move WorldStateAlwaysUpFrame
		if (WorldStateAlwaysUpFrame) then
		frameTop = TitanMovableFrame_GetOffset(WorldStateAlwaysUpFrame, "TOP");
		top = -15 + panelYOffset; 		
		TitanMovableFrame_CheckTopFrame(frameTop, top, WorldStateAlwaysUpFrame:GetName());
		end

	elseif (position == TITAN_PANEL_PLACE_BOTTOM) then

		panelYOffset = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars"));
		
		-- Move MainMenuBar
		if (not Gypsy_ActionBar and not BibActionBar1 and MainMenuBar) then
			bottom = 0 + panelYOffset; 
			frameBottom = TitanMovableFrame_GetOffset(MainMenuBar, "BOTTOM");
			if (frameBottom >= 0) then
				TitanMovableFrame_CheckBottomFrame(frameBottom, bottom, MainMenuBar:GetName());
			end
		end
	
		-- Move MultiBarRight
		if (MultiBarRight) then
		bottom = 98 + panelYOffset; 
		frameBottom = TitanMovableFrame_GetOffset(MultiBarRight, "BOTTOM");
		TitanMovableFrame_CheckBottomFrame(frameBottom, bottom, MultiBarRight:GetName());
		end
	end	

end

function TitanMovableFrame_MoveFrames(position, override)	
	local frameData, frame, frameName, frameArchor, xArchor, y, xOffset, yOffset, panelYOffset;
	
	for index, value in TitanMovable do
		frameData = TitanMovableData[value];
		frame = getglobal(frameData.frameName);
		frameName = frameData.frameName;
		frameArchor = frameData.frameArchor;

		if (frame and frame.IsUserPlaced and not frame:IsUserPlaced()) then
			xArchor = frameData.xArchor;
			y = frameData.y;
			
			panelYOffset = TitanMovable_GetPanelYOffset(frameData.position, TitanPanelGetVar("BothBars"), override);
	
			xOffset = TitanMovableFrame_GetOffset(frame, xArchor);		
			if (frameName == "TemporaryEnchantFrame" and TitanMovable_IsShown(TicketStatusFrame)) then
				yOffset = (-TicketStatusFrame:GetHeight()) + panelYOffset;
			else
				yOffset = y + panelYOffset;	
			end
			
			frame:ClearAllPoints();		
			frame:SetPoint(frameArchor, "UIParent", frameArchor, xOffset, yOffset);
		else
			--Leave frame where it is as it has been moved by a user
		end
	end
end

function TitanMovableFrame_AdjustBlizzardFrames()
	Titan_FCF_UpdateDockPosition();
	Titan_FCF_UpdateCombatLogPosition();
	if TitanPanelGetVar("CastingBar") then
		Titan_CastingBarFrame_UpdatePosition();
	end
	Titan_UIParent_ManageRightSideFrames();
end

function TitanMovableFrame_GetOffset(frame, point)
	if (frame and point) then
		if (point == "LEFT" and frame:GetLeft() and UIParent:GetLeft()) then
			return frame:GetLeft() - UIParent:GetLeft();
		elseif (point == "RIGHT" and frame:GetRight() and UIParent:GetRight()) then
			return frame:GetRight() - UIParent:GetRight();			
		elseif (point == "TOP" and frame:GetTop() and UIParent:GetTop()) then
			return frame:GetTop() - UIParent:GetTop();
		elseif (point == "BOTTOM" and frame:GetBottom() and UIParent:GetBottom()) then
			return frame:GetBottom() - UIParent:GetBottom();
		elseif (point == "CENTER" and frame:GetLeft() and frame:GetRight() and UIParent:GetLeft() and UIParent:GetRight()) then
			return (frame:GetLeft() + frame:GetRight() - UIParent:GetLeft() - UIParent:GetRight()) / 2;
		end
	end	
	return 0;
end

function TitanMovable_GetPanelYOffset(framePosition, bothbars, override)
	local barPosition = TitanPanelGetVar("Position");
	local barnumber = 0;

	if override then
		if framePosition == TITAN_PANEL_PLACE_TOP then
			if TitanPanelGetVar("ScreenAdjust") then
				return 0;
			end
		elseif framePosition == TITAN_PANEL_PLACE_BOTTOM and bothbars == nil then
			if TitanPanelGetVar("ScreenAdjust") then
				return 0;
			end
		elseif framePosition == TITAN_PANEL_PLACE_BOTTOM and bothbars == 1 then
			if TitanPanelGetVar("AuxScreenAdjust") then
				return 0;
			end
		else
			return 0;
		end
	end
	
	if bothbars ~= nil then
		barPosition = framePosition;
	else
		barPosition = TitanPanelGetVar("Position");
	end
	
	barnumber = TitanUtils_GetDoubleBar(bothbars, framePosition);
	
	local scale = TitanPanelGetVar("Scale");
	if (scale and framePosition and barPosition and framePosition == barPosition) then
		if (framePosition == TITAN_PANEL_PLACE_TOP) then
			return (-24 * scale)*(barnumber);
		elseif (framePosition == TITAN_PANEL_PLACE_BOTTOM) then
			return (24 * scale)*(barnumber);
		end
	end
	return 0;
end

function TitanMovableFrame_CheckTopFrame(frameTop, top, frameName)
--	if (frameTop + 1 >= top) then
--TitanDebug(frameTop .." - " .. top);
		table.insert(TitanMovable, frameName);
--	end
end

function TitanMovableFrame_CheckBottomFrame(frameBottom, bottom, frameName)
--	if (frameBottom - 1 <= bottom) then
		table.insert(TitanMovable, frameName);
--	end
end

function Titan_TicketStatusFrame_OnEvent()
	local panelYOffset = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_TOP, TitanPanelGetVar("BothBars"));
	
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		GetGMTicket();
	else
		if ( arg1 ~= 0 ) then		
			this:Show();
			TitanMovable_SetPoint(TemporaryEnchantFrame, "TOPRIGHT", this:GetParent():GetName(), "TOPRIGHT", -205, 0 - this:GetHeight() + panelYOffset); -- ATTN
			refreshTime = GMTICKET_CHECK_INTERVAL;
		else
			this:Hide();
			TitanMovable_SetPoint(TemporaryEnchantFrame, "TOPRIGHT", "UIParent", "TOPRIGHT", -205, -13 + panelYOffset); -- ATTN
		end
	end	
end

function Titan_FCF_UpdateDockPosition()
	local panelYOffset = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars"));

	if ( not DEFAULT_CHAT_FRAME ) then
		return;
	end
	if ( DEFAULT_CHAT_FRAME.IsUserPlaced and DEFAULT_CHAT_FRAME:IsUserPlaced() ) then
		if ( SIMPLE_CHAT ~= "1" ) then
			return;
		end
	end
	
	local chatOffset = 85 + panelYOffset;
	if ( GetNumShapeshiftForms() > 0 or HasPetUI() or PetHasActionBar() ) then
		if ( TitanMovable_IsShown(MultiBarBottomLeft) or BOTTOMBAR_OFFSET_Y ) then
			chatOffset = chatOffset + 55;
		else
			chatOffset = chatOffset + 15;
		end
	elseif ( TitanMovable_IsShown(MultiBarBottomLeft) or BOTTOMBAR_OFFSET_Y ) then
		chatOffset = chatOffset + 15;
	end
	TitanMovable_SetPoint(DEFAULT_CHAT_FRAME, "BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 32, chatOffset);
	if ( FCF_DockUpdate ) then
		FCF_DockUpdate();
	end
end

function Titan_FCF_UpdateCombatLogPosition()
	local panelYOffset = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars"));

	if ( SIMPLE_CHAT == "1" ) then
		local xOffset = -32;
		local yOffset = 75 + panelYOffset;
		if ( TitanMovable_IsShown(MultiBarBottomRight) ) then
			yOffset = yOffset + 40;
		end
		if ( TitanMovable_IsShown(MultiBarLeft) ) then
			xOffset = xOffset - 88;
		elseif ( TitanMovable_IsShown(MultiBarRight) ) then
			xOffset = xOffset - 43;
		end
		TitanMovable_SetPoint(ChatFrame2, "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", xOffset, yOffset);
	end
end

function Titan_CastingBarFrame_UpdatePosition()
	local panelYOffset = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars"));
	
	local castingBarPosition = 60 + panelYOffset;
	if ( TitanMovable_IsShown(PetActionBarFrame) or TitanMovable_IsShown(ShapeshiftBarFrame) ) then
		castingBarPosition = castingBarPosition + 40;
	end
	if ( TitanMovable_IsShown(MultiBarBottomLeft) or TitanMovable_IsShown(MultiBarBottomRight) ) then
		castingBarPosition = castingBarPosition + 40;
	end
	if ( CastingBarFlash ) then
		CastingBarFlash:ClearAllPoints();
		CastingBarFlash:SetPoint("BOTTOM", "UIParent", "BOTTOM", 0, castingBarPosition - 22);
	end
	if ( CastingBarText ) then
		CastingBarText:ClearAllPoints();
		CastingBarText:SetPoint("BOTTOM", "UIParent", "BOTTOM", 0, castingBarPosition);
	end
	if ( CastingBarFrameStatusBar ) then
		CastingBarFrameStatusBar:ClearAllPoints();
		CastingBarFrameStatusBar:SetPoint("BOTTOM", "UIParent", "BOTTOM", 0, castingBarPosition);
	end
	if ( CastingBarFrame ) then
		CastingBarFrame:ClearAllPoints();
		CastingBarFrame:SetPoint("BOTTOM", "UIParent", "BOTTOM", 0, castingBarPosition);
	end
end

function Titan_UIParent_ManageRightSideFrames()
	local panelYOffset = TitanMovable_GetPanelYOffset(TITAN_PANEL_PLACE_BOTTOM, TitanPanelGetVar("BothBars"));
	
	local anchorX = 0;
	local anchorY = 0 + panelYOffset;
	local bottomBars = TitanMovable_IsShown(MultiBarBottomRight) or TitanMovable_IsShown(MultiBarBottomLeft);

	-- Update group loot frame anchor
	if ( bottomBars ) then
		TitanMovable_SetPoint(GroupLootFrame1, "BOTTOM", "UIParent", "BOTTOM", 0, 102 + panelYOffset);
	else
		TitanMovable_SetPoint(GroupLootFrame1, "BOTTOM", "UIParent", "BOTTOM", 0, 60 + panelYOffset);
	end
	
	-- Update tutorial anchor
	-- [Keldurn fix] TutorialFrameParent / FramerateLabel may not exist in this client
	if ( bottomBars ) then
		TitanMovable_SetPoint(TutorialFrameParent, "BOTTOM", "UIParent", "BOTTOM", 0, 94 + panelYOffset);
		TitanMovable_SetPoint(FramerateLabel, "BOTTOM", "WorldFrame", "BOTTOM", 0, 104 + panelYOffset);
	else
		TitanMovable_SetPoint(TutorialFrameParent, "BOTTOM", "UIParent", "BOTTOM", 0, 52 + panelYOffset);
		TitanMovable_SetPoint(FramerateLabel, "BOTTOM", "WorldFrame", "BOTTOM", 0, 64 + panelYOffset);
	end
	
	-- Update bag anchor
	if ( TitanMovable_IsShown(MultiBarBottomRight) ) then
		CONTAINER_OFFSET_Y = 97 + panelYOffset;
	else
		CONTAINER_OFFSET_Y = 70 + panelYOffset;
	end
	-- Setup x anchor
	if ( TitanMovable_IsShown(MultiBarLeft) ) then
		CONTAINER_OFFSET_X = 90;
		anchorX = 90;
	elseif ( TitanMovable_IsShown(MultiBarRight) ) then
		CONTAINER_OFFSET_X = 45;
		anchorX = 45;
	else
		CONTAINER_OFFSET_X = 0;
		anchorX = 0;
	end
	-- Setup y anchors
	if ( MinimapCluster ) then
		TitanMovable_SetPoint(QuestTimerFrame, "TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -anchorX, anchorY);
		if ( TitanMovable_IsShown(QuestTimerFrame) ) then
			anchorY = anchorY - TitanMovable_Height(QuestTimerFrame);
		end
		TitanMovable_SetPoint(DurabilityFrame, "TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -anchorX-20, anchorY);
		if ( TitanMovable_IsShown(DurabilityFrame) ) then
			anchorY = anchorY - TitanMovable_Height(DurabilityFrame);
		end
		TitanMovable_SetPoint(QuestWatchFrame, "TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -anchorX, anchorY);
	end

	-- Update combat log anchor
	if ( FCF_UpdateCombatLogPosition ) then
		FCF_UpdateCombatLogPosition();
	end
end
