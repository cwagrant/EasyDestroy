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
		EasyDestroy.ClearItems();
		EasyDestroy:PopulateSearch(EasyDestroy.CurrentFilter);
	elseif event=="PLAYER_ENTERING_WORLD" and EasyDestroy.AddonLoaded then
		EasyDestroy:PopulateSearch(testfilter)
	elseif event=="ADDON_LOADED" then
		local name = ...
		if name == EasyDestroy.AddonName then
			EasyDestroy.AddonLoaded = true
			EasyDestroy:Initialize()	

			if EasyDestroyData then 
				EasyDestroy.Data = EasyDestroyData
				EasyDestroy.DataLoaded = true
				EasyDestroy.Data.Filters = EasyDestroy.Data.Filters or {}
		
				EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
				UIDropDownMenu_Initialize(EasyDestroyDropDown, EasyDestroy_InitDropDown)
				
				for k, filterObj in pairs(EasyDestroy.Data.Filters) do
					if filterObj.properties.favorite then
						UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, k)
						EasyDestroy_LoadFilter(k)
						EasyDestroy.FilterChanged = true
					end
				end
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
		EasyDestroy:ClearItems()
		EasyDestroy:PopulateSearch(EasyDestroy.CurrentFilter)
		EasyDestroy.FilterChanged = false
	end
end

function EasyDestroy_DropDownSelect(self, arg1, arg2, checked)
	EasyDestroy.Debug("SetSelectedValue", self.value)
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, self.value)
	if self.value == 0 then
		EasyDestroy_ClearFilterFrame()
		EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
	else
		EasyDestroy_LoadFilter(self.value)
		EasyDestroy.CurrentFilter = EasyDestroy.Data.Filters[self.value]
	end
	EasyDestroy.FilterChanged = true
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
EasyDestroyNameSearch.input:SetScript("OnEditFocusLost", function() EasyDestroy.FilterChanged = true end)
EasyDestroyNameSearch.input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

EasyDestroyItemID.input:SetScript("OnEditFocusLost", function() EasyDestroy.FilterChanged = true end)
EasyDestroyItemID.input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

EasyDestroyRarityCommon:SetScript("OnClick", function() EasyDestroy.FilterChanged = true end)
EasyDestroyRarityUncommon:SetScript("OnClick", function() EasyDestroy.FilterChanged = true end)
EasyDestroyRarityRare:SetScript("OnClick", function() EasyDestroy.FilterChanged = true end)
EasyDestroyRarityEpic:SetScript("OnClick", function() EasyDestroy.FilterChanged = true end)

EasyDestroyButton:SetScript("PreClick", function(self)
	EasyDestroy:DisenchantItem()
	end
)
EasyDestroyButton:SetScript("PostClick", function(self)
	EasyDestroyButton:SetAttribute("macrotext", "")
	end
)

EasyDestroySave:SetScript("OnClick", EasyDestroy_SaveFilter)
EasyDestroyDelete:SetScript("OnClick", EasyDestroy_DeleteFilter)

