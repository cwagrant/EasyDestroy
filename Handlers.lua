--[[

    This file will cover the functions that are used by the various buttons, boxes, and other
    interface pieces that a user might interact with.

]]
-- EasyDestroy_DropDownSelect
function EasyDestroy.Handlers.FilterDropDownOnSelect(self, arg1, arg2, checked)

    -- Handler for EasyDestroy.UI.FilterDropDown selections

    EasyDestroy.Debug("EasyDestroy.Handlers.FilterDropDownOnSelect", self.value)

	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, self.value)
	if self.value == 0 then
		EasyDestroy.UI.ClearFilter()
		EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
	else
		EasyDestroy.UI.LoadFilter(self.value)
		EasyDestroy.CurrentFilter = EasyDestroy.Data.Filters[self.value]
		EasyDestroy.CurrentFilter.fid = self.value
	end
	EasyDestroy_Refresh()

end

-- EasyDestroySearchTypes_OnClick
function EasyDestroy.Handlers.FilterTypesOnClick()

    EasyDestroy.Debug("EasyDestroy.Handlers.FilterTypesOnClick")

	EasyDestroy.UI.FilterDropDown.Initialize()
	local favoriteID = EasyDestroy.Favorites.GetFavorite()

	if not(EasyDestroy:IncludeSearches()) and not(EasyDestroy:IncludeBlacklists()) then
		UIDropDownMenu_SetText(EasyDestroyDropDown, 'You must select at least one type of filter.')
	elseif EasyDestroy:IncludeSearches() and favoriteID then
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, favoriteID)
		EasyDestroy.UI.LoadFilter(favoriteID)
		EasyDestroy_Refresh()
	else
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
	end

end

--EasyDestroyFilters_SaveFilter
function EasyDestroy.Handlers.SaveFilterOnClick(skipFavoriteCheck)
	
    -- Handler for EasyDestroy.UI.Buttons.SaveFilter

    EasyDestroy.Debug("EasyDestroy.Handlers.SaveFilterOnClick")

	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
	
	local filter = EasyDestroy:GenerateFilter()

	local valid, validationErrorType, validationMessage = filter:Validate()

	-- if error and error is not type name and we haven't already warned them, warn the user
	if not valid and validationErrorType == ED_ERROR_NAME then
		StaticPopup_Show("ED_FILTER_UNIQUE_NAME", validationMessage)
		EasyDestroy.Debug("Name must be unique")
		return
	
	-- if error and error is a favorite error, warn the user
	elseif not valid and validationErrorType == ED_ERROR_FAVORITE and not skipFavoriteCheck then
		StaticPopup_Show("ED_CONFIRM_NEW_FAVORITE")
		return

	-- if error and error is type favorite and we have alredy warned them OR it is valid, then we save the filter
	elseif (not valid and validationErrorType == ED_ERROR_FAVORITE) or valid then

        filter:SetProperties(EasyDestroy.UI.GetFilterProperties())
        -- EasyDestroy.UpdateFilterProperties(filter)
		EasyDestroy.Debug("Saving filter")
		if EasyDestroy.DebugActive then
			pprint(filter)
		end
		if validationErrorType == ED_ERROR_FAVORITE then
			EasyDestroy.Favorites.UnsetFavorite()
			filter:SetFavorite(true)
		end
		filter:SaveToData()

        EasyDestroy.UI.ReloadFilter(filter.filterID)


	else
		print("EasyDestroy: UNKNOWN ERROR when saving Filter " .. filter.properties.name)
	end

end

-- EasyDestroyFilters_CreateNewFromCurrent
function EasyDestroy.Handlers.CopyFilterOnClick()

    -- Handler for EasyDestroy.UI.Buttons.NewFilterFromCurrent

    EasyDestroy.Debug("EasyDestroy.Handlers.CopyFilterOnClick")

	local CurrentFilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
	local filter, ftype

	local filter = EasyDestroyFilter:New(EasyDestroy.UI.GetFilterType(), EasyDestroy.UI.GetFilterName())
	filter:SetFavorite(false)
	local valid, validationErrorType, validationMessage = filter:Validate()

	-- if not valid because name is in use, print error
	if not valid and validationErrorType == ED_ERROR_NAME then
		StaticPopup_Show("ED_FILTER_RENAME", validationMessage)
		EasyDestroy.Debug("Name must be unique")

	-- if not valid because the current filter is the favorite OR if valid, save
	elseif (not valid and validationErrorType == ED_ERROR_FAVORITE) or valid then
		filter:SaveToData()

	else
		print("UNKNOWN ERROR when saving Filter " .. filter.properties.name)
	end

end

-- EasyDestroyFilters_DeleteFilter
function EasyDestroy.Handlers.DeleteFilterOnClick()

    -- Handler for EasyDestroy.UI.Buttons.DeleteFilter

    EasyDestroy.Debug("EasyDestroy.Handlers.DeleteFilterOnClick")

	--[[ Delete current filter. Load user's favorite filter if one is available. ]]
	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
	EasyDestroy.Debug("Deleting Filter", FilterID)
	EasyDestroy.Data.Filters[FilterID] = nil

	-- when deleting a filter, we need to make sure to clear it from the cache.
	if EasyDestroy.Cache.FilterCache and EasyDestroy.Cache.FilterCache[FilterID] then
		EasyDestroy.Cache.FilterCache[FilterID] = nil
	end

	EasyDestroy.UI.FilterDropDown.Update()

	local favoriteID =  EasyDestroy.Favorites.GetFavorite()

	if EasyDestroy.Favorites.UsingCharacterFavorites() and favoriteID == FilterID then
		EasyDestroy.Favorites.ClearUserFavorite()
		favoriteID = nil
	end

	if favoriteID ~= nil then
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, favoriteID)
		EasyDestroy.UI.LoadFilter(favoriteID)
	else
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
		EasyDestroy.UI.ClearFilter()
	end

	EasyDestroy.FilterChanged = true

end

-- EasyDestroyFilters.SelectFilterTypes
function EasyDestroy.Handlers.CriteriaDropDownOnSelect(self, arg1, arg2, checked)

    -- Handler for EasyDestroy.UI.CriteriaDropdown

	local selectedValue = self.value
	local selectedFilter = EasyDestroy.CriteriaRegistry[selectedValue]
	UIDropDownMenu_SetText(EasyDestroyFilterTypes, EasyDestroy.Dict.Strings.CriteriaSelectionDropdown)

	if checked then 
		local frame = selectedFilter:GetFilterFrame()
		local lastFrame = nil
		local scrollFrame = _G[EDFILTER_SCROLL_CHILD]
		if EasyDestroy.CriteriaStack[#EasyDestroy.CriteriaStack] and EasyDestroy.CriteriaStack[#EasyDestroy.CriteriaStack].frame then
			lastFrame = EasyDestroy.CriteriaStack[#EasyDestroy.CriteriaStack].frame
		else
			lastFrame = nil 
		end
		frame:ClearAllPoints()
		frame:SetPoint("LEFT", scrollFrame, 4, 0)
		frame:SetPoint("RIGHT", scrollFrame, -4, 0)

		if lastFrame == nil then 
			lastFrame = scrollFrame
			frame:SetPoint("TOPLEFT", scrollFrame)
		else
			frame:SetPoint("TOP", lastFrame, "BOTTOM")
		end

		frame:SetHeight(selectedFilter.height)
		frame:Show()
		tinsert(EasyDestroy.CriteriaStack, selectedFilter)
		lastFrame = frame
	else
		local frame = selectedFilter:GetFilterFrame()
		for k, v in ipairs(EasyDestroy.CriteriaStack) do
			if v.key == selectedFilter.key then
				v.frame:Hide()
				v:Clear()
				tremove(EasyDestroy.CriteriaStack, k)
			end
		end
	end
	EasyDestroy.UI.CriteriaWindow.PlaceCriteria()
	EasyDestroy_Refresh()
end

function EasyDestroy.Handlers.FilterTypeOnClick(self)


    --if EasyDestroyFilterSettings.Blacklist:GetChecked() and EasyDestroyFilterSettings.Favorite:GetChecked() then 
    if EasyDestroy.UI.GetFilterType() == ED_FILTER_TYPE_BLACKLIST and EasyDestroy.UI.GetFavoriteChecked() then
        StaticPopup_Show("ED_BLACKLIST_NO_FAVORITE") 
    end  

    if not EasyDestroy.IncludeBlacklists() or not EasyDestroy.IncludeSearches() then
        StaticPopup_Show("ED_SHOW_ALL_FILTERS")
    end

    if self:GetChecked() and EasyDestroy.UI.Favorite:IsEnabled() then
        EasyDestroy.UI.Favorite:Disable()
    elseif not self:GetChecked() and not EasyDestroyFilterSettings.Favorite:IsEnabled() then
        EasyDestroy.UI.Favorite:Enable()
    end

    EasyDestroy.FilterChanged = true

end 

function EasyDestroy.Handlers.DestroyPreClick(self)

	EasyDestroy.Debug("EasyDestroy.Handlers.DestroyPreClick")
	-- The actual process for disenchanting an item.
	if not EasyDestroyFrame:IsVisible() then
		EasyDestroyFrame:Show()
		return
	end

	local iteminfo = EasyDestroyItemsFrameItem1.item or nil
	local bag, slot
	
	if iteminfo ~= nil then
		bag, slot = iteminfo.bag, iteminfo.slot	
	else
		return 
	end

	local action = EasyDestroy.API.GetDestroyActionForItem(iteminfo)
	local actionDict = EasyDestroy.Dict.Actions[action]
	local spellName = GetSpellInfo(actionDict.spellID)
	
	if not IsSpellKnown(actionDict.spellID) then
		print ("EasyDestroy: You must have " .. GetSpellLink(actionDict.spellID) .. " to destroy this item.")
		return
	elseif EasyDestroyFilterSettings.Blacklist:GetChecked() then
		StaticPopup_Show("ED_CANT_DISENCHANT_BLACKLIST")
		return
	elseif not IsUsableSpell(actionDict.spellID) then
		print("EasyDestroy: You cannot destroy that item right now.")
		return
	elseif #GetLootInfo() > 0 then
		if not EasyDestroy.Warnings.LootOpen then
			print("EasyDestroy: Unable to destroy while loot window is open.")
				EasyDestroy.Warnings.LootOpen = true
			-- lets only warn people every so often, don't want to fill their chat logs if they spam click.
			C_Timer.After(30, function()
				EasyDestroy.Warnings.LootOpen = false
			end
			)
		end
		return
	elseif IsCurrentSpell(actionDict.spellID) then
		-- fail quietly as they are already casting
		return
	elseif iteminfo == nil then
		return
	end

	EasyDestroy.Debug("EasyDestroy.Handlers.DestroyPreClick", iteminfo.itemLink)
	EasyDestroy.API.DestroyItem(iteminfo)

end

function EasyDestroy.Handlers.OnCriteriaUpdate()


	EasyDestroy.FilterChanged = true

end