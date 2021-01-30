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

function EasyDestroyFilters.GetFilterName()
	return EasyDestroyFilters_FilterName.input:GetText()
end

function EasyDestroy.InitFilters()
	EasyDestroyFilters.Title:SetFontObject("GameFontHighlight");
	EasyDestroyFilters.Title:SetText("Filters");		
	EasyDestroyFilters_FilterName.label:SetText("Filter Name:")
	EasyDestroyFilters_FavoriteIcon:SetChecked(false);		
end
--[[
function EasyDestroy_InitFilterDestroySpells()
	local info = UIDropDownMenu_CreateInfo()
	info.text, info.value, info.checked, info.func, info.owner = "Pick a spell...", 0, false, EasyDestroy_DestroySpellSelect, EasyDestroyDestroySpell
	UIDropDownMenu_AddButton(info)

	for _, spell in ipairs(EasyDestroy.Spells) do
		local spellname = GetSpellInfo(spell)
		info.text, info.value, info.checked, info.func, info.owner = spellname, spell, false, EasyDestroy_DestroySpellSelect, EasyDestroyDestroySpell
		UIDropDownMenu_AddButton(info)
	end
end]]

function EasyDestroy_InitFilterTypes()
	local info = UIDropDownMenu_CreateInfo()
	info.text, info.value, info.func, info.owner, info.isTitle, info.notCheckable = 
	"Select filters ...", 0, nil, EasyDestroyFilterTypes, true, true
	UIDropDownMenu_AddButton(info)
	--refresh info w/o any of the above settings
	info =  UIDropDownMenu_CreateInfo()
	for k, v in pairs(EasyDestroyFilters.Registry) do
		info.text, info.value, info.checked, info.func, info.owner, info.keepShownOnClick =
		v.name, v.key, v.IsShown(), EasyDestroy_FilterSelect, EasyDestroyFilterTypes, true
		UIDropDownMenu_AddButton(info)
	end
	UIDropDownMenu_SetText(EasyDestroyFilterTypes, "Select filters...")
	UIDropDownMenu_SetWidth(EasyDestroyFilterTypes, EasyDestroyFilters:GetWidth()-60)
end

function EasyDestroy_FilterSelect(self, arg1, arg2, checked)
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
				tremove(EasyDestroyFilters.FilterStack, k)
			end
		end
	end
	EasyDestroy_RestackFilters()
end

function EasyDestroy_RestackFilters()
	local lastFrame = EasyDestroyFilters_AddFilterType
	for k, v in ipairs(EasyDestroyFilters.FilterStack) do
		v.frame:SetPoint("TOP", lastFrame, "BOTTOM")
		lastFrame = v.frame
	end
end

function EasyDestroy.HaveTransmog(itemlink)
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

function EasyDestroy.GenerateFilter()
	local filterObj = {}
	filterObj.properties = {}
	filterObj.filter = {}

	for key, registeredFilter in pairs(EasyDestroyFilters.Registry) do
		local val = registeredFilter:GetValues()
		if val ~= nil then 
			filterObj.filter[key] = val
		end
	end

	local filter_name = EasyDestroyFilters.GetFilterName()	
	if not filter_name or filter_name == "" then 
		filter_name = "Filter" .. tostring(EasyDestroyFilters_GetNextFilterID(true))
	end
		
	filterObj.properties.name = filter_name
	filterObj.properties.favorite = EasyDestroyFilters_FavoriteIcon:GetChecked()
		
	return filterObj
end

function EasyDestroyFilters_GetNextFilterID(noiterate)

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

function EasyDestroyFilters_SaveFilter()
	-- This will save the currently selected filter, if selection is "New Filter..." then
	-- this will create the save the new filter with a new FilterID

	local FilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)

	-- if we are creating a new filter, then give it an ID
	if FilterID == 0 then
		FilterID = "FilterID" .. EasyDestroyFilters_GetNextFilterID()
	end

	local filter = EasyDestroy:GenerateFilter()
	local valid, validationErrorType, validationMessage = EasyDestroyFilters_SaveValidation(FilterID, filter)

	-- if error and error is not type name and we haven't already warned them, warn the user
	if not valid and validationErrorType ~= EasyDestroy.Errors.Name and not EasyDestroy.FilterSaveWarned then
		print(validationMessage)
		if validationErrorType == EasyDestroy.Errors.Favorite then
			EasyDestroy.FilterSaveWarned = true
		end

	-- if error and error is type name, reset warning status and print message
	elseif not valid and validationErrorType == EasyDestroy.Errors.Name then
		EasyDestroy.FilterSaveWarned = false
		print(validationMessage)

	-- if error and error is type favorite and we have alredy warned them OR it is valid, then we save the filter
	elseif (not valid and validationErrorType == EasyDestroy.Errors.Favorite and EasyDestroy.FilterSaveWarned) or valid then
		if validationErrorType == EasyDestroy.Errors.Favorite then
			EasyDestroyFilters_ClearFavorite()
		end
		EasyDestroyFilters__Save(FilterID, filter)
		EasyDestroy.FilterSaveWarned = false

	else
		print("UNKNOWN ERROR when saving Filter " .. filter.properties.name)
	end

end

function EasyDestroyFilters_CreateNewFromCurrent()
	-- This will allow you to create a copy of the currently selected filter after you edit it.
	-- At the very least you would have to give it a differnt name before using this

	local CurrentFilterID = UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)

	local FilterID = "FilterID" .. EasyDestroyFilters_GetNextFilterID()

	local filter = EasyDestroy:GenerateFilter()
	local valid, validationErrorType, validationMessage = EasyDestroyFilters_SaveValidation(FilterID, filter, true)

	-- if not valid because name is in use, print error
	if not valid and validationErrorType == EasyDestroy.Errors.Name then
		print(validationMessage)

	-- if not valid because the current filter is the favorite OR if valid, save
	elseif (not valid and validationErrorType == EasyDestroy.Errors.Favorite) or valid then
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
		return false, EasyDestroy.Errors.Name, 'Error: filter named ' .. filter.properties.name .. ' already exists.'

	elseif favoriteFilter and filter.properties.favorite and not skipFavoriteCheck then
		return false, EasyDestroy.Errors.Favorite, 'Error: you already have a favorite filter, click save again to override.'

	end

	return true, EasyDestroy.Errors.None, ''

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
	EasyDestroyFilters_FilterName.input:SetText("")
	EasyDestroyFilters_FavoriteIcon:SetChecked(false);
end

function EasyDestroy_ResetFilterStack()
	for k, v in ipairs(EasyDestroyFilters.FilterStack) do
		v.frame:Hide()
		EasyDestroyFilters.FilterStack[k] = nil
	end

	for k,v in pairs(EasyDestroyFilters.Registry) do
		v:Clear()
	end
end

function EasyDestroy_LoadFilter(fid)
	EasyDestroy_ClearFilterFrame()
	EasyDestroy_ResetFilterStack()
	EasyDestroy:Debug("Loading Filter", fid)
	local filter = EasyDestroy.Data.Filters[fid]

	EasyDestroyFilters_FilterName.input:SetText(filter.properties.name)
	EasyDestroyFilters_FavoriteIcon:SetChecked(filter.properties.favorite)

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