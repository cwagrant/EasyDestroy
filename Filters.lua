EasyDestroy = EasyDestroy
EasyDestroyFilters.Registry = {}
EasyDestroyFilters.FilterStack = {}
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
--[[
	How are we going to handle having 2 drop downs. 1 for the main window and 1 for the editor.

	If a user selects a Search from the main window drop down - load that filter into the editor window

	Maybe instead of having the 2 different drop downs we'll stick to one drop down. That way when
	a user is editing a blacklist they see what items it catches in the main window. 

	What happens when they select Blacklist on a filter they are editing if they don't have Blacklists checked
	on the main window? 
	 - We could check it for them automatically?

	Alternative: What if instead of having a blacklist checkbox, we add a new button on the editor window.
	[Convert to Blacklist] / [Convert to Search] --Nixxed this idea, would require some kind of indicator to show it's a blacklist anyways.
	 - If you click Convert to Blacklist and blacklist isn't checked, does it just switch over to your favorite filter?
	 - If you click Convert to Search and search isn't checked does it just switch to an empty/New filter?
	 - Executive Decision: Clicking the Convert button will activate the checkbox in main window for the appropriate type.
		 Give users a 1 time message advising them that clicking one of these buttons will force the main window
		 selections for Searches and Blacklists to both be enabled.
			- Add separator in the drop down for when you have both Searches and Blacklists checked
			- Will require splitting the loop out into 2 sections, 1 for searches, a second for blacklists
			- Only include separator & title when blacklists AND searches are shown. Otherwise just show searches.
			- Add title row anyway to both just for clarity?

	BIG TODO:
	Cleanup functions/names/frames etc. Lets make this shit be a bit more sensible

	e.g. lets make getters/setters and not allow all the madness that is the current iteration of filters

	Add confirm box for Delete
]]

function EasyDestroyFilters:SetupWindow()
	self.Title:SetFontObject("GameFontHighlight");
	self.Title:SetText("Filter Editor");		
	self.FilterName.label:SetText("Filter Name:")
	self.Favorite:SetChecked(false);		
	self.Blacklist.label:SetText("Blacklist")
	UIDropDownMenu_SetWidth(EasyDestroyFilterTypes, self:GetWidth()-60)

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
		OnAccept = function(self) EasyDestroyFilters.SaveFilter(true) end,
		OnCancel = function(self) EasyDestroyFilters.Favorite:SetChecked(false) end,
		timeout = 30,
		whileDead = false,
		hideOnEscape = true,
		preferredIndex = 3,
	}

	StaticPopupDialogs["ED_BLACKLIST_NO_FAVORITE"] = {
		text = "You cannot set a blacklist as a favorite. If you continue, this filter will be no longer be favorited.",
		button1 = "Okay",
		button2 = "Cancel",
		OnAccept = function(self) 
			EasyDestroyFilters.Favorite:SetChecked(false)
			EasyDestroyFilters.Favorite:Disable()
		end,
		OnCancel = function(self)
			EasyDestroyFilters.Blacklist:SetChecked(false)
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

	EasyDestroyFilters.Blacklist:SetScript("OnClick", function() 
		if EasyDestroyFilters.Blacklist:GetChecked() and EasyDestroyFilters.Favorite:GetChecked() then 
			StaticPopup_Show("ED_BLACKLIST_NO_FAVORITE") 
		end  

		if not EasyDestroy:IncludeBlacklists() or not EasyDestroy:IncludeSearches() then
			StaticPopup_Show("ED_SHOW_ALL_FILTERS")
		end
	end )
end

function EasyDestroyFilters:GetFilterName()
	return self.FilterName.input:GetText()
end

function EasyDestroyFilters:SetFilterName(filtername)
	if filtername ~= nil and type(filtername) == "string" then 
		self.FilterName.input:SetText(filtername)
	end
end

function EasyDestroyFilters:RegisterFilter(filter)
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
		if EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack] and EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack].frame then
			lastFrame = EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack].frame
		else
			lastFrame = EasyDestroyFilters_AddFilterType
		end
		frame:SetPoint("LEFT", EasyDestroyFiltersDialogBG, "LEFT", 4, 0)
		frame:SetPoint("RIGHT", EasyDestroyFiltersDialogBG, "RIGHT", -4, 0)
		frame:SetPoint("TOP", lastFrame, "BOTTOM")
		frame:SetHeight(selectedFilter.height)
		frame:Show()
		tinsert(EasyDestroyFilters.FilterStack, selectedFilter)
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
	EasyDestroyFilters:RestackFilters()
	EasyDestroy_Refresh()
end

function EasyDestroyFilters:RestackFilters()
	local lastFrame = EasyDestroyFilters_AddFilterType
	for k, v in ipairs(self.FilterStack) do
		v.frame:SetPoint("TOP", lastFrame, "BOTTOM")
		lastFrame = v.frame
	end
end

function EasyDestroyFilters:HaveTransmog(itemlink)
	local appearance = C_TransmogCollection.GetItemInfo(itemlink);
	if apperance then 
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
	if EasyDestroyFilters.Blacklist:GetChecked() then
		filterObj.properties.type = ED_FILTER_TYPE_BLACKLIST
	else
		filterObj.properties.type = ED_FILTER_TYPE_SEARCH
	end
		
	return filterObj
end

function EasyDestroyFilters:GetNextFilterID(noiterate)

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

function EasyDestroyFilters.SaveFilter(skipFavoriteCheck)
	-- This will save the currently selected filter, if selection is "New Filter..." then
	-- this will create the save the new filter with a new FilterID

	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)

	-- if we are creating a new filter, then give it an ID
	if FilterID == 0 then
		FilterID = "FilterID" .. EasyDestroyFilters:GetNextFilterID()
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

	-- elseif filter.properties.favorite and filter.properties.type == ED_FILTER_TYPE_BLACKLIST then

	-- end

	-- if error and error is type favorite and we have alredy warned them OR it is valid, then we save the filter
	elseif (not valid and validationErrorType == ED_ERROR_FAVORITE) or valid then
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
	-- At the very least you would have to give it a differnt name before using this

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

	EasyDestroy:Debug("Saving Filter", filterID)
	EasyDestroy.Data.Filters[filterID] = filter

	-- not a fan of putting this stuff  over here in filters. But that's just how it is for now.
	EasyDestroy_LoadFilter(filterID)
	EasyDestroy_InitDropDown()
	-- UIDropDownMenu_Initialize(EasyDestroyDropDown, EasyDestroy_InitDropDown)
	EasyDestroy.FilterChanged = true
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, filterID)

end

function EasyDestroyFilters_DeleteFilter()

	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
	EasyDestroy:Debug("Deleting Filter", FilterID)
	EasyDestroy.Data.Filters[FilterID] = nil

	EasyDestroy_InitDropDown()
	for k, filterObj in pairs(EasyDestroy.Data.Filters) do
		if filterObj.properties.favorite then
			UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, k)
			EasyDestroy_LoadFilter(k)
			EasyDestroy.FilterChanged = true
		end
	end

end

function EasyDestroyFilters_SaveValidation(newFilterID, filter, skipFavoriteCheck)

	local fid, favoriteFilter = EasyDestroyFilters_FindFavorite()
	local nameFid, nameFilter = EasyDestroyFilters_FindFilterWithName(filter.properties.name)

	-- if the name already exists and the name does not belong to the filter we are checking
	if nameFid and nameFid ~= newFilterID then
		return false, ED_ERROR_NAME, filter.properties.name

	elseif favoriteFilter and filter.properties.favorite and not skipFavoriteCheck then
		EasyDestroy.Debug(fid, newFilterID, "Checking for filter id match.")
		if fid ~= newFilterID then
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

function EasyDestroyFilters_FindFavorite()
	if EasyDestroy.Data.Filters then 
		for fid, filter in pairs(EasyDestroy.Data.Filters) do

			if filter.properties.favorite then

				return fid, filter

			end

		end
	end

	return nil
end

function EasyDestroyFilters_ClearFavorite(fid)
	if fid then
		EasyDestroy.Data.Filters[fid].properties.favorite = false
	else
		for fid, filter in pairs(EasyDestroy.Data.Filters) do
			filter.properties.favorite=false
		end
	end
	
end

function EasyDestroy_ClearFilterFrame()
	EasyDestroyFilters:SetFilterName("")
	EasyDestroyFilters_FavoriteIcon:SetChecked(false)
	EasyDestroyFilters.Blacklist:SetChecked(false)
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

function EasyDestroy_LoadFilter(fid)
	EasyDestroy_ClearFilterFrame()
	EasyDestroy_ResetFilterStack()
	EasyDestroy:Debug("Loading Filter", fid)
	local filter = EasyDestroy.Data.Filters[fid]

	EasyDestroyFilters:SetFilterName(filter.properties.name) --_FilterName.input:SetText(filter.properties.name)
	EasyDestroyFilters_FavoriteIcon:SetChecked(filter.properties.favorite)
	
	if filter.properties.type == ED_FILTER_TYPE_BLACKLIST then
		EasyDestroyFilters.Blacklist:SetChecked(true)
		EasyDestroyFilters.Favorite:Disable()
	else
		EasyDestroyFilters.Blacklist:SetChecked(false)
		EasyDestroyFilters.Favorite:Enable()
	end

	for key, registeredFilter in pairs(EasyDestroyFilters.Registry) do
		registeredFilter:Clear()
		if filter.filter[key] ~= nil then
			local frame = registeredFilter.GetFilterFrame()
			local lastFrame = nil
			if EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack] and EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack].frame then
				lastFrame = EasyDestroyFilters.FilterStack[#EasyDestroyFilters.FilterStack].frame
			else
				lastFrame = EasyDestroyFilters_AddFilterType
			end
			frame:SetPoint("LEFT", EasyDestroyFiltersDialogBG, "LEFT", 4, 0)
			frame:SetPoint("RIGHT", EasyDestroyFiltersDialogBG, "RIGHT", -4, 0)
			frame:SetPoint("TOP", lastFrame, "BOTTOM")
			frame:SetHeight(registeredFilter.height)
			frame:Show()
			tinsert(EasyDestroyFilters.FilterStack, registeredFilter)
			registeredFilter:SetValues(filter.filter[key] or "")
		end
	end
end

function EasyDestroyFilters_FavoriteIconOnClick()
	if EasyDestroyFilters_FavoriteIcon:GetChecked() then
		EasyDestroyFilters_FavoriteIcon:SetChecked(false)
	else
		local existingFavorite = EasyDestroyFilters_FindFavorite()
		if existingFavorite then
			EasyDestroy.Data.Filters[existingFavorite].properties.favorite = false
		end
		EasyDestroyFilters_FavoriteIcon:SetChecked(true)
	end
end