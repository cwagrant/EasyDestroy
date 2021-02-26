--[[ 
    Dress up the spaghetti with a more formalized structure.
    Eventually we'll work backwards from this in cleaning up old code.
]]

--[[ Main Window ]]
EasyDestroy.UI.ItemWindowFrame = EasyDestroyItems
EasyDestroy.UI.ItemWindow = EasyDestroyItemsFrame
EasyDestroy.UI.FilterDropDown = EasyDestroyDropDown
EasyDestroy.UI.FilterDropDown.SearchesCheckbutton = EasyDestroyFrameSearch.Types.Search
EasyDestroy.UI.FilterDropDown.BlacklistsCheckbutton = EasyDestroyFrameSearch.Types.Blacklist

--[[ Configurator Fields ]]
EasyDestroy.UI.FilterName = EasyDestroyFilterSettings.FilterName
EasyDestroy.UI.Favorite = EasyDestroyFilterSettings.Favorite
EasyDestroy.UI.FilterType = EasyDestroyFilterSettings.Blacklist
EasyDestroy.UI.CriteriaDropdown = EasyDestroyFilterTypes
EasyDestroy.UI.CriteriaWindow = EasyDestroySelectedFilters

--[[ Configurator/Filter Buttons]]
EasyDestroy.UI.Buttons = {}
EasyDestroy.UI.Buttons.NewFilter = EasyDestroyFilters_New
EasyDestroy.UI.Buttons.NewFilterFromCurrent = EasyDestroyFilters_NewFromFilter
EasyDestroy.UI.Buttons.DeleteFilter = EasyDestroyFilters_Delete
EasyDestroy.UI.Buttons.SaveFilter = EasyDestroyFilters_Save

--[[ Main "Always Shown" UI Buttons]]
EasyDestroy.UI.Buttons.DestroyButton = EasyDestroyButton
EasyDestroy.UI.Buttons.ToggleConfigurator = EasyDestroy_ToggleConfigurator
EasyDestroy.UI.Buttons.ShowItemBlacklist = EasyDestroy_OpenBlacklist

--[[ Font Strings ]]
EasyDestroy.UI.ItemCounter = EasyDestroyFrame_FoundItemsCount

function EasyDestroy.UI.ItemWindow.Update()

    -- Update the Item Window (Item List)

    EasyDestroy.Debug("EasyDestroy.UI.ItemWindow.Update")

    EasyDestroy.UI.ItemWindow.UpdateItemList = true
    EasyDestroy.UI.ItemWindow:ScrollUpdate()
    EasyDestroy.UI.ItemCounter:SetText(EasyDestroy.UI.ItemWindow.ItemCount ..  " Item(s) Found")

end

function EasyDestroy.UI.FilterDropDown.Initialize()

    EasyDestroy.Debug("EasyDestroy.UI.FilterDropDown.Initialize")

    local info = UIDropDownMenu_CreateInfo()
	local favoriteID = nil
	info.text, info.value, info.checked, info.func, info.owner = EasyDestroy.Dict.Strings.FilterSelectionDropdownNew, 0, false, EasyDestroy.Handlers.FilterDropDownOnSelect, EasyDestroyDropDown
	UIDropDownMenu_AddButton(info)
	local hasSeparator = false
	local includeSearches, includeBlacklists = EasyDestroy:IncludeSearches(), EasyDestroy:IncludeBlacklists()

	-- This monstrosity sorts by type=type and name<name or type<type
	-- e.g. if types match, sort by name, otherwise sort by type
	if EasyDestroy.Data.Filters then
		for fid, filter in EasyDestroy.spairs(EasyDestroy.Data.Filters, function(t, a, b) return (t[a].properties.type == t[b].properties.type and t[a].properties.name:lower() < t[b].properties.name:lower()) or t[a].properties.type < t[b].properties.type end) do
			info.text, info.value, info.checked, info.func, info.owner = filter.properties.name, fid, false, EasyDestroy.Handlers.FilterDropDownOnSelect, EasyDestroyDropDown

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

-- An alias for clarifying when we actually initialize the drop down vs are just updating the data in it.
EasyDestroy.UI.FilterDropDown.Update = EasyDestroy.UI.FilterDropDown.Initialize

function EasyDestroy.UI.GetSelectedFilter()

    return UIDropDownMenu_GetSelectedValue(EasyDestroy.UI.FilterDropDown)

end

function EasyDestroy.UI.SetSelectedFilter(val)

    UIDropDownMenu_SetSelectedValue(EasyDestroy.UI.FilterDropDown, val)

end

function EasyDestroy.UI.UpdateFilterDropDownWidth()

    -- Could probably map this to the OnSizeChanged widget handler for the EasyDestroyFrame

    UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)

end


function EasyDestroy.UI.GetFilterName()

	return EasyDestroy.UI.FilterName:GetText()

end

function EasyDestroy.UI.SetFilterName(filtername)
	if filtername == nil or type(filtername) ~= "string" then 
        error("Usage: EasyDestroy.UI.SetFilterName(filtername).")
    else
        EasyDestroy.UI.FilterName:SetText(filtername)
	end
end

function EasyDestroy.UI.GetFavoriteChecked()
    
    return EasyDestroy.UI.Favorite:GetChecked()

end

function EasyDestroy.UI.SetFavoriteChecked(bool)
    
    return EasyDestroy.UI.Favorite:SetChecked(bool)

end

function EasyDestroy.UI.GetFilterType()

    if EasyDestroy.UI.FilterType:GetChecked() then
        return ED_FILTER_TYPE_BLACKLIST
    end
    
    return ED_FILTER_TYPE_SEARCH

end

function EasyDestroy.UI.GetFilterProperties(filter)

    return EasyDestroy.UI.GetFilterName(), EasyDestroy.UI.GetFilterType(), EasyDestroy.UI.GetFavoriteChecked()

end

function EasyDestroy:SelectAllFilterTypes()

	EasyDestroy.UI.FilterDropDown.BlacklistsCheckbutton:SetChecked(true)
	EasyDestroy.UI.FilterDropDown.SearchesCheckbutton:SetChecked(true)
	
end

function EasyDestroy.UI.CriteriaDropdown.Initialize()

    --EasyDestroyFilters.InitializeFilterTypesDropDown()

	local info = UIDropDownMenu_CreateInfo()
	local filterRegistry = EasyDestroy.CriteriaRegistry

	info.text, info.value, info.func, info.owner, info.isTitle, info.notCheckable = 
	EasyDestroy.Dict.Strings.CriteriaSelectionDropdown, 0, nil, EasyDestroyFilterTypes, true, true

	UIDropDownMenu_AddButton(info)

	--refresh info w/o any of the above settings, not sure why disabled is getting set, may be a function of isTitle or notCheckable.
	info.isTitle, info.notCheckable, info.disabled = false, false, false

	for k, v in pairs(filterRegistry) do
		info.text, info.value, info.checked, info.func, info.owner, info.keepShownOnClick =
		v.name, v.key, v:IsShown(), EasyDestroy.Handlers.CriteriaDropDownOnSelect, EasyDestroyFilterTypes, true
		UIDropDownMenu_AddButton(info)
	end

	UIDropDownMenu_SetText(EasyDestroyFilterTypes, EasyDestroy.Dict.Strings.CriteriaSelectionDropdown)

end

-- EasyDestroy_ResetFilterStack
function EasyDestroy.UI.CriteriaWindow.Reset()

    -- Clears and hides all criteria in the registry and resets the criteria stack.

    EasyDestroy.Debug("EasyDestroy.UI.CriteriaWindow.Reset")

	for k,v in pairs(EasyDestroy.CriteriaRegistry) do
		v:Clear()
		if v.frame then
			v.frame:Hide()
		end
	end

	wipe(EasyDestroy.CriteriaStack)

end

-- EasyDestroy_PlaceFilterFrames
function EasyDestroy.UI.CriteriaWindow.PlaceCriteria()

    -- Places the currently selected criteria in the criteria window
    -- Handles placing them in order

    EasyDestroy.Debug("EasyDestroy.UI.CriteriaWindow.PlaceCriteria")

	local lastFrame = nil
	local scrollFrame = _G[EDFILTER_SCROLL_CHILD]
	for k, v in ipairs(EasyDestroy.CriteriaStack) do
		local frame = v.GetFilterFrame()
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

-- EasyDestroy_ClearFilterFrame
function EasyDestroy.UI.ClearFilterSettings()

    -- Clears the "settings" for the filter

    EasyDestroy.Debug("EasyDestroy.UI.ClearFilterSettings")

    EasyDestroy.UI.SetFilterName("")
	EasyDestroyFilters_FavoriteIcon:SetChecked(false)
	EasyDestroyFilterSettings.Blacklist:SetChecked(false)

end

function EasyDestroy.UI.ClearFilter()

    -- Clears both the settings and criteria from the UI.

    EasyDestroy.Debug("EasyDestroy.UI.ClearFilter")
    
    EasyDestroy.UI.ClearFilterSettings()
    EasyDestroy.UI.CriteriaWindow.Reset()

end

--EasyDestroy_LoadFilter
function EasyDestroy.UI.LoadFilter(fid)
	EasyDestroy.UI.ClearFilter()

	EasyDestroy.Debug("EasyDestroy.UI.LoadFilter", "Loading Filter", fid)
	-- local filter = EasyDestroy.Data.Filters[fid]
	local filter = EasyDestroyFilter:Load(fid)

    EasyDestroy.UI.SetFilterName(filter:GetName())

	if EasyDestroy.Favorites.UsingCharacterFavorites() then
		local fav = EasyDestroy.Favorites.GetFavorite()
		if fav and fav ~= nil and fav == fid then
			if filter:GetType() ~= ED_FILTER_TYPE_BLACKLIST then
				EasyDestroyFilters_FavoriteIcon:SetChecked(true)
			else
				-- if a player tries to load a filter that's a blacklist and they have previously
				-- marked it as a favorite, then we're going to unset that (sorry, not sorry).
					EasyDestroy.Favorites.UnsetFavorite()
			end
		end
	else
		EasyDestroyFilters_FavoriteIcon:SetChecked(filter:GetFavorite())
	end
	
	if filter:GetType() == ED_FILTER_TYPE_BLACKLIST then
		EasyDestroyFilterSettings.Blacklist:SetChecked(true)
		EasyDestroyFilterSettings.Favorite:Disable()
	else
		EasyDestroyFilterSettings.Blacklist:SetChecked(false)
		EasyDestroyFilterSettings.Favorite:Enable()
	end

	for key, registeredFilter in pairs(EasyDestroy.CriteriaRegistry) do
		registeredFilter:Clear()
		if filter:GetCriterionByKey(key) ~= nil then
			tinsert(EasyDestroy.CriteriaStack, registeredFilter)
			-- EasyDestroy.UI.CriteriaWindow.PlaceCriteria()
			registeredFilter:SetValues(filter:GetCriterionByKey(key) or "")
		end
	end

	-- We can just call this after we've loaded all the criteria
	EasyDestroy.UI.CriteriaWindow.PlaceCriteria()

end

-- EasyDestroy.Reload
function EasyDestroy.UI.ReloadFilter(filterID)

    -- For reloading after a filter has been saved

    EasyDestroy.Debug("EasyDestroy.UI.ReloadFilter")

	EasyDestroy.UI.LoadFilter(filterID)
	EasyDestroy.UI.FilterDropDown.Update()
	EasyDestroy.FilterChanged = true
	--UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
    EasyDestroy.UI.SetSelectedFilter(filterID)

    local filterNameUpdate = EasyDestroy.UI.GetFilterName()
    if EasyDestroy.DebugActive then
        filterNameUpdate = filterNameUpdate .. " | " .. filterID
    end

    -- because if you change the name, the system doesn't seem to know how to handle
    -- updating the menu text without you opening the menu, changing to another option
    -- and then changing back.

    UIDropDownMenu_SetText(EasyDestroy.UI.FilterDropDown, filterNameUpdate)

end
