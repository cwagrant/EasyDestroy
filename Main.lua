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
EasyDestroyFrame:RegisterEvent("ITEM_PUSH")
EasyDestroyFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

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
		EasyDestroyItemsScrollBar_Update()
	elseif event=="PLAYER_ENTERING_WORLD" and EasyDestroy.AddonLoaded then
		EasyDestroy.CurrentFilter=testfilter
		EasyDestroyItemsScrollBar_Update()
	elseif event == "ITEM_PUSH" then
		-- seems to be safe to reenable after this event fires
		-- at least a fraction of a second after the event fires, that is...
		C_Timer.After(0.2, function()
			EasyDestroyButton:Enable()
		end
		)
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		if select(1, ...) == "player" then
			EasyDestroyButton:Enable()
		end
	elseif event=="ADDON_LOADED" then
		local name = ...
		if name == EasyDestroy.AddonName then
			EasyDestroy.AddonLoaded = true
			EasyDestroy:Initialize()
			EasyDestroy:InitFilters()
			EasyDestroy.RegisterFilters()

			if EasyDestroyData then 
				EasyDestroy.Data = EasyDestroyData
				EasyDestroy.DataLoaded = true
			else
				EasyDestroy.Data = {}
				EasyDestroy.DataLoaded = true
			end
			EasyDestroy.Data.Filters = EasyDestroy.Data.Filters or {}
			EasyDestroy.Data.Options = EasyDestroy.Data.Options or {}
			EasyDestroy.Test = {}
			EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
			UIDropDownMenu_Initialize(EasyDestroyDropDown, EasyDestroy_InitDropDown)
			if GetTableSize(EasyDestroy.Data.Filters)>0 then
				tinsert(EasyDestroy.Test, "Loaded filters, count > 0")
				for k, filterObj in pairs(EasyDestroy.Data.Filters) do
					if filterObj.properties.favorite then
						UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, k)
						EasyDestroy_LoadFilter(k)
						EasyDestroy.FilterChanged = true
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

function EasyDestroy_DropDownSelect(self, arg1, arg2, checked)
	EasyDestroy.Debug("SetSelectedValue", self.value)
	EasyDestroy.FilterSaveWarned = false
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, self.value)
	if self.value == 0 then
		EasyDestroy_ClearFilterFrame()
		EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
	else
		EasyDestroy_LoadFilter(self.value)
		EasyDestroy.CurrentFilter = EasyDestroy.Data.Filters[self.value]
		EasyDestroy.CurrentFilter.fid = self.value
	end
	EasyDestroy.FilterChanged = true
end

function EasyDestroy_DestroySpellSelect(self, arg1, arg2, checked)
	EasyDestroy.Debug("SetSelectedValue", self.value)
	UIDropDownMenu_SetSelectedValue(EasyDestroyDestroyType, self.value)
end

SLASH_OPENUI1 = "/edestroy";
SLASH_OPENUI2 = "/ed";
SLASH_OPENUI3 = "/easydestroy"

function SlashCmdList.OPENUI(msg)
	if msg=="reset" then
		-- reset position to center of screen
		EasyDestroyFrame:SetPoint("RIGHT", UIParent, "CENTER", 0, 0)
	elseif msg=="macro" then
		CreateMacro("ED_Disenchant", 236557, "/click EasyDestroyButton", nil)
	else
		if EasyDestroyFrame:IsVisible() then
			EasyDestroyFrame:Hide()
		else
			EasyDestroyFrame:Show()
		end
	end
end

EasyDestroyFrame:SetScript("OnShow", function()
	EasyDestroyFrame:RegisterEvent("BAG_UPDATE_DELAYED")
	EasyDestroy.FilterChanged = true -- This will force the search to repopulate on load
end)

EasyDestroyFrame:SetScript("OnHide", function()
	EasyDestroyFrame:UnregisterEvent("BAG_UPDATE_DELAYED")
end)


EasyDestroyFrame:SetScript("OnEvent", EasyDestroy_EventHandler)
EasyDestroyFrame:SetScript("OnUpdate", EasyDestroy_OnUpdate)

EasyDestroyFilters_ItemName.input:SetScript("OnEditFocusLost", function() EasyDestroy.FilterChanged = true end)
EasyDestroyFilters_ItemID.input:SetScript("OnEditFocusLost", function() EasyDestroy.FilterChanged = true end)
EasyDestroyFilters_ItemLevel.inputfrom:SetScript("OnEditFocusLost", function() EasyDestroy.FilterChanged = true end)
EasyDestroyFilters_ItemLevel.inputto:SetScript("OnEditFocusLost", function() EasyDestroy.FilterChanged = true end)

EasyDestroyFilters_RarityCommon:SetScript("OnClick", function() EasyDestroy.FilterChanged = true end)
EasyDestroyFilters_RarityUncommon:SetScript("OnClick", function() EasyDestroy.FilterChanged = true end)
EasyDestroyFilters_RarityRare:SetScript("OnClick", function() EasyDestroy.FilterChanged = true end)
EasyDestroyFilters_RarityEpic:SetScript("OnClick", function() EasyDestroy.FilterChanged = true end)

EasyDestroyButton:SetScript("PreClick", function(self)
	EasyDestroy:DisenchantItem()
	end
)
EasyDestroyButton:SetScript("PostClick", function(self)
	EasyDestroyButton:SetAttribute("macrotext", "")
	end
)

EasyDestroy_OpenFilters:SetScript("OnClick", EasyDestroy_ToggleFilters)
EasyDestroyFilters_Save:SetScript("OnClick", EasyDestroyFilters_SaveFilter)
EasyDestroyFilters_Delete:SetScript("OnClick", EasyDestroyFilters_DeleteFilter)
EasyDestroyFilters_NewFromFilter:SetScript("OnClick", EasyDestroyFilters_CreateNewFromCurrent)
EasyDestroyFilters_New:SetScript("OnClick", function() 
	EasyDestroy_ClearFilterFrame() 
	EasyDestroy_InitDropDown()
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0) 
	EasyDestroy.FilterChanged = true end
)

