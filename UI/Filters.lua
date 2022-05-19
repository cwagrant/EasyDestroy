EasyDestroy.UI.Filters = {}
local FiltersFrame = EasyDestroy.UI.Filters
FiltersFrame.name = "EasyDestroy.UI.Filters"

local initialized = false
local protected  = {}

-- Filter Selection (saved filters)
FiltersFrame.FilterDropDown = EasyDestroyDropDown
FiltersFrame.Blacklists = EasyDestroyFrame.FilterSelection.Types.Blacklist
FiltersFrame.Searches = EasyDestroyFrame.FilterSelection.Types.Search

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
FiltersFrame.Buttons.ExportFilter = EasyDestroyFilters_Export
FiltersFrame.Buttons.ImportFilter = EasyDestroyFilters_Import

function FiltersFrame.__init()

    if initialized then return end 

	StaticPopupDialogs["ED_CONFIRM_DELETE_FILTER"] = {
		text = "Are you sure you wish to delete filter %s?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = protected.DeleteFilterOnClick,
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ED_FILTER_RENAME"] = {
		text = "You must give this filter a unique name.",
		hasEditBox = true,
		button1 = "Rename",
		button2 = "Cancel",
		OnAccept = function(self) FiltersFrame.SetFilterName(self.editBox:GetText()); protected.SaveFilterAsOnClick(); end, 
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ED_CONFIRM_NEW_FAVORITE"] = {
		text = "You already have a favorite filter. Do you want to make this your new favorite filter?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self) protected.SaveFilterOnClick(true) end,
		OnCancel = function(self) FiltersFrame.Favorite:SetChecked(false) end,
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	UIDropDownMenu_Initialize(EasyDestroyDropDown, EasyDestroy.UI.Filters.Initialize_FilterDropDown)
	EasyDestroyFrame.LoadUserFavorite()

	UIDropDownMenu_Initialize(FiltersFrame.CriteriaDropdown, FiltersFrame.Initialize_CriteriaDropDown)

    EasyDestroy.RegisterCallback(FiltersFrame.FilterDropDown, "ED_FILTERS_AVAILABLE_CHANGED", FiltersFrame.Initialize_FilterDropDown)
	EasyDestroy.RegisterCallback(FiltersFrame.CriteriaDropdown, "ED_CRITERIA_AVAILABLE_CHANGED", FiltersFrame.Initialize_CriteriaDropDown)


	FiltersFrame.Searches.Checkbutton:SetScript("OnClick", protected.FilterTypesOnClick)
	FiltersFrame.Blacklists.Checkbutton:SetScript("OnClick", protected.FilterTypesOnClick)

	FiltersFrame.FilterType:SetScript("OnClick", protected.FilterTypeOnClick)

	FiltersFrame.Buttons.NewFilter:SetScript("OnClick", protected.NewOnClick)
	FiltersFrame.Buttons.SaveFilterAs:SetScript("OnClick", protected.SaveFilterAsOnClick)
	FiltersFrame.Buttons.DeleteFilter:SetScript("OnClick", function() 
		local dialog = StaticPopup_Show("ED_CONFIRM_DELETE_FILTER", FiltersFrame.GetFilterName()) 
		dialog.source = FiltersFrame
	end)
	FiltersFrame.Buttons.SaveFilter:SetScript("OnClick", protected.SaveFilterOnClick)
	FiltersFrame.Buttons.ExportFilter:SetScript("OnClick", protected.ExportFilterOnClick)
	FiltersFrame.Buttons.ImportFilter:SetScript("OnClick", protected.ImportFilterOnClick)

	FiltersFrame.Favorite:SetScript("OnClick", protected.FavoriteIconOnClick)

	-- I would think this belongs more with EasyDestroyFrame, but for whatever reason I'm too tired to
	-- figure at at the moment, it doesn't set the script when placed in that file...
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
		EasyDestroy.Data.Options.ConfiguratorShown = false
		
	end)
	
	EasyDestroyConfiguration:SetScript("OnShow", function()
		EasyDestroyFrame:SetSize(580, 580)
		EasyDestroy_ToggleConfigurator:SetText("Hide Configurator")
		UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)
		EasyDestroy_ToggleConfigurator:ClearAllPoints()
		EasyDestroy_ToggleConfigurator:SetPoint("BOTTOMRIGHT", EasyDestroy_OpenBlacklist, "BOTTOMLEFT", -10, 0)
		EasyDestroy.Data.Options.ConfiguratorShown = true
		
	end)

	EasyDestroySelectedFiltersScroll:SetToplevel(true)
    
    initialized = true

end

function FiltersFrame.Initialize_FilterDropDown()

    local info = UIDropDownMenu_CreateInfo()
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

	FiltersFrame.Blacklists:SetChecked(true)
	FiltersFrame.Searches:SetChecked(true)
	
end

function FiltersFrame.UpdateFilterDropDownWidth()

    -- Could probably map this to the OnSizeChanged widget handler for the EasyDestroyFrame

    UIDropDownMenu_SetWidth(FiltersFrame.FilterDropDown, FiltersFrame.FilterDropDown:GetWidth()-40)

end

function FiltersFrame.IncludeBlacklists()

	return FiltersFrame.Blacklists:GetChecked()

end

function FiltersFrame.IncludeSearches()

	return FiltersFrame.Searches:GetChecked()

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

    FiltersFrame.SetFilterName("")
	FiltersFrame.Favorite:SetChecked(false)
	FiltersFrame.FilterType:SetChecked(false)

end

function FiltersFrame.Clear()

    -- Clears both the settings and criteria from the UI.
    
    FiltersFrame.ClearFilterSettings()
    FiltersFrame.ResetCriteriaWindow()

	EasyDestroy.Events:Fire("ED_FILTER_CRITERIA_CHANGED")
end

function FiltersFrame.LoadFilter(fid)
	-- We're changing filters, so we'll clear the restack queue
	EasyDestroy.Inventory.ClearRestackQueue()
	FiltersFrame.Clear()

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

	EasyDestroy.Events:Call("ED_FILTER_LOADED", filter)

end

-- EasyDestroy.Reload
function FiltersFrame.ReloadFilter(filterID)

    -- For reloading after a filter has been saved

	FiltersFrame.LoadFilter(filterID)
	FiltersFrame.Update_FilterDropDown()

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
	local nameFid = EasyDestroy.Filters.FindFilterWithName(filterName)

    if nameFid and nameFid ~= filter.filterID then
		return false, ED_ERROR_NAME, filterName

    elseif favoriteFid and favoriteFid ~= nil and EasyDestroy.Favorites.UsingCharacterFavorites() then
		if favoriteFid ~= filter.filterID and favChecked then
			return false, ED_ERROR_FAVORITE
		end

    elseif favoriteFid and favoriteFid ~= nil and filter:GetFavorite() then
		if favoriteFid ~= filter.filterID and favChecked then
			return false, ED_ERROR_FAVORITE
		end
	end

    return true, ED_ERROR_NONE, ''

end

function FiltersFrame.GenerateFilter()

	--[[ This generates our filter table from settings in the EasyDestroyFilters window. ]]
	--[[ 2021-02-26 Removed old table, now uses a proper Filter object for downstream work.]]

	-- Needs to updated cached filters or create a brand new filter

	local FilterID = EasyDestroy.UI.Filters.GetSelectedFilter()
	local filter
	
	if EasyDestroy.Cache.FilterCache and EasyDestroy.Cache.FilterCache[FilterID] then
		filter = EasyDestroy.Cache.FilterCache[FilterID]
	else
		filter = EasyDestroyFilter:New(EasyDestroy.UI.Filters.GetFilterType(), EasyDestroy.UI.Filters.GetFilterName())
	end

	return filter
	
end

-- #####################################
-- [[ UI Event Handlers ]]
-- #####################################

--[[ If using Character Favorites, then clicking the icon will immediately set the favorite. ]]
	function protected.FavoriteIconOnClick()
		local existingFavorite = EasyDestroy.Favorites.GetFavorite()
		local currentFID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
		if existingFavorite and existingFavorite ~= nil and existingFavorite ~= currentFID then
			if EasyDestroy.Favorites.UsingCharacterFavorites() then
				StaticPopup_Show("ED_CONFIRM_NEW_CHARACTER_FAVORITE")
			end
		elseif existingFavorite == currentFID then
			if not EasyDestroyFilters_FavoriteIcon:GetChecked() and EasyDestroy.Favorites.UsingCharacterFavorites() then
				EasyDestroy.CharacterData.FavoriteID = nil
			end
		else
			if EasyDestroy.Favorites.UsingCharacterFavorites() then
				EasyDestroy.CharacterData.FavoriteID = currentFID
			end
		end
	end
	

function protected.FilterTypeOnClick(self)

    if FiltersFrame.GetFilterType() == ED_FILTER_TYPE_BLACKLIST and FiltersFrame.GetFavoriteChecked() then
        StaticPopup_Show("ED_BLACKLIST_NO_FAVORITE") 
    end  

    if not FiltersFrame:IncludeBlacklists() or not FiltersFrame:IncludeSearches() then
        StaticPopup_Show("ED_SHOW_ALL_FILTERS")
    end

    if self:GetChecked() and FiltersFrame.Favorite:IsEnabled() then
        FiltersFrame.Favorite:Disable()
    elseif not self:GetChecked() and not FiltersFrame.Favorite:IsEnabled() then
        FiltersFrame.Favorite:Enable()
    end

    EasyDestroy.Events:Fire("ED_FILTER_CRITERIA_CHANGED")

end 

function protected.FilterTypesOnClick()

	FiltersFrame.Initialize_FilterDropDown()
	local favoriteID = EasyDestroy.Favorites.GetFavorite()

	if not(FiltersFrame:IncludeSearches()) and not(FiltersFrame:IncludeBlacklists()) then
		UIDropDownMenu_SetText(EasyDestroyFrame.FilterSelection.DropDown, 'You must select at least one type of filter.')
		FiltersFrame.Clear()

	elseif FiltersFrame:IncludeSearches() and favoriteID then
		UIDropDownMenu_SetSelectedValue(EasyDestroyFrame.FilterSelection.DropDown, favoriteID)
		FiltersFrame.LoadFilter(favoriteID)
	
	else
		UIDropDownMenu_SetSelectedValue(EasyDestroyFrame.FilterSelection.DropDown, 0)

	end

	EasyDestroy.Events:Fire("ED_FILTERS_AVAILABLE_CHANGED")

end

function protected.FilterDropDownOnSelect(self, arg1, arg2, checked)

	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, self.value)
	if self.value == 0 then
		FiltersFrame.Clear()
	else
		FiltersFrame.LoadFilter(self.value)
	end

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
		
		for k, v in ipairs(EasyDestroy.CriteriaStack) do
			if v.key == selectedFilter.key then
				v.frame:Hide()
				v:Clear()
				tremove(EasyDestroy.CriteriaStack, k)
			end
		end
	end
	FiltersFrame.PlaceCriteria()
	
	EasyDestroy.Events:Fire("ED_FILTER_CRITERIA_CHANGED")
end

function protected.NewOnClick()

	-- Handler for EasyDestroy.UI.Buttons.NewFilter

	FiltersFrame.Clear()

	FiltersFrame.Initialize_FilterDropDown()

	UIDropDownMenu_SetSelectedValue(FiltersFrame.FilterDropDown, 0) 

	if FiltersFrame:IncludeBlacklists() and not FiltersFrame:IncludeSearches() then
		FiltersFrame.Searches:SetChecked(true)
	end
	
	EasyDestroy.Events:Fire("ED_FILTER_CRITERIA_CHANGED")
	
end

function protected.SaveFilterOnClick(skipFavoriteCheck)
	
    -- Handler for EasyDestroy.UI.Buttons.SaveFilter
	
	local filter = EasyDestroy.UI.Filters.GenerateFilter()

	local valid, validationErrorType, validationMessage = FiltersFrame.FilterValidation(filter)

	-- if error and error is not type name and we haven't already warned them, warn the user
	if not valid and validationErrorType == ED_ERROR_NAME then
		StaticPopup_Show("ED_FILTER_UNIQUE_NAME", validationMessage)
		return
	
	-- if error and error is a favorite error, warn the user
	elseif not valid and validationErrorType == ED_ERROR_FAVORITE and not skipFavoriteCheck then
		StaticPopup_Show("ED_CONFIRM_NEW_FAVORITE")
		return

	-- if error and error is type favorite and we have alredy warned them OR it is valid, then we save the filter
	elseif (not valid and validationErrorType == ED_ERROR_FAVORITE) or valid then

        filter:SetProperties(FiltersFrame.GetFilterProperties())
        -- EasyDestroy.UpdateFilterProperties(filter)

		if validationErrorType == ED_ERROR_FAVORITE then
			EasyDestroy.Favorites.UnsetFavorite()
			filter:SetFavorite(true)
		end

		filter:SetCriteria(FiltersFrame.GetCriteria())
		EasyDestroy.Filters.SaveFilter(filter)

        FiltersFrame.ReloadFilter(filter.filterID)


	else
		print("EasyDestroy: UNKNOWN ERROR when saving Filter " .. filter.properties.name)
	end

end

-- EasyDestroyFilters_CreateNewFromCurrent
function protected.SaveFilterAsOnClick()

    -- Handler for EasyDestroy.UI.Buttons.NewFilterFromCurrent

	local filter = EasyDestroyFilter:New(FiltersFrame.GetFilterType(), FiltersFrame.GetFilterName())
	filter:SetFavorite(false)
	local valid, validationErrorType, validationMessage = FiltersFrame.FilterValidation(filter)

	-- if not valid because name is in use, print error
	if not valid and validationErrorType == ED_ERROR_NAME then
		StaticPopup_Show("ED_FILTER_RENAME", validationMessage)

	-- if not valid because the current filter is the favorite OR if valid, save
	elseif (not valid and validationErrorType == ED_ERROR_FAVORITE) or valid then
		filter:SetCriteria(FiltersFrame:GetCriteria())
		EasyDestroy.Filters.SaveFilter(filter)
		
		FiltersFrame.ReloadFilter(filter.filterID)

	else
		print("UNKNOWN ERROR when saving Filter " .. filter.properties.name)
	end

end

function protected.DeleteFilterOnClick()

	--[[ Delete current filter. Load user's favorite filter if one is available. ]]
	local FilterID = UIDropDownMenu_GetSelectedValue(FiltersFrame.FilterDropDown)

	-- can't delete a non-existent filter TODO: Should this just clear the filter frame? Or maybe add a Clear button?
	if FilterID == 0 then return end 

	EasyDestroy.Filters.DeleteFilter(FilterID)

	local favoriteID =  EasyDestroy.Favorites.GetFavorite()

	if EasyDestroy.Favorites.UsingCharacterFavorites() and favoriteID == FilterID then
		EasyDestroy.Favorites.ClearUserFavorite()
		favoriteID = nil
	end

	if favoriteID ~= nil then
		UIDropDownMenu_SetSelectedValue(FiltersFrame.FilterDropDown, favoriteID)
		FiltersFrame.LoadFilter(favoriteID)
	else
		UIDropDownMenu_SetSelectedValue(FiltersFrame.FilterDropDown, 0)
		FiltersFrame.Clear()
	end

end

function protected.LoadFilterFromTable(filter)
	-- functionally we are creating a new filter
	protected.NewOnClick()

	if filter.filterType == ED_FILTER_TYPE_BLACKLIST then
		FiltersFrame.FilterType:SetChecked(true)
		FiltersFrame.Favorite:Disable()
	else
		FiltersFrame.FilterType:SetChecked(false)
		FiltersFrame.Favorite:Enable()
	end

	for key, registeredFilter in pairs(EasyDestroy.CriteriaRegistry) do
		registeredFilter:Clear()
		if key and filter.criteria and filter.criteria[key] then 
			tinsert(EasyDestroy.CriteriaStack, registeredFilter)
			registeredFilter:SetValues(filter.criteria[key] or "")
		end
	end

	FiltersFrame.PlaceCriteria()

	EasyDestroy.Events:Call("ED_FILTER_CRITERIA_CHANGED", filter)

end

function protected.ExportFilterOnClick()
	ImportExportDialog(false, protected.GetEncodedFilter())
end

function protected.ImportFilterOnClick()
	ImportExportDialog(true, nil, protected.LoadEncodedFilter)
end

function protected.GetEncodedFilter()
	local libs = LibStub("LibSerialize")
	local libd = LibStub("LibDeflate")
	if not libs or not libd then return end

	local filter = {}
	filter.criteria = FiltersFrame.GetCriteria()
	filter.filterType = FiltersFrame.GetFilterType()

	local serialized = libs:Serialize(filter)
	local compressed = libd:CompressDeflate(serialized)
	return libd:EncodeForPrint(compressed)
end

function protected.LoadEncodedFilter(encoded_filter)
	local libs = LibStub("LibSerialize")
	local libd = LibStub("LibDeflate")
	if not libs or not libd then return end

	local from_print = libd:DecodeForPrint(encoded_filter)
	local decompressed = libd:DecompressDeflate(from_print)
	local success, deserialized = libs:Deserialize(decompressed)

	if not success then
		error("EasyDestroy: Error, invalid filter.")
		return
	end

	protected.LoadFilterFromTable(deserialized)
end

