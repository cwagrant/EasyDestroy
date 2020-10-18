EasyDestroy = EasyDestroy

local testfilter = {filter={quality={3}, id=161984}, properties={name="TEST"}}


EasyDestroyFrame:RegisterEvent("ADDON_LOADED")
EasyDestroyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
EasyDestroyFrame:RegisterEvent("PLAYER_LOGOUT")
EasyDestroyFrame:RegisterEvent("PLAYER_LOGIN")
EasyDestroyFrame:RegisterEvent("BAG_UPDATE_DELAYED")

--[[ 
Need to look at registering LOOT_OPENED, LOOT_CLOSED, UNIT_SPELLCAST_START, UNIT_SPELLCAST_STOP, UNIT_SPELLCAST_SUCCEEDED

Disable on UNIT_SPELLCAST_START
Reenable on LOOT_CLOSED, UNIT_SPELLCAST_STOP, or after 2 seconds.
]]--

function EasyDestroy_EventHandler(self, event, ...)
	if event == "BAG_UPDATE_DELAYED" and EasyDestroy.AddonLoaded and EasyDestroyFrame:IsVisible() then 
		EasyDestroyItemsScrollBar_Update()
	elseif event=="PLAYER_ENTERING_WORLD" and EasyDestroy.AddonLoaded then
		EasyDestroy.CurrentFilter=testfilter
		EasyDestroyItemsScrollBar_Update()
	elseif event=="ADDON_LOADED" then
		local name = ...
		if name == EasyDestroy.AddonName then
			EasyDestroy.AddonLoaded = true
			EasyDestroy:Initialize()
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
	
			EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
			UIDropDownMenu_Initialize(EasyDestroyDropDown, EasyDestroy_InitDropDown)
			
			if EasyDestroy.Data.Filters and table.getn(EasyDestroy.Data.Filters)>0 then
				for k, filterObj in pairs(EasyDestroy.Data.Filters) do
					if filterObj.properties.favorite then
						UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, k)
						EasyDestroy_LoadFilter(k)
						EasyDestroy.FilterChanged = true
					end
				end
			else
				UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
				--UIDropDownMenu_Initialize(EasyDestroyDestroyType, EasyDestroy_InitFilterDestroySpells)
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
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0) 
	EasyDestroy.FilterChanged = true end
)

