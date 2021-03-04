EasyDestroy = EasyDestroy
local testfilter = {filter={quality={3}, id=161984}, properties={name="TEST"}}

--[[ This file is the file to initialize the addon, will call relevant functions from other files,
register events, set scripts on buttons and handle the loading and saving/unloading of data. Will
call this file last so that everything else should be set up and ready to be started.]]--


EasyDestroyFrame:RegisterEvent("ADDON_LOADED")
-- EasyDestroyFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- not really needed it seems
EasyDestroyFrame:RegisterEvent("PLAYER_LOGOUT")
EasyDestroyFrame:RegisterEvent("PLAYER_LOGIN")
EasyDestroyFrame:RegisterEvent("BAG_UPDATE_DELAYED")
EasyDestroyFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
EasyDestroyFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EasyDestroyFrame:RegisterEvent("PLAYER_STARTED_MOVING")
EasyDestroyFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
EasyDestroyFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

function EasyDestroy_EventHandler(self, event, ...)
	if event == "BAG_UPDATE_DELAYED" and EasyDestroy.AddonLoaded and EasyDestroyFrame:IsVisible() then 


		if not EasyDestroy.ProcessingItemCombine then 

			-- As long as we're not the ones changing the users bags, lets upate our 
			-- windows and lists and make sure to reenable the button if it's disabled

			EasyDestroy.BagsUpdated = true 

			EasyDestroy.UI.ItemWindow.Update(function() EasyDestroyButton:Enable() end)


		end

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 

		local subevent = {CombatLogGetCurrentEventInfo()}
		local playerGUID = UnitGUID("player")

		if subevent[4] == playerGUID and tContains(EasyDestroy.Dict.ActionTable, subevent[12]) and EasyDestroy.ButtonWasClicked then 

			EasyDestroy.Debug("EventHandler", "Destroy Spell Cast")

			if subevent[2] == "SPELL_CAST_FAILED" and subevent[15] == SPELL_FAILED_CANT_BE_DISENCHANTED or subevent[15] == SPELL_FAILED_CANT_BE_MILLED or subevent[15] == SPELL_FAILED_CANT_BE_PROSPECTED then

				if EasyDestroy.Data.Options.AutoBlacklist then
					EasyDestroy.Debug("EventHandler", "Straight To Jail")
					if EasyDestroy.UI.GetCurrentItem() then 
						EasyDestroy.API.Blacklist.AddItem(EasyDestroy.UI.GetCurrentItem())
						EasyDestroy.UI.ItemWindow.Update()
					end
				end
				EasyDestroy.ButtonWasClicked = false
				EasyDestroyButton:Enable()
			
			elseif subevent[2] == "SPELL_CAST_FAILED" and subevent[15] == INTERRUPTED then

				EasyDestroy.Debug("EventHandler", "Cast Interrupted")
				EasyDestroy.ButtonWasClicked = false

				if not EasyDestroy.PlayerMoving then 
					EasyDestroyButton:Enable()
				end

			elseif subevent[2] == "SPELL_CAST_SUCCESS" then

				EasyDestroy.Debug("EventHandler", "Cast Succeeded")
				EasyDestroy.ButtonWasClicked = false

			end

		end	

	elseif event=="PLAYER_REGEN_DISABLED" then

		-- Disable the button in combat 

		EasyDestroyButton:Disable()

	elseif event=="PLAYER_REGEN_ENABLED" and not EasyDestroy.PlayerMoving then

		-- Enable the button out of combat

		EasyDestroyButton:Enable()

	elseif event=="PLAYER_STARTED_MOVING" then

		-- Disable button while player is moving
		EasyDestroy.PlayerMoving = true
		EasyDestroyButton:Disable()

	elseif event=="PLAYER_STOPPED_MOVING" then

		-- Reenable button when player stops moving

		EasyDestroy.PlayerMoving = false
		EasyDestroyButton:Enable()

	elseif event=="ADDON_LOADED" then

		-- This is the big kahuna. This handles all the startup for the addon.

		local name = ...
		if name == EasyDestroy.AddonName then
			EasyDestroy.AddonLoaded = true
			EasyDestroy.UI.Initialize()

			if EasyDestroyData then 
				EasyDestroy.Data = EasyDestroyData
				EasyDestroy.DataLoaded = true
			else
				EasyDestroy.Data = {}
				EasyDestroy.DataLoaded = true
			end

			if EasyDestroyCharacter then
				EasyDestroy.CharacterData = EasyDestroyCharacter
			else
				EasyDestroy.CharacterData = {}
			end

			-- Update DB Format if theres any changes

			EasyDestroy.Data = EasyDestroy:UpdateDBFormat(EasyDestroy.Data)
			
			-- Load or Initialize the DB structure

			EasyDestroy.Data.Filters = EasyDestroy.Data.Filters or {}
			EasyDestroy.Data.Options = EasyDestroy.Data.Options or {}
			EasyDestroy.Data.Options.MinimapIcon = EasyDestroy.Data.Options.MinimapIcon or {}
			EasyDestroy.Data.Blacklist = EasyDestroy.Data.Blacklist or {}
			EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter

			EasyDestroy.Data.Options.Actions = EasyDestroy.Data.Options.Actions or EasyDestroy.Enum.Actions.Disenchant

			if EasyDestroy.Data.Options.CharacterFavorites == nil then 
				EasyDestroy.Data.Options.CharacterFavorites = false
			end
			-- "Post"-Initialization functions that need to occur once data has been loaded

			UIDropDownMenu_Initialize(EasyDestroyDropDown, EasyDestroy.UI.FilterDropDown.Initialize)
			
			EasyDestroy.UI.LoadUserFavorite()

			EasyDestroy.BagsUpdated = true

			local showConfig = EasyDestroy_GetOptionValue("ConfiguratorShown")
			if showConfig ~= nil then
				EasyDestroyConfiguration:SetShown(showConfig)
			end

			local ldbicon = LibStub("LibDBIcon-1.0")
			local ldb = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("EasyDestroy", {
				type = "launcher",
				text = "EasyDestroy",
				icon = 132885,
				OnClick = function(self, button) 
					if button == "RightButton" then
						InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
    					InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
					elseif EasyDestroyFrame:IsVisible() then
						EasyDestroyFrame:Hide()
					else
						EasyDestroyFrame:Show()
					end
				end,
				OnLeave = function(self) GameTooltip:Hide() end,
				OnEnter = function(self)
					local x, y = GetCursorPosition()
					local width = GetScreenWidth() or 0
					local anchor = "ANCHOR_RIGHT"
					if x > (width/2) then anchor = "ANCHOR_LEFT" end
					GameTooltip:SetOwner(self, anchor)
					GameTooltip:ClearLines()
					GameTooltip:AddLine("EasyDestroy")
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("Left-click to |cFFE9C6F7Open.|r")
					GameTooltip:AddLine("Right-click for |cFFE9C6F7Options.|r")
					GameTooltip:Show()
				end

				})

			ldbicon:Register("EasyDestroy", ldb, EasyDestroy.Data.Options.MinimapIcon)

			-- If we haven't set up Alerts before, add them to database now.
			if not EasyDestroy.Data.Alerts then 

				EasyDestroy.Data.Alerts = 0x0000

			end

			-- New users don't get update alerts, previous users do.
			if EasyDestroy.FirstStartup then 

				-- This indicates this is not a new user going forward.
				EasyDestroy.Data.Alerts = bit.bor(EasyDestroy.Data.Alerts, 0x0001)

			else

				-- A little bit of future proofing, so we don't have an army of table entries
				-- we'll just use some bit flags. Only 1 field to concern ourselves with then.
				if bit.band(EasyDestroy.Data.Alerts, 0x0002) < 1 then 

					-- If it's not your first time and you haven't seen the alert, we're setting the indicator
					-- that you are not a first time user for going forward.

					if not EasyDestroy.FirstStartup and not (bit.band(EasyDestroy.Data.Alerts, 0x0001)>0) then
						EasyDestroy.Data.Alerts = bit.bor(EasyDestroy.Data.Alerts, 0x0001)
					end

					EasyDestroyFrame:HookScript("OnShow", function()

						-- If we already sent the alert this session, then do nothing.
						if bit.band(EasyDestroy.Data.Alerts, 0x0002) > 0 then return end

						StaticPopup_Show("ED_3_0_FEATURE_ALERT")
						EasyDestroy.Data.Alerts = bit.bor(EasyDestroy.Data.Alerts, 0x0002)

					end)

				end

			end

		end
	elseif event=="PLAYER_LOGOUT" then

		-- Save our data on logout

		if EasyDestroy.DataLoaded then
			EasyDestroyData = EasyDestroy.Data
			EasyDestroyCharacter = EasyDestroy.CharacterData
		end

	end

end

function EasyDestroy_OnUpdate(self, delay)

	-- If an action has been taken that modifies the current filter then we update the item window

	if EasyDestroy.Thread and coroutine.status(EasyDestroy.Thread) ~= "dead" then
		coroutine.resume(EasyDestroy.Thread)
	-- elseif #EasyDestroy.toCombineQueue > 0 then
	-- 	EasyDestroy.API.CombineItemsInQueue()
	end

	if EasyDestroy.FilterChanged then 

		-- This is only used when a user has AddOnSkins active.

		EasyDestroy.UpdateSkin = true

		-- clear the combine queue since we've changed the filter
		-- this makes sure the item doesn't get touched unless it will show up in the new/changed filter
		wipe(EasyDestroy.toCombineQueue) 

		EasyDestroy.UI.ItemWindow.Update()

		EasyDestroy.FilterChanged = false

		EasyDestroy.API.CombineItemsInQueue()

		-- EasyDestroy.Handlers.OnFilterUpdate()

	end

end

SLASH_EASYDESTROY1 = "/edestroy";
SLASH_EASYDESTROY2 = "/ed";
SLASH_EASYDESTROY3 = "/easydestroy"

function SlashCmdList.EASYDESTROY(msg)
	msg = string.lower(msg)
	if msg=="reposition" then
		-- reset position to center of screen
		EasyDestroyFrame:SetPoint("RIGHT", UIParent, "CENTER", 0, 0)
	elseif msg=="macro" then
		CreateMacro("ED_Disenchant", 236557, "/click EasyDestroyButton", nil)
	elseif msg=="reset" then
		EasyDestroyButton:Enable()
	elseif msg:find("characterfavorites ") or msg:find("cf ") then
		local a, b = strsplit(" ", msg)
		if b == "true" then
			EasyDestroy.Data.Options.CharacterFavorites = true
			print("Character Favorites turned on.")
		elseif b == "false" then 
			EasyDestroy.Data.Options.CharacterFavorites = false
			print("Character Favorites turned off.")
		else
			print("Unrecognized setting: " .. b)
		end
	elseif msg=="debug" and EasyDestroy.DebugActive then
		EasyDestroy.DebugFrame:GetParent():Show()
	elseif msg=="opt" or msg=="option" or msg=="options" then 
		InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
    	InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
	else
		if EasyDestroyFrame:IsVisible() then
			EasyDestroyFrame:Hide()
		else
			EasyDestroyFrame:Show()
		end
	end
end

-- Generally should just set EasyDestroy.FilterChanged = true to refresh the window with the most recent settings for the filter
function EasyDestroy_Refresh()
	EasyDestroy.FilterChanged = true
end

EasyDestroyFrame:SetScript("OnShow", EasyDestroy.Handlers.RegisterEvents)
EasyDestroyFrame:SetScript("OnHide", EasyDestroy.Handlers.UnregisterEvents)

EasyDestroyFrame:SetScript("OnEvent", EasyDestroy_EventHandler)
EasyDestroyFrame:SetScript("OnUpdate", EasyDestroy_OnUpdate)

EasyDestroyButton:SetScript("PreClick", EasyDestroy.Handlers.DestroyPreClick)
EasyDestroyButton:SetScript("PostClick", function(self)
	EasyDestroyButton:SetAttribute("macrotext", "")	
	EasyDestroy.ButtonWasClicked = true
end)

-- EasyDestroyButton:HookScript("OnClick", EasyDestroy.Handlers.DestroyPreClick)

EasyDestroyFrameSearchTypes.Search.Checkbutton:SetScript("OnClick", EasyDestroy.Handlers.FilterTypesOnClick)
EasyDestroyFrameSearchTypes.Blacklist.Checkbutton:SetScript("OnClick", EasyDestroy.Handlers.FilterTypesOnClick)

EasyDestroyFilters_Save:SetScript("OnClick", function() EasyDestroy.Handlers.SaveFilterOnClick() end)
EasyDestroyFilters_Delete:SetScript("OnClick", function() StaticPopup_Show("ED_CONFIRM_DELETE_FILTER", EasyDestroy.UI.GetFilterName()) end)
EasyDestroyFilters_NewFromFilter:SetScript("OnClick", EasyDestroy.Handlers.CopyFilterOnClick)
EasyDestroyFilters_New:SetScript("OnClick", EasyDestroy.Handlers.NewOnClick)

EasyDestroy_ToggleConfigurator:SetScript("OnClick", function() 
	if EasyDestroyConfiguration:IsVisible() then 
		EasyDestroyConfiguration:Hide() 
	else
		EasyDestroyConfiguration:Show()
	end
end)

EasyDestroyConfiguration:SetScript("OnHide", function()
	EasyDestroyFrame:SetSize(340, 380)
	EasyDestroy_ToggleConfigurator:SetText("Show Configurator")
	UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)
	EasyDestroy_ToggleConfigurator:ClearAllPoints()
	EasyDestroy_ToggleConfigurator:SetPoint("BOTTOMRIGHT", EasyDestroy_OpenBlacklist, "TOPRIGHT", 0, 10)
	EasyDestroy_SaveOptionValue("ConfiguratorShown", false)
end)

EasyDestroyConfiguration:SetScript("OnShow", function()
	EasyDestroyFrame:SetSize(580, 580)
	EasyDestroy_ToggleConfigurator:SetText("Hide Configurator")
	UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)
	EasyDestroy_ToggleConfigurator:ClearAllPoints()
	EasyDestroy_ToggleConfigurator:SetPoint("BOTTOMRIGHT", EasyDestroy_OpenBlacklist, "BOTTOMLEFT", -10, 0)
	EasyDestroy_SaveOptionValue("ConfiguratorShown", true)
end)

EasyDestroySelectedFiltersScroll:SetToplevel(true)

if EasyDestroy.DebugActive then
	EasyDestroy:CreateBG(EasyDestroyFrameSearch, 1, 0, 0)
	EasyDestroy:CreateBG(EasyDestroyConfiguration, 0, 1, 0)
end

EasyDestroyFilters_FavoriteIcon:SetScript("OnClick", EasyDestroy.Favorites.FavoriteIconOnClick)

EasyDestroyFilterSettings.Blacklist:SetScript("OnClick", EasyDestroy.Handlers.FilterTypeOnClick)


