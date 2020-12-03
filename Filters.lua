EasyDestroy = EasyDestroy

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

function EasyDestroy.RegisterFilters()
	EasyDestroyFilters['name'] = function(inputname, itemname) if string.find(string.lower(itemname), string.lower(inputname)) then return true end return false end
	EasyDestroyFilters['quality'] = function(inputquality, itemquality) if tContains(inputquality, itemquality) then return true end return false end
	EasyDestroyFilters['level'] = EasyDestroyFilters.FilterItemLevel
	EasyDestroyFilters['id'] = function(inputid, itemid) if inputid == itemid then return true end return false end
end

function EasyDestroyFilters.FilterItemLevel(inputlevel, itemlevel)
	if itemlevel == nil then
		return false
	elseif type(inputlevel) ~= "table" then
		if inputlevel == itemlevel then
			return true
		end
	elseif itemlevel >=  inputlevel['levelfrom'] and itemlevel <= inputlevel['levelto'] then
		return true
	end
	return false
end

function EasyDestroyFilters.GetItemLevels()
	local inputfrom = EasyDestroyFilters_ItemLevel.inputfrom:GetNumber() or 0
	local inputto = EasyDestroyFilters_ItemLevel.inputto:GetNumber() or 0

	if inputto ~= 0 and inputto ~= nil then
		if inputfrom ~= nil then
			return {levelfrom=inputfrom, levelto=inputto}
		end
	end

	if inputfrom ~=0 and inputfrom ~= nil then
		return inputfrom
	end

	return nil

end

function EasyDestroyFilters.GetFilterName()
	return EasyDestroyFilters_FilterName.input:GetText()
end

function EasyDestroyFilters.GetItemName()
	return EasyDestroyFilters_ItemName.input:GetText()
end

function EasyDestroyFilters.GetItemID()
	return EasyDestroyFilters_ItemID.input:GetNumber()
end

function EasyDestroyFilters.GetRarityChecked(rarityType)
	rarityType = string.lower(rarityType)
	if EasyDestroyFilters_Rarity[rarityType] then
		if EasyDestroyFilters_Rarity[rarityType]:GetChecked() then
			return true
		end
	end
	return false
end

function EasyDestroy.InitFilters()
	EasyDestroyFilters.Title:SetFontObject("GameFontHighlight");
	EasyDestroyFilters.Title:SetText("Filters");		
	--EasyDestroyFilterDestroySpell.label:SetText("Destroy Spell:")
	--UIDropDownMenu_SetWidth(EasyDestroyDestroyType, (EasyDestroyDestroyType:GetWidth()-EasyDestroyFilterDestroySpellLabel:GetWidth()+25))
	EasyDestroyFilters_FilterName.label:SetText("Filter Name:")
	EasyDestroyFilters_ItemName.label:SetText("Item Name:")
	EasyDestroyFilters_ItemID.label:SetText("Item ID:")
	EasyDestroyFilters_ItemID.input:SetNumeric(true)
	EasyDestroyFilters_Rarity.common.label:SetText("|c11ffffff" .. "Common" .. "|r")
	EasyDestroyFilters_Rarity.rare.label:SetText("|c110070dd" .. "Rare" .. "|r")
	EasyDestroyFilters_Rarity.uncommon.label:SetText("|c111eff00" .. "Uncommon" .. "|r")
	EasyDestroyFilters_Rarity.epic.label:SetText("|c11a335ee" .. "Epic" .. "|r")
	EasyDestroyFilters_ItemLevel.label:SetText("Item Level:")
	EasyDestroyFilters_ItemLevel.inputfrom:SetNumeric(true)
	EasyDestroyFilters_ItemLevel.inputto:SetNumeric(true)
	EasyDestroyFilters_FavoriteIcon:SetChecked(false);
end

function EasyDestroy_InitFilterDestroySpells()
	local info = UIDropDownMenu_CreateInfo()
	info.text, info.value, info.checked, info.func, info.owner = "Pick a spell...", 0, false, EasyDestroy_DestroySpellSelect, EasyDestroyDestroySpell --EasyDestroy_DropDownSelect
	UIDropDownMenu_AddButton(info)

	for _, spell in ipairs(EasyDestroy.Spells) do
		local spellname = GetSpellInfo(spell)
		info.text, info.value, info.checked, info.func, info.owner = spellname, spell, false, EasyDestroy_DestroySpellSelect, EasyDestroyDestroySpell
		UIDropDownMenu_AddButton(info)
	end
end

function EasyDestroy.ItemInEquipmentSet(bag, slot)
	local sets = C_EquipmentSet.GetEquipmentSetIDs();
	
	for _, setid in pairs(sets) do
		local items = C_EquipmentSet.GetItemLocations(setid)
		if items then
			for _, locid in pairs(items) do
				local equipped, bank, bags, void, slotnum, bagnum = EquipmentManager_UnpackLocation(locid);
				if bagnum==bag and slotnum==slot then
					return true
				end
			end
		end
	end
	return false
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
	local filter_name = EasyDestroyFilters.GetFilterName()
	local entry_id = EasyDestroyFilters.GetItemID()
	local entry_name = EasyDestroyFilters.GetItemName()
	local itemLevels = EasyDestroyFilters.GetItemLevels()
	
	if not filter_name or filter_name == "" then 
		filter_name = "Filter" .. tostring(EasyDestroyFilters_GetNextFilterID(true))
	end
		
	filterObj.properties.name = filter_name
	filterObj.properties.favorite = EasyDestroyFilters_FavoriteIcon:GetChecked()
	
	if entry_id > 0 then filterObj.filter.id = entry_id end
	if entry_name ~= "" then filterObj.filter.name = entry_name end

	if itemLevels ~= nil then filterObj.filter.level = itemLevels end
	
	for key, value in pairs(Enum.ItemQuality) do
		if EasyDestroyFilters.GetRarityChecked(key) then 
			if filterObj.filter.quality == nil then
				filterObj.filter.quality = {}
			end
			tinsert(filterObj.filter.quality, value)
		end
	end

	
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
	EasyDestroyFilters_ItemID.input:SetText("")
	EasyDestroyFilters_ItemName.input:SetText("")
	EasyDestroyFilters_ItemLevel.inputfrom:SetText("")
	EasyDestroyFilters_ItemLevel.inputto:SetText("")
	EasyDestroyFilters_FavoriteIcon:SetChecked(false);
	for _, v in pairs(EasyDestroyFilters_Rarity.Rarity) do
		v:SetChecked(false)
	end
end

function EasyDestroy_LoadFilter(fid)
	EasyDestroy_ClearFilterFrame()
	EasyDestroy:Debug("Loading Filter", fid)
	local filter = EasyDestroy.Data.Filters[fid]
	EasyDestroyFilters_FilterName.input:SetText(filter.properties.name)
	EasyDestroyFilters_ItemID.input:SetText(filter.filter.id or "")
	EasyDestroyFilters_ItemName.input:SetText(filter.filter.name or "")
	EasyDestroyFilters_FavoriteIcon:SetChecked(filter.properties.favorite)
	if type(filter.filter.level) == "table" then
		EasyDestroyFilters_ItemLevel.inputfrom:SetText(filter.filter.level.levelfrom or "")
		EasyDestroyFilters_ItemLevel.inputto:SetText(filter.filter.level.levelto or "")
	else
		EasyDestroyFilters_ItemLevel.inputfrom:SetText(filter.filter.level or "")
	end
	
	for iqname, iqvalue in pairs(Enum.ItemQuality) do
		if tContains(filter.filter.quality or {}, iqvalue) then 
			local quality = string.lower(iqname)
			if EasyDestroyFilters_Rarity[quality] then
				EasyDestroyFilters_Rarity[quality]:SetChecked(true)
			end
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