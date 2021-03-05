EasyDestroy.UI.Filters = {}
local FiltersFrame = EasyDestroy.UI.Filters
FiltersFrame.name = "EasyDestroy.UI.Filters"

local initialized = false
local protected  = {}

-- Filter Selection (saved filters)
FiltersFrame.FilterDropDown = EasyDestroyDropDown
FiltersFrame.FilterDropDown.SearchesCheckbutton = EasyDestroyFrameSearch.Types.Search
FiltersFrame.FilterDropDown.BlacklistsCheckbutton = EasyDestroyFrameSearch.Types.Blacklist

-- Filter Editing (CRUD)
FiltersFrame.FilterName = EasyDestroyFilterSettings.FilterName
FiltersFrame.Favorite = EasyDestroyFilterSettings.Favorite
FiltersFrame.FilterType = EasyDestroyFilterSettings.Blacklist
FiltersFrame.CriteriaDropdown = EasyDestroyFilterTypes
FiltersFrame.CriteriaWindow = EasyDestroySelectedFilters

FiltersFrame.Buttons = {}
FiltersFrame.Buttons.NewFilter = EasyDestroyFilters_New
FiltersFrame.Buttons.SaveFilterAs = EasyDestroyFilters_NewFromFilter
FiltersFrame.Buttons.DeleteFilter = EasyDestroyFilters_Delete
FiltersFrame.Buttons.SaveFilter = EasyDestroyFilters_Save

function FiltersFrame.__init()

    if initialized then return end 

    EasyDestroy:RegisterCallback("FiltersUpdated", FiltersFrame.Initialize_FilterDropDown)

	FiltersFrame.FilterDropDown.SearchesCheckbutton:SetScript("OnClick", protected.FilterTypesOnClick)
	FiltersFrame.FilterDropDown.BlacklistsCheckbutton:SetScript("OnClick", protected.FilterTypesOnClick)

	FiltersFrame.Buttons.NewFilter:SetScript("OnClick", protected.NewOnClick)
	FiltersFrame.Buttons.SaveFilterAs:SetScript("OnClick", protected.SaveFilterAsOnClick)
	FiltersFrame.Buttons.DeleteFilter:SetScript("OnClick", function() StaticPopup_Show("ED_CONFIRM_DELETE_FILTER", EasyDestroy.UI.GetFilterName()) end)
	FiltersFrame.Buttons.SaveFilter:SetScript("OnClick", protected.SaveFilterOnClick)
    
    initialized = true

end

function FiltersFrame.Initialize_FilterDropDown()

    EasyDestroy.Debug(FiltersFrame.name, "Initialize_FilterDropDown")

    local info = UIDropDownMenu_CreateInfo()
	local favoriteID = nil
	info.text, info.value, info.checked, info.func, info.owner = EasyDestroy.Dict.Strings.FilterSelectionDropdownNew, 0, false, protected.FilterDropDownOnSelect, FiltersFrame.FilterDropDown
	UIDropDownMenu_AddButton(info)
	local hasSeparator = false
	local includeSearches, includeBlacklists = FiltersFrame.IncludeSearches(), FiltersFrame.IncludeBlacklists()

	-- This monstrosity sorts by type=type and name<name or type<type
	-- e.g. if types match, sort by name, otherwise sort by type
	if EasyDestroy.Data.Filters then
		for fid, filter in EasyDestroy.spairs(EasyDestroy.Data.Filters, function(t, a, b) return (t[a].properties.type == t[b].properties.type and t[a].properties.name:lower() < t[b].properties.name:lower()) or t[a].properties.type < t[b].properties.type end) do
			info.text, info.value, info.checked, info.func, info.owner = filter.properties.name, fid, false, protected.FilterDropDownOnSelect, FiltersFrame.FilterDropDown

			if EasyDestroy.Cache.FilterCache and not EasyDestroy.Cache.FilterCache[fid] then
				EasyDestroy.Cache.FilterCache[fid] = EasyDestroyFilter:Load(fid)
			end
			
			if EasyDestroy.DebugActive then
				info.text = filter.properties.name .. " | " .. fid
			end

			if filter.properties.type == ED_FILTER_TYPE_SEARCH and includeSearches then
				UIDropDownMenu_AddButton(info)
				if filter.properties.favorite == true then
					favoriteID = info.value
				end
			elseif filter.properties.type == ED_FILTER_TYPE_BLACKLIST and includeBlacklists then
				if not hasSeparator and includeSearches then
					UIDropDownMenu_AddButton(EasyDestroy.separatorInfo)
					hasSeparator = true
				end
				UIDropDownMenu_AddButton(info)
			end
		end
	end

end

FiltersFrame.Update_FilterDropDown = FiltersFrame.Initialize_FilterDropDown

function FiltersFrame.Initialize_CriteriaDropDown()

    --EasyDestroyFilters.InitializeFilterTypesDropDown()

	local info = UIDropDownMenu_CreateInfo()
	local filterRegistry = EasyDestroy.CriteriaRegistry

	info.text, info.value, info.func, info.owner, info.isTitle, info.notCheckable = 
	EasyDestroy.Dict.Strings.CriteriaSelectionDropdown, 0, nil, FiltersFrame.CriteriaDropdown, true, true

	UIDropDownMenu_AddButton(info)

	--refresh info w/o any of the above settings, not sure why disabled is getting set, may be a function of isTitle or notCheckable.
	info.isTitle, info.notCheckable, info.disabled = false, false, false

	for k, v in pairs(filterRegistry) do
		info.text, info.value, info.checked, info.func, info.owner, info.keepShownOnClick =
		v.name, v.key, v:IsShown(), protected.CriteriaDropDownOnSelect, FiltersFrame.CriteriaDropdown, true
		UIDropDownMenu_AddButton(info)
	end

	UIDropDownMenu_SetText( FiltersFrame.CriteriaDropdown, EasyDestroy.Dict.Strings.CriteriaSelectionDropdown)

end

function FiltersFrame.GetSelectedFilter()

    return UIDropDownMenu_GetSelectedValue(FiltersFrame.FilterDropDown)

end

function FiltersFrame.SetSelectedFilter(val)

    UIDropDownMenu_SetSelectedValue(FiltersFrame.FilterDropDown, val)

end

function FiltersFrame.SelectAllFilterTypes()

	FiltersFrame.FilterDropDown.BlacklistsCheckbutton:SetChecked(true)
	FiltersFrame.FilterDropDown.SearchesCheckbutton:SetChecked(true)
	
end

function FiltersFrame.UpdateFilterDropDownWidth()

    -- Could probably map this to the OnSizeChanged widget handler for the EasyDestroyFrame

    UIDropDownMenu_SetWidth(FiltersFrame.FilterDropDown, FiltersFrame.FilterDropDown:GetWidth()-40)

end

function FiltersFrame.IncludeBlacklists()

	return FiltersFrame.FilterDropDown.BlacklistsCheckbutton:GetChecked()

end

function FiltersFrame.IncludeSearches()

	return FiltersFrame.FilterDropDown.SearchesCheckbutton:GetChecked()

end

function FiltersFrame.GetFilterName()

	return FiltersFrame.FilterName:GetText()

end

function FiltersFrame.SetFilterName(filtername)
	if filtername == nil or type(filtername) ~= "string" then 
        error("Usage: EasyDestroy.UI.SetFilterName(filtername).", 2)
    else
        FiltersFrame.FilterName:SetText(filtername)
	end
end

function FiltersFrame.GetFavoriteChecked()
    
    return FiltersFrame.Favorite:GetChecked()

end

function FiltersFrame.SetFavoriteChecked(bool)
    
    return FiltersFrame.Favorite:SetChecked(bool)

end

function FiltersFrame.GetFilterType()

    if FiltersFrame.FilterType:GetChecked() then
        return ED_FILTER_TYPE_BLACKLIST
    end
    
    return ED_FILTER_TYPE_SEARCH

end

function FiltersFrame.GetFilterProperties(filter)

    return FiltersFrame.GetFilterName(), FiltersFrame.GetFilterType(), FiltersFrame.GetFavoriteChecked()

end

function FiltersFrame.ResetCriteriaWindow()

    -- Clears and hides all criteria in the registry and resets the criteria stack.

    EasyDestroy.Debug(FiltersFrame.name, "ResetCriteriaWindow")

	for k,v in pairs(EasyDestroy.CriteriaRegistry) do
		v:Clear()
		if v.frame then
			v.frame:Hide()
		end
	end

	wipe(EasyDestroy.CriteriaStack)

end

function FiltersFrame.PlaceCriteria()

    -- Places the currently selected criteria in the criteria window
    -- Handles placing them in order

    EasyDestroy.Debug(FiltersFrame.name, "PlaceCriteria")

	local lastFrame = nil
	local scrollFrame = _G[EDFILTER_SCROLL_CHILD]
	for k, v in ipairs(EasyDestroy.CriteriaStack) do
		local frame = v:GetFilterFrame()
		frame:ClearAllPoints()

		if lastFrame == nil then
			lastFrame = scrollFrame
			frame:SetPoint("TOPLEFT", lastFrame, 0, -4)
		else
			frame:SetPoint("TOP", lastFrame, "BOTTOM", 0, -4)
		end

		frame:SetPoint("LEFT", scrollFrame, 4, 0)
		frame:SetPoint("RIGHT", scrollFrame, -4, 0)

		frame:SetHeight(v.height)
		frame:Show()
		lastFrame = frame
	end

end

function FiltersFrame.GetCriteria()
	
	-- gather up all the criteria currently selected by the user and their values
	
    local out = {}

    for i, registeredFilter in ipairs(EasyDestroy.CriteriaStack) do
		local val = registeredFilter:GetValues()
		if val ~= nil then 
			out[registeredFilter:GetKey()] = val
		end
	end

    return out

end

-- EasyDestroy_ClearFilterFrame
function FiltersFrame.ClearFilterSettings()

    -- Clears the "settings" for the filter

    EasyDestroy.Debug(FiltersFrame.name, "ClearFilterSettings")

    FiltersFrame.SetFilterName("")
	FiltersFrame.Favorite:SetChecked(false)
	FiltersFrame.FilterType:SetChecked(false)

end

function FiltersFrame.Clear()

    -- Clears both the settings and criteria from the UI.

    EasyDestroy.Debug(FiltersFrame.name, "Clear")
    
    FiltersFrame.ClearFilterSettings()
    FiltersFrame.ResetCriteriaWindow()

end

function FiltersFrame.LoadFilter(fid)
	FiltersFrame.Clear()

	EasyDestroy.Debug("EasyDestroy.UI.LoadFilter", "Loading Filter", fid)

	local filter = EasyDestroyFilter:Load(fid)

    FiltersFrame.SetFilterName(filter:GetName())

	if EasyDestroy.Favorites.UsingCharacterFavorites() then
		local fav = EasyDestroy.Favorites.GetFavorite()
		if fav and fav ~= nil and fav == fid then
			if filter:GetType() ~= ED_FILTER_TYPE_BLACKLIST then
				FiltersFrame.Favorite:SetChecked(true)
			else
				-- if a player tries to load a filter that's a blacklist and they have previously
				-- marked it as a favorite, then we're going to unset that (sorry, not sorry).
					EasyDestroy.Favorites.UnsetFavorite()
			end
		end
	else
		FiltersFrame.Favorite:SetChecked(filter:GetFavorite())
	end
	
	if filter:GetType() == ED_FILTER_TYPE_BLACKLIST then
		FiltersFrame.FilterType:SetChecked(true)
		FiltersFrame.Favorite:Disable()
	else
		FiltersFrame.FilterType:SetChecked(false)
		FiltersFrame.Favorite:Enable()
	end

	for key, registeredFilter in pairs(EasyDestroy.CriteriaRegistry) do
		registeredFilter:Clear()
		if filter:GetCriterionByKey(key) ~= nil then
			tinsert(EasyDestroy.CriteriaStack, registeredFilter)
			registeredFilter:SetValues(filter:GetCriterionByKey(key) or "")
		end
	end

	FiltersFrame.PlaceCriteria()

end

-- EasyDestroy.Reload
function FiltersFrame.ReloadFilter(filterID)

    -- For reloading after a filter has been saved

    EasyDestroy.Debug(FiltersFrame.name, "ReloadFilter")

	FiltersFrame.LoadFilter(filterID)
	FiltersFrame.Update_FilterDropDown()

	EasyDestroy.FilterChanged = true
	--UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
    FiltersFrame.SetSelectedFilter(filterID)

    local filterNameUpdate = FiltersFrame.GetFilterName()
    if EasyDestroy.DebugActive then
        filterNameUpdate = filterNameUpdate .. " | " .. filterID
    end

    -- because if you change the name, the system doesn't seem to know how to handle
    -- updating the menu text without you opening the menu, changing to another option
    -- and then changing back.

    UIDropDownMenu_SetText(FiltersFrame.FilterDropDown, filterNameUpdate)

end

function FiltersFrame.ReloadCurrentFilter()

	local fid = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)

	if fid and fid ~= 0 then 

		FiltersFrame.ReloadFilter(fid)

	end

end

function FiltersFrame.FilterValidation(filter)

	local filterName = FiltersFrame.GetFilterName()
    local favChecked = FiltersFrame.GetFavoriteChecked()

    local favoriteFid = EasyDestroy.Favorites.GetFavorite()
	local nameFid = EasyDestroy.API.Filters.FindFilterWithName(filterName)

    if nameFid and nameFid ~= filter.filterID then
		return false, ED_ERROR_NAME, filterName
    elseif favoriteFid and favoriteFid ~= nil and EasyDestroy.Favorites.UsingCharacterFavorites() and not skipFavoriteCheck then
		if favoriteFid ~= filter.filterID and favChecked then
			return false, ED_ERROR_FAVORITE
		end
	--elseif favoriteFid and favoriteFid ~= nil and self:GetFavorite() and not skipFavoriteCheck then
    elseif favoriteFid and favoriteFid ~= nil and filter:GetFavorite() and not skipFavoriteCheck then
		EasyDestroy.Debug(favoriteFid, filter.filterID, "Checking for filter id match.")
		if favoriteFid ~= filter.filterID and favChecked then
			return false, ED_ERROR_FAVORITE
		end
	end

    return true, ED_ERROR_NONE, ''

end



-- #####################################
--[[ UI Event Handlers ]]
-- #####################################

function protected.FilterTypesOnClick()

    EasyDestroy.Debug(FiltersFrame.name, "FilterTypesOnClick")

	FiltersFrame.Initialize_FilterDropDown()
	local favoriteID = EasyDestroy.Favorites.GetFavorite()

	if not(FiltersFrame:IncludeSearches()) and not(FiltersFrame:IncludeBlacklists()) then
		UIDropDownMenu_SetText(EasyDestroyDropDown, 'You must select at least one type of filter.')
	elseif FiltersFrame:IncludeSearches() and favoriteID then
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, favoriteID)
		EasyDestroy.UI.LoadFilter(favoriteID)
		EasyDestroy_Refresh()
	else
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
	end

end

function protected.FilterDropDownOnSelect(self, arg1, arg2, checked)

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

function protected.CriteriaDropDownOnSelect(self, arg1, arg2, checked)

    -- Handler for EasyDestroy.UI.CriteriaDropdown

	local selectedValue = self.value
	local selectedFilter = EasyDestroy.CriteriaRegistry[selectedValue]
	UIDropDownMenu_SetText(FiltersFrame.CriteriaDropdown, EasyDestroy.Dict.Strings.CriteriaSelectionDropdown)

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

function protected.NewOnClick()

	-- Handler for EasyDestroy.UI.Buttons.NewFilter

	FiltersFrame.Clear()

	FiltersFrame.Initialize_FilterDropDown()

	EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter

	UIDropDownMenu_SetSelectedValue(FiltersFrame.FilterDropDown, 0) 

	if FiltersFrame:IncludeBlacklists() and not FiltersFrame:IncludeSearches() then
		FiltersFrame.FilterDropDown.SearchesCheckbutton:SetChecked(true)
	end
	
	EasyDestroy.FilterChanged = true
	
end

function protected.SaveFilterOnClick(skipFavoriteCheck)
	
    -- Handler for EasyDestroy.UI.Buttons.SaveFilter

    EasyDestroy.Debug(FiltersFrame.name, "SaveFilterOnClick")

	local FilterID = FiltersFrame.GetSelectedFilter()
	
	local filter = EasyDestroy:GenerateFilter()

	local valid, validationErrorType, validationMessage = FiltersFrame.FilterValidation(filter)

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
function protected.SaveFilterAsOnClick()

    -- Handler for EasyDestroy.UI.Buttons.NewFilterFromCurrent

    EasyDestroy.Debug("EasyDestroy.Handlers.CopyFilterOnClick")

	local CurrentFilterID = UIDropDownMenu_GetSelectedValue(FiltersFrame.FilterDropDown)
	local filter, ftype

	local filter = EasyDestroyFilter:New(EasyDestroy.UI.GetFilterType(), EasyDestroy.UI.GetFilterName())
	filter:SetFavorite(false)
	local valid, validationErrorType, validationMessage = FiltersFrame.FilterValidation(filter)

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
function protected.DeleteFilterOnClick()

    -- Handler for EasyDestroy.UI.Buttons.DeleteFilter

    EasyDestroy.Debug("EasyDestroy.Handlers.DeleteFilterOnClick")

	--[[ Delete current filter. Load user's favorite filter if one is available. ]]
	local FilterID = UIDropDownMenu_GetSelectedValue(FiltersFrame.FilterDropDown)
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
		UIDropDownMenu_SetSelectedValue(FiltersFrame.FilterDropDown, favoriteID)
		EasyDestroy.UI.LoadFilter(favoriteID)
	else
		UIDropDownMenu_SetSelectedValue(FiltersFrame.FilterDropDown, 0)
		EasyDestroy.UI.ClearFilter()
	end

	EasyDestroy.FilterChanged = true

end

