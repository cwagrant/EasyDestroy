--[[
	This will kick everything off
	Register and handle Blizz events
	Initialize/Load/Save data structure
	Send up Dialog/Alert for  updates
	Setup slash commands

]]

EasyDestroy = EasyDestroy

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

local protected = {}

protected.PlayerMoving = false
protected.DataLoaded = false

function EasyDestroy_EventHandler(self, event, ...)
	if event == "BAG_UPDATE_DELAYED" and EasyDestroy.AddonLoaded and EasyDestroyFrame:IsVisible() then 


		-- if we're restacking items, then we don't want this to trigger multiple updates
		if EasyDestroy.Inventory.RestackInProgress() then return end 

		EasyDestroy.Events:Call("ED_INVENTORY_UPDATED")


	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then 

		local subevent = {CombatLogGetCurrentEventInfo()}
		local playerGUID = UnitGUID("player")

		if subevent[4] == playerGUID and tContains(EasyDestroy.Dict.ActionTable, subevent[12]) and EasyDestroy.ButtonWasClicked then 


			if subevent[2] == "SPELL_CAST_FAILED" and subevent[15] == SPELL_FAILED_CANT_BE_DISENCHANTED or subevent[15] == SPELL_FAILED_CANT_BE_MILLED or subevent[15] == SPELL_FAILED_CANT_BE_PROSPECTED then

				if EasyDestroy.Data.Options.AutoBlacklist then

					if EasyDestroy.UI.GetCurrentItem() then 
						EasyDestroy.Blacklist.AddItem(EasyDestroy.UI.GetCurrentItem())
					end

				end
				EasyDestroy.ButtonWasClicked = false
				EasyDestroyButton:Enable()
			
			elseif subevent[2] == "SPELL_CAST_FAILED" and subevent[15] == INTERRUPTED then

				EasyDestroy.ButtonWasClicked = false

				if not protected.PlayerMoving then 
					EasyDestroyButton:Enable()
				end

			elseif subevent[2] == "SPELL_CAST_SUCCESS" then

				EasyDestroy.ButtonWasClicked = false

			end

		end	

	elseif event=="PLAYER_REGEN_DISABLED" then

		-- Disable the button in combat 

		EasyDestroyButton:Disable()

	elseif event=="PLAYER_REGEN_ENABLED" and not protected.PlayerMoving then

		-- Enable the button out of combat

		EasyDestroyButton:Enable()

	elseif event=="PLAYER_STARTED_MOVING" then

		-- Disable button while player is moving
		protected.PlayerMoving = true
		EasyDestroyButton:Disable()

	elseif event=="PLAYER_STOPPED_MOVING" then

		-- Reenable button when player stops moving

		protected.PlayerMoving = false
		EasyDestroyButton:Enable()

	elseif event=="ADDON_LOADED" then

		-- This is the big kahuna. This handles all the startup for the addon.

		local name = ...
		if name == EasyDestroy.AddonName then
			EasyDestroy.AddonLoaded = true
			-- EasyDestroyFrame.__init()

			if EasyDestroyData then 
				EasyDestroy.Data = EasyDestroyData
				protected.DataLoaded = true
			else
				EasyDestroy.Data = {}
				protected.DataLoaded = true
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
			
			EasyDestroy.Data.Options.Actions = EasyDestroy.Data.Options.Actions or EasyDestroy.Enum.Actions.Disenchant

			if EasyDestroy.Data.Options.CharacterFavorites == nil then 
				EasyDestroy.Data.Options.CharacterFavorites = false
			end
			-- "Post"-Initialization functions that need to occur once data has been loaded
			EasyDestroyFrame.__init()
			EasyDestroy.UI.ItemWindow.__init()
			EasyDestroy.UI.Filters.__init()
			EasyDestroy.UI.Options.__init()
			EasyDestroy.UI.Blacklist.__init()

			-- update users inventory on login
			EasyDestroy.Events:Call("ED_INVENTORY_UPDATED")

			local showConfig = EasyDestroy.Data.Options.ConfiguratorShown or false
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
			EasyDestroy.MinimapIcon = ldbicon


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

		if protected.DataLoaded then
			EasyDestroyData = EasyDestroy.Data
			EasyDestroyCharacter = EasyDestroy.CharacterData
		end

	end

end

function EasyDestroy_OnUpdate(self, delay)

	-- At this point this serves just as a way to run the item stacking coroutine

	if EasyDestroy.Thread and coroutine.status(EasyDestroy.Thread) ~= "dead" then
		coroutine.resume(EasyDestroy.Thread)
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
		local _, b = strsplit(" ", msg)
		if b == "true" or b == "on" then
			EasyDestroy.Data.Options.CharacterFavorites = true
			print("Character Favorites turned on.")
		elseif b == "false" or b == "false" then 
			EasyDestroy.Data.Options.CharacterFavorites = false
			print("Character Favorites turned off.")
		else
			print("Unrecognized setting: " .. b)
		end
	elseif msg=="debug" and EasyDestroy.DebugActive then
		EasyDestroy:ShowDebugFrame()
	elseif msg=="opt" or msg=="option" or msg=="options" then 
		InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
    	InterfaceOptionsFrame_OpenToCategory("EasyDestroy")
	elseif msg=="dump" then
		ImportExportDialog(false, EasyDestroy:Dump())
	else
		if EasyDestroyFrame:IsVisible() then
			EasyDestroyFrame:Hide()
		else
			EasyDestroyFrame:Show()
		end
	end
end


-- 'turn on' the event handlers
EasyDestroyFrame:SetScript("OnEvent", EasyDestroy_EventHandler)
EasyDestroyFrame:SetScript("OnUpdate", EasyDestroy_OnUpdate)


EasyDestroy.Events:Fire("ED_ADDON_LOADED")





