EasyDestroy = EasyDestroy
EasyDestroyFilters.Registry = {}
EasyDestroyFilters.FilterStack = {}
EasyDestroyFilters.CurrentFilterID = nil
--[[
filters = {
	Armor Type = Cloth, Leather, Mail, Plate
	Bags = Backpack, Bags 1-4
	Bind Type = BOE, BOP
	Equipment Set = true/false
	Item Level = Min, Max
	Item Name = string
	Item Quality = Common, Uncommon, Rare, Epic
	Item Slot = Equip slots
	Item Type = Armor, Weapon, Trade Good
	Sell Price = Min, Max
	Item ID = integer to lookup
	Transmog = (have or not, true/false)
	Weapon Type = Axe, Sword, Bow, etc.
	}
	
]] 

function EasyDestroyFilters:SetupWindow()		
	EasyDestroyFilterSettings.FilterName.label:SetText("Filter Name:")
	EasyDestroyFilterSettings.Favorite:SetChecked(false);		
	EasyDestroyFilterSettings.Blacklist.label:SetText("Blacklist")
	UIDropDownMenu_SetWidth(EasyDestroyFilterTypes, EasyDestroyFilterSettings:GetWidth()-50)

	StaticPopupDialogs["ED_CONFIRM_DELETE_FILTER"] = {
		text = "Are you sure you wish to delete filter %s?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = EasyDestroyFilters_DeleteFilter,
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ED_CONFIRM_NEW_FAVORITE"] = {
		text = "You already have a favorite filter. Do you want to make this your new favorite filter?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self) EasyDestroyFilters_SaveFilter(true) end,
		OnCancel = function(self) EasyDestroyFilterSettings.Favorite:SetChecked(false) end,
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ED_BLACKLIST_NO_FAVORITE"] = {
		text = "You cannot set a blacklist as a favorite. If you continue, this filter will be no longer be favorited. |n|n|cFFFF0000This applies to all characters that have this filter as a favorite.",
		button1 = "Okay",
		button2 = "Cancel",
		OnAccept = function(self) 
			EasyDestroyFilterSettings.Favorite:SetChecked(false)
			EasyDestroyFilterSettings.Favorite:Disable()
			EasyDestroy_UnsetFavorite()
		end,
		OnCancel = function(self)
			EasyDestroyFilterSettings.Blacklist:SetChecked(false)
		end,
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ED_SHOW_ALL_FILTERS"] = {
		text = "You do not currently have both Searches and Blacklists checked. |nChecking this box will cause both Searches and Blacklists to show under the Filter selection. Do you wish to continue?",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function(self) EasyDestroy:SelectAllFilterTypes() end,
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ED_FILTER_UNIQUE_NAME"] = {
		text = "Filters require a unique name. %s is already used.|n|n|cFFFF0000Your filter has NOT been saved.|r",
		button1 = "Okay",
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	EasyDestroyFilterSettings.Blacklist:SetScript("OnClick", function(self) 
		if EasyDestroyFilterSettings.Blacklist:GetChecked() and EasyDestroyFilterSettings.Favorite:GetChecked() then 
			StaticPopup_Show("ED_BLACKLIST_NO_FAVORITE") 
		end  

		if not EasyDestroy:IncludeBlacklists() or not EasyDestroy:IncludeSearches() then
			StaticPopup_Show("ED_SHOW_ALL_FILTERS")
		end

		if self:GetChecked() and EasyDestroyFilterSettings.Favorite:IsEnabled() then
			EasyDestroyFilterSettings.Favorite:Disable()
		elseif not self:GetChecked() and not EasyDestroyFilterSettings.Favorite:IsEnabled() then
			EasyDestroyFilterSettings.Favorite:Enable()
		end
		EasyDestroy.FilterChanged = true
	end )
end

function EasyDestroyFilters:RegisterFilter(filter)
    --[[ 
    Register a filter with the addon.
    This should be called by the filters themselves.
    ]]
	local filterKeys = EasyDestroy.Keys(filter)
	if not tContains(filterKeys, 'name') then
		EasyDestroy.Error('Error: Filter found with no name. Unable to register.')
		return
	elseif not tContains(filterKeys, 'key') then 
		EasyDestroy.Error('Error: Filter ' .. filter.name .. ' nunable to load. No key provided.')
		return
	end

	EasyDestroyFilters.Registry[filter.key] = filter
	UIDropDownMenu_Initialize(EasyDestroyFilterTypes, EasyDestroyFilters.InitializeFilterTypesDropDown)
end

function EasyDestroyFilters:GetFilterName()
	return EasyDestroyFilterSettings.FilterName.input:GetText()
end

function EasyDestroyFilters:SetFilterName(filtername)
	if filtername ~= nil and type(filtername) == "string" then 
		EasyDestroyFilterSettings.FilterName.input:SetText(filtername)
	end
end

function EasyDestroyFilters.InitializeFilterTypesDropDown()
	local info = UIDropDownMenu_CreateInfo()
	local filterRegistry = EasyDestroyFilters.Registry
	info.text, info.value, info.func, info.owner, info.isTitle, info.notCheckable = 
	"Select filters ...", 0, nil, EasyDestroyFilterTypes, true, true
	UIDropDownMenu_AddButton(info)
	--refresh info w/o any of the above settings, not sure why disabled is getting set, may be a function of isTitle or notCheckable.
	info.isTitle, info.notCheckable, info.disabled = false, false, false
	--pprint(info)
	for k, v in pairs(filterRegistry) do
		info.text, info.value, info.checked, info.func, info.owner, info.keepShownOnClick =
		v.name, v.key, v.IsShown(), EasyDestroyFilters.SelectFilterTypes, EasyDestroyFilterTypes, true
		UIDropDownMenu_AddButton(info)
	end
	UIDropDownMenu_SetText(EasyDestroyFilterTypes, "Select filters...")
end

function EasyDestroyFilters.SelectFilterTypes(self, arg1, arg2, checked)
	local selectedValue = self.value
	local selectedFilter = EasyDestroyFilters.Registry[selectedValue]
	UIDropDownMenu_SetText(EasyDestroyFilterTypes, "Select filters...")

	if checked then 
		local frame = selectedFilter.GetFilterFrame()
		local lastFrame = nil
		local scrollFrame = _G[EDFILTER_SCROLL_CHILD]
		if EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack] and EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack].frame then
			lastFrame = EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack].frame
		else
			lastFrame = nil --EasyDestroyFilters_AddFilterType
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
		tinsert(EasyDestroyFilters.FilterStack, selectedFilter)
		lastFrame = frame
	else
		local frame = selectedFilter.GetFilterFrame()
		for k, v in ipairs(EasyDestroyFilters.FilterStack) do
			if v.key == selectedFilter.key then
				v.frame:Hide()
				v.Clear()
				tremove(EasyDestroyFilters.FilterStack, k)
			end
		end
	end
	EasyDestroy_PlaceFilterFrames()
	EasyDestroy_Refresh()
end

function EasyDestroyFilters:HaveTransmog(itemlink)
	local appearance = C_TransmogCollection.GetItemInfo(itemlink);
	if appearance then 
		local sources = C_TransmogCollection.GetAppearanceSources(appearance);
		if sources then
			for k, v in pairs(sources) do
				if v.isCollected then
					return true
				end
			end
		end
	end
	return false
end

--[[ This generates our filter table from settings in the EasyDestroyFilters window. ]]
function EasyDestroy:GenerateFilter()
	local filterObj = {}
	filterObj.properties = {}
	filterObj.filter = {}

	for key, registeredFilter in pairs(EasyDestroyFilters.Registry) do
		local val = registeredFilter:GetValues()
		if val ~= nil then 
			filterObj.filter[key] = val
		end
	end

	local filter_name = EasyDestroyFilters:GetFilterName()	
	if not filter_name or filter_name == "" then 
		filter_name = "Filter" .. tostring(EasyDestroyFilters:GetNextFilterID(true))
	end
		
	filterObj.properties.name = filter_name
	filterObj.properties.favorite = EasyDestroyFilters_FavoriteIcon:GetChecked()
	if EasyDestroyFilterSettings.Blacklist:GetChecked() then
		filterObj.properties.type = ED_FILTER_TYPE_BLACKLIST
	else
		filterObj.properties.type = ED_FILTER_TYPE_SEARCH
	end
		
	return filterObj
end

function EasyDestroyFilters:GetNextFilterID(noiterate)
	--[[
		Every filter gets a unique id (Filter ID).
		This ID is used to identify a filter as a
		character favorite, and to simplify CRUD
		functionality.
	]]
	local nextID = EasyDestroy.Data.Options.NextFilterID or 0
	if nextID <= 0 then 
		for _, v in pairs(EasyDestroy.Data.Filters) do
			nextID = nextID + 1
		end
		nextID = nextID + 100
	end
	if not noiterate then
		nextID = nextID + 1
	end
	EasyDestroy.Data.Options.NextFilterID = nextID
	return nextID

end

function EasyDestroyFilters_SaveFilter(skipFavoriteCheck)
	--[[ 
		Get the FID of the currently selected filter.
		If there is no current filter, generate a FID.
		Generate the filter from current settings.
		Validate the filter for saving.
		Popup validation errors as necessary.
		If validation is clean (or we are ignoring the favorite check) then save the filter.
	]]
	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)

	-- if we are creating a new filter, then give it an ID
	if FilterID == 0 and not EasyDestroyFilters.CurrentFilterID then
		FilterID = "FilterID" .. EasyDestroyFilters:GetNextFilterID()
	elseif EasyDestroyFilters.CurrentFilterID ~= nil and EasyDestroyFilters.CurrentFilterID ~= 0 then
		FilterID = EasyDestroyFilters.CurrentFilterID
	end

	local filter = EasyDestroy:GenerateFilter()
	local valid, validationErrorType, validationMessage = EasyDestroyFilters_SaveValidation(FilterID, filter)

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
		EasyDestroy.Debug("Saving filter")
		if EasyDestroy.DebugActive then
			pprint(filter)
		end
		if validationErrorType == ED_ERROR_FAVORITE then
			EasyDestroyFilters_ClearFavorite()
		end
		EasyDestroyFilters__Save(FilterID, filter)

	else
		print("EasyDestroy: UNKNOWN ERROR when saving Filter " .. filter.properties.name)
	end

end

function EasyDestroyFilters_CreateNewFromCurrent()
	-- This will allow you to create a copy of the currently selected filter after you edit it.
	-- At the very least you would have to give it a differnt name before using this.

	local CurrentFilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)

	local FilterID = "FilterID" .. EasyDestroyFilters:GetNextFilterID()

	local filter = EasyDestroy:GenerateFilter()
	local valid, validationErrorType, validationMessage = EasyDestroyFilters_SaveValidation(FilterID, filter, true)

	-- if not valid because name is in use, print error
	if not valid and validationErrorType == ED_ERROR_NAME then
		StaticPopup_Show("ED_FILTER_UNIQUE_NAME", validationMessage)
		EasyDestroy.Debug("Name must be unique")

	-- if not valid because the current filter is the favorite OR if valid, save
	elseif (not valid and validationErrorType == ED_ERROR_FAVORITE) or valid then
		filter.properties.favorite = false
		EasyDestroyFilters__Save(FilterID, filter)

	else
		print("UNKNOWN ERROR when saving Filter " .. filter.properties.name)
	end

end

function EasyDestroyFilters__Save(filterID, filter)
	--[[ 
		This is the actual saving function.
		If using Character Favorites and the filter is favorited then
		set the character settings for this favorite.

	]]
	EasyDestroy:Debug("Saving Filter", filterID)
	EasyDestroy.Data.Filters[filterID] = filter

	if EasyDestroy.DebugActive then
		pprint(filter)
	end

	-- update favorite id for character specific ids
	if EasyDestroyFilterSettings.Favorite:GetChecked() then
		if EasyDestroy_UsingCharacterFavorites() then
			EasyDestroy.CharacterData.FavoriteID = filterID
		end
	end

	-- not a fan of putting this stuff  over here in filters. But that's just how it is for now.
	EasyDestroy_LoadFilter(filterID)
	EasyDestroy_InitDropDown()
	EasyDestroy.FilterChanged = true
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, filterID)
end

function EasyDestroyFilters_DeleteFilter()
	--[[ Delete current filter. Load user's favorite filter if one is available. ]]
	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
	EasyDestroy:Debug("Deleting Filter", FilterID)
	EasyDestroy.Data.Filters[FilterID] = nil

	EasyDestroy_InitDropDown()

	local favoriteID =  EasyDestroy_GetFavorite()
	if favoriteID ~= nil then
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, favoriteID)
		EasyDestroy_LoadFilter(favoriteID)
		EasyDestroy.FilterChanged = true
	end
end

function EasyDestroyFilters_SaveValidation(newFilterID, filter, skipFavoriteCheck)

	local fid = EasyDestroy_GetFavorite()
	local nameFid, nameFilter = EasyDestroyFilters_FindFilterWithName(filter.properties.name)

	-- if the name already exists and the name does not belong to the filter we are checking
	if nameFid and nameFid ~= newFilterID then
		return false, ED_ERROR_NAME, filter.properties.name

	elseif fid and fid ~= nil and EasyDestroy_UsingCharacterFavorites() and not skipFavoriteCheck then
		if fid ~= newFilterID and EasyDestroyFilterSettings.Favorite:GetChecked() then
			return false, ED_ERROR_FAVORITE, "This character already has a favorite."
		end
		
	elseif fid and fid ~= nil and filter.properties.favorite and not skipFavoriteCheck then
		EasyDestroy.Debug(fid, newFilterID, "Checking for filter id match.")
		if fid ~= newFilterID and EasyDestroyFilterSettings.Favorite:GetChecked() then
			return false, ED_ERROR_FAVORITE, 'Error: you already have a favorite filter, click save again to override.'
		end
	end

	return true, ED_ERROR_NONE, ''

end

function EasyDestroyFilters_FindFilterWithName(filterName)
	if EasyDestroy.Data.Filters then
		for fid, filter in pairs(EasyDestroy.Data.Filters) do

			if filter.properties.name == filterName then

				return fid, filter

			end

		end
	end

	return nil
end

function EasyDestroy_ClearFilterFrame()
	EasyDestroyFilters:SetFilterName("")
	EasyDestroyFilters_FavoriteIcon:SetChecked(false)
	EasyDestroyFilterSettings.Blacklist:SetChecked(false)
	EasyDestroyFilters.CurrentFilterID = nil
end

-- loops through the filter registry, clears/hides any active filters, and sets the filterstack to an empty list.
function EasyDestroy_ResetFilterStack()
	for k,v in pairs(EasyDestroyFilters.Registry) do
		v:Clear()
		if v.frame then
			v.frame:Hide()
		end
	end
	wipe(EasyDestroyFilters.FilterStack)
end

function EasyDestroy_PlaceFilterFrames()
	local lastFrame = nil
	local scrollFrame = _G[EDFILTER_SCROLL_CHILD]
	for k, v in ipairs(EasyDestroyFilters.FilterStack) do
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

function EasyDestroy_LoadFilter(fid)
	EasyDestroy_ClearFilterFrame()
	EasyDestroy_ResetFilterStack()
	EasyDestroy:Debug("Loading Filter", fid)
	local filter = EasyDestroy.Data.Filters[fid]
	EasyDestroyFilters.CurrentFilterID = fid

	EasyDestroyFilters:SetFilterName(filter.properties.name) --_FilterName.input:SetText(filter.properties.name)
	if EasyDestroy_UsingCharacterFavorites() then
		local fav = EasyDestroy_GetFavorite()
		if fav and fav ~= nil and fav == fid then
			if filter.properties.type ~= ED_FILTER_TYPE_BLACKLIST then
				EasyDestroyFilters_FavoriteIcon:SetChecked(true)
			else
				-- if a player tries to load a filter that's a blacklist and they have previously
				-- marked it as a favorite, then we're going to unset that (sorry, not sorry).
				EasyDestroy_UnsetFavorite()
			end
		end
	else
		EasyDestroyFilters_FavoriteIcon:SetChecked(filter.properties.favorite)
	end
	
	if filter.properties.type == ED_FILTER_TYPE_BLACKLIST then
		EasyDestroyFilterSettings.Blacklist:SetChecked(true)
		EasyDestroyFilterSettings.Favorite:Disable()
	else
		EasyDestroyFilterSettings.Blacklist:SetChecked(false)
		EasyDestroyFilterSettings.Favorite:Enable()
	end

	for key, registeredFilter in pairs(EasyDestroyFilters.Registry) do
		registeredFilter:Clear()
		if filter.filter[key] ~= nil then
			tinsert(EasyDestroyFilters.FilterStack, registeredFilter)
			EasyDestroy_PlaceFilterFrames()
			registeredFilter:SetValues(filter.filter[key] or "")
		end
	end
end
