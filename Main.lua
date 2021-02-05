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
		EasyDestroyItemsScrollBar_Update(function() EasyDestroyButton:Enable() end)
	elseif event=="PLAYER_ENTERING_WORLD" and EasyDestroy.AddonLoaded then
		EasyDestroy.CurrentFilter=testfilter
		EasyDestroyItemsScrollBar_Update()
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		local who, _, what = ... 
		if who=="player" and what==13262 then
			EasyDestroy.Debug("Disenchant Interrupted")
			EasyDestroyButton:Enable()
		end
	elseif event == "UNIT_SPELLCAST_FAILED" then
		local who, _, what = ...
		if who=="player" and what==13262 then
			EasyDestroy.Debug("Failed to Disenchant item...")
			EasyDestroyButton:Enable()
		end
	elseif event=="PLAYER_REGEN_DISABLED" then
		EasyDestroyButton:Disable()
	elseif event=="PLAYER_REGEN_ENABLED" then
		EasyDestroyButton:Enable()
	elseif event=="ADDON_LOADED" then
		local name = ...
		if name == EasyDestroy.AddonName then
			EasyDestroy.AddonLoaded = true
			EasyDestroy:Initialize()
			EasyDestroyFilters:SetupWindow()

			if EasyDestroyData then 
				EasyDestroy.Data = EasyDestroyData
				EasyDestroy.DataLoaded = true
			else
				EasyDestroy.Data = {}
				EasyDestroy.DataLoaded = true
			end
			
			EasyDestroy.Data = EasyDestroy:UpdateDBFormat(EasyDestroy.Data)
			EasyDestroy.Data.Filters = EasyDestroy.Data.Filters or {}
			EasyDestroy.Data.Options = EasyDestroy.Data.Options or {}
			EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter

			UIDropDownMenu_Initialize(EasyDestroyDropDown, EasyDestroy_InitDropDown)
			
			if GetTableSize(EasyDestroy.Data.Filters)>0 then
				for k, filterObj in pairs(EasyDestroy.Data.Filters) do
					if filterObj.properties.favorite then
						UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, k)
						EasyDestroy_LoadFilter(k)
						EasyDestroy_Refresh()
					end
				end
			else
				UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
			end

		end
	elseif event=="PLAYER_LOGOUT" then
		if EasyDestroy.DataLoaded then
			EasyDestroyData = EasyDestroy.Data
		end
	end
end

function EasyDestroy_OnUpdate(self, delay)
	if EasyDestroy.FilterChanged then 
		EasyDestroy.CurrentFilter = EasyDestroy:GenerateFilter()
		EasyDestroyItemsScrollBar_Update()
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

EasyDestroyFrameSearchTypes.Search:SetScript("OnClick", EasyDestroySearchTypes_OnClick)
EasyDestroyFrameSearchTypes.Blacklist:SetScript("OnClick", EasyDestroySearchTypes_OnClick)

EasyDestroy_OpenFilters:SetScript("OnClick", EasyDestroy_ToggleFilters)
EasyDestroyFilters_Save:SetScript("OnClick", function() EasyDestroyFilters.SaveFilter() end)
-- EasyDestroyFilters_Delete:SetScript("OnClick", EasyDestroyFilters_DeleteFilter)
EasyDestroyFilters_Delete:SetScript("OnClick", function() StaticPopup_Show("ED_CONFIRM_DELETE_FILTER", EasyDestroyFilters:GetFilterName()) end)
EasyDestroyFilters_NewFromFilter:SetScript("OnClick", EasyDestroyFilters_CreateNewFromCurrent)
EasyDestroyFilters_New:SetScript("OnClick", function() 
	EasyDestroy_ClearFilterFrame() 
	EasyDestroy_InitDropDown()
	EasyDestroy_ResetFilterStack()
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0) 
	if EasyDestroy:IncludeBlacklists() and not EasyDestroy:IncludeSearches() then
		EasyDestroyFrameSearchTypes.Blacklist:SetChecked(true)
	end
	EasyDestroy_Refresh() end
)


