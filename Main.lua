EasyDestroy = EasyDestroy
local testfilter = {filter={quality={3}, id=161984}, properties={name="TEST"}}

--[[ This file is the file to initialize the addon, will call relevant functions from other files,
register events, set scripts on buttons and handle the loading and saving/unloading of data. Will
call this file last so that everything else should be set up and ready to be started.]]--

EasyDestroyFrame:RegisterEvent("ADDON_LOADED")
EasyDestroyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EasyDestroyFrame:RegisterEvent("PLAYER_LOGOUT")
EasyDestroyFrame:RegisterEvent("PLAYER_LOGIN")
EasyDestroyFrame:RegisterEvent("BAG_UPDATE_DELAYED")
EasyDestroyFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
EasyDestroyFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
EasyDestroyFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
EasyDestroyFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
EasyDestroyFrame:RegisterEvent("PLAYER_STARTED_MOVING")
EasyDestroyFrame:RegisterEvent("PLAYER_STOPPED_MOVING")

--[[ 
Note1: Considering looking at events to handle the enable/disable of the disenchant button
Need to look at registering LOOT_OPENED, LOOT_CLOSED, UNIT_SPELLCAST_START, UNIT_SPELLCAST_STOP, UNIT_SPELLCAST_SUCCEEDED
Disable on UNIT_SPELLCAST_START
Reenable on LOOT_CLOSED, UNIT_SPELLCAST_STOP, or after 2 seconds.

Currently this is just done with a timer. I know that the fast loot addons can cause some issues and so
I think for now that is what I will stick with.  May come down to registering events or hitting a
timer cap (2s) to reenable the Disenchant button.

Note2: As a thought, might look into allowing the user to set a bag limit so that if for any reason they
have less than X bag slots they won't disenchant. 
]]--

function EasyDestroy_EventHandler(self, event, ...)
	if event == "BAG_UPDATE_DELAYED" and EasyDestroy.AddonLoaded and EasyDestroyFrame:IsVisible() then 
		-- Originally reenabled the button via a timer, however by doing it as a callback this makes it so
		-- that we don't have to worry about it ever somehow being re-enabled before the bags and
		-- item list have been properly processed.
		-- EasyDestroyItemsScrollBar_Update(function() EasyDestroyButton:Enable() end)
		EasyDestroyItemsFrame.UpdateItemList = true
		EasyDestroyItemsFrame:ScrollUpdate(function() EasyDestroyButton:Enable() end)
		EasyDestroyFrame_FoundItemsCount:SetText(EasyDestroyItemsFrame.ItemCount ..  " Item(s) Found")
	elseif event=="PLAYER_ENTERING_WORLD" and EasyDestroy.AddonLoaded then
		EasyDestroy.CurrentFilter=testfilter
		-- EasyDestroyItemsScrollBar_Update()
		EasyDestroyItemsFrame:ScrollUpdate()
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		local who, _, what = ... 
		if who=="player" and what==13262 and not EasyDestroy.PlayerMoving then
			EasyDestroy.Debug("Disenchant Interrupted")
			EasyDestroyButton:Enable()
		end
	elseif event == "UNIT_SPELLCAST_FAILED" then
		local who, _, what = ...
		if who=="player" and what==13262 and not EasyDestroy.PlayerMoving then
			EasyDestroy.Debug("Failed to Disenchant item...")
			EasyDestroyButton:Enable()
		end
	elseif event=="PLAYER_REGEN_DISABLED" then
		EasyDestroyButton:Disable()
	elseif event=="PLAYER_REGEN_ENABLED" and not EasyDestroy.PlayerMoving then
		EasyDestroyButton:Enable()
	elseif event=="PLAYER_STARTED_MOVING" then
		EasyDestroy.PlayerMoving = true
		EasyDestroyButton:Disable()
	elseif event=="PLAYER_STOPPED_MOVING" then
		EasyDestroy.PlayerMoving = false
		EasyDestroyButton:Enable()
	elseif event=="ADDON_LOADED" then
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

			EasyDestroy.Data = EasyDestroy:UpdateDBFormat(EasyDestroy.Data)
			
			EasyDestroy.Data.Filters = EasyDestroy.Data.Filters or {}
			EasyDestroy.Data.Options = EasyDestroy.Data.Options or {}
			EasyDestroy.Data.Blacklist = EasyDestroy.Data.Blacklist or {}
			EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter

			UIDropDownMenu_Initialize(EasyDestroyDropDown, EasyDestroy.UI.FilterDropDown.Initialize)
			
			local fav = EasyDestroy.Favorites.GetFavorite()
			if fav ~= nil then
				UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, fav)
				EasyDestroy.UI.LoadFilter(fav)
				EasyDestroy_Refresh()
			else
				UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
			end

			local showConfig = EasyDestroy_GetOptionValue("ConfiguratorShown")
			if showConfig ~= nil then
				EasyDestroyConfiguration:SetShown(showConfig)
			end

		end
	elseif event=="PLAYER_LOGOUT" then
		if EasyDestroy.DataLoaded then
			EasyDestroyData = EasyDestroy.Data
			EasyDestroyCharacter = EasyDestroy.CharacterData
		end
	end
end

function EasyDestroy_OnUpdate(self, delay)
	if EasyDestroy.FilterChanged then 
		EasyDestroy.UpdateSkin = true
		EasyDestroy.CurrentFilter = EasyDestroy:GenerateFilter()
		EasyDestroyItemsFrame.UpdateItemList = true
		EasyDestroyItemsFrame:ScrollUpdate()
		EasyDestroyFrame_FoundItemsCount:SetText(EasyDestroyItemsFrame.ItemCount ..  " Item(s) Found")
		EasyDestroy.FilterChanged = false
	end
end

SLASH_OPENUI1 = "/edestroy";
SLASH_OPENUI2 = "/ed";
SLASH_OPENUI3 = "/easydestroy"

function SlashCmdList.OPENUI(msg)
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

EasyDestroyFrame:SetScript("OnShow", function()
	EasyDestroyFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	EasyDestroy_Refresh() -- This will force the search to repopulate on load
end)

EasyDestroyFrame:SetScript("OnHide", function()
	EasyDestroyFrame:UnregisterEvent("BAG_UPDATE_DELAYED")
	collectgarbage()
end)


EasyDestroyFrame:SetScript("OnEvent", EasyDestroy_EventHandler)
EasyDestroyFrame:SetScript("OnUpdate", EasyDestroy_OnUpdate)

EasyDestroyButton:SetScript("PreClick", function(self)
	EasyDestroy:DisenchantItem()
	end
)
EasyDestroyButton:SetScript("PostClick", function(self)
	EasyDestroyButton:SetAttribute("macrotext", "")
	end
)

EasyDestroyFrameSearchTypes.Search:SetScript("OnClick", EasyDestroy.Handlers.FilterTypesOnClick)
EasyDestroyFrameSearchTypes.Blacklist:SetScript("OnClick", EasyDestroy.Handlers.FilterTypesOnClick)

EasyDestroyFilters_Save:SetScript("OnClick", function() EasyDestroy.Handlers.SaveFilterOnClick() end)
EasyDestroyFilters_Delete:SetScript("OnClick", function() StaticPopup_Show("ED_CONFIRM_DELETE_FILTER", EasyDestroy.UI.GetFilterName()) end)
EasyDestroyFilters_NewFromFilter:SetScript("OnClick", EasyDestroy.Handlers.CopyFilterOnClick)
EasyDestroyFilters_New:SetScript("OnClick", function() 
	EasyDestroy.UI.ClearFilter()
	EasyDestroy.UI.FilterDropDown.Update()
	EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0) 
	if EasyDestroy:IncludeBlacklists() and not EasyDestroy:IncludeSearches() then
		EasyDestroyFrameSearchTypes.Search:SetChecked(true)
	end
	EasyDestroy_Refresh() end
)

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
