--Addon settings
EasyDestroy = EasyDestroy

--local GetItemInfo, GetContainerItemInfo, GetContainerItemID = GetItemInfo, GetContainerItemInfo, GetContainerItemID

local separatorInfo = {
	owner = EasyDestroyDropDown;
	hasArrow = false;
	dist = 0;
	isTitle = true;
	isUninteractable = true;
	notCheckable = true;
	iconOnly = true;
	icon = "Interface\\Common\\UI-TooltipDivider-Transparent";
	tCoordLeft = 0;
	tCoordRight = 1;
	tCoordTop = 0;
	tCoordBottom = 1;
	tSizeX = 0;
	tSizeY = 8;
	tFitDropDownSizeX = true;
	iconInfo = {
		tCoordLeft = 0,
		tCoordRight = 1,
		tCoordTop = 0,
		tCoordBottom = 1,
		tSizeX = 0,
		tSizeY = 8,
		tFitDropDownSizeX = true
	},
};

function EasyDestroy_InitDropDown()
	local info = UIDropDownMenu_CreateInfo()
	local favoriteID = nil
	info.text, info.value, info.checked, info.func, info.owner = EasyDestroy.Strings.FilterSelectionDropdownNew, 0, false, EasyDestroy_DropDownSelect, EasyDestroyDropDown
	UIDropDownMenu_AddButton(info)
	local hasSeparator = false
	local includeSearches, includeBlacklists = EasyDestroy:IncludeSearches(), EasyDestroy:IncludeBlacklists()

	-- This monstrosity sorts by type=type and name<name or type<type
	-- e.g. if types match, sort by name, otherwise sort by type
	if EasyDestroy.Data.Filters then
		for fid, filter in EasyDestroy.spairs(EasyDestroy.Data.Filters, function(t, a, b) return (t[a].properties.type == t[b].properties.type and t[a].properties.name:lower() < t[b].properties.name:lower()) or t[a].properties.type < t[b].properties.type end) do
			info.text, info.value, info.checked, info.func, info.owner = filter.properties.name, fid, false, EasyDestroy_DropDownSelect, EasyDestroyDropDown

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
					UIDropDownMenu_AddButton(separatorInfo)
					hasSeparator = true
				end
				UIDropDownMenu_AddButton(info)
			end
		end
	end
end

function EasyDestroySearchTypes_OnClick()
	EasyDestroy_InitDropDown()
	local favoriteID = EasyDestroy_GetFavorite()

	if not(EasyDestroy:IncludeSearches()) and not(EasyDestroy:IncludeBlacklists()) then
		UIDropDownMenu_SetText(EasyDestroyDropDown, 'You must select at least one type of filter.')
	elseif EasyDestroy:IncludeSearches() and favoriteID then
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, favoriteID)
		EasyDestroy_LoadFilter(favoriteID)
		EasyDestroy_Refresh()
	else
		UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, 0)
	end
end

--[[
	EasyDestroy.Cache.ItemCache {
		[bag:slot:quality:itemLink] = item
	}
]]

function EasyDestroy.EasyDestroyCacheID(bag, slot, quality, link)
	
	-- Create Cache ID from bag, slot, quality, and item link

	if type(bag) ~= "number" or type(slot) ~= "number" or type(quality) ~= "number" or type(link) ~= "string" then 
		error(
			string.format("Usage: EasyDestroy.EasyDestroyCacheID(bag, slot, itemQuality, itemLink)\n (%s, %s, %s, %s)", bag or "nil", slot or "nil", quality or "nil", link or "nil")
		)
	end
	return string.format("%i:%i:%i:%s", bag, slot, quality, link)

end


function EasyDestroy.GetBagItems()

	-- Creates a list of items in the users bags and caches the items.

	local itemList = {}
	local filterRegistry = EasyDestroyFilters.Registry
	local cachedItem = false

	for bag = 0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do
			local item, EasyDestroyID
			local quality, _, _, itemlink = select(4, GetContainerItemInfo(bag, slot))
			
			if itemlink then 
				EasyDestroyID = EasyDestroy.EasyDestroyCacheID(bag, slot, quality, itemlink)
			end

			if EasyDestroyID and EasyDestroy.Cache.ItemCache[EasyDestroyID] then 
				item = EasyDestroy.Cache.ItemCache[EasyDestroyID]
				tinsert(itemList, item)
				cachedItem = true
			else
				item = EasyDestroyItem:New(bag, slot)
				cachedItem = false
			end

			while (true) do 
				if item == nil then break end

				if cachedItem then break end
				
				if item:GetItemID() and C_Item.IsItemKeystoneByID(item:GetItemID()) then break end

				if item:GetItemLink() then
					item.haveTransmog = item:HaveTransmog()

					for k, v in pairs(filterRegistry) do
						if v.GetItemInfo ~= nil and type(v.GetItemInfo) == "function" then
							item:SetValueByKey(k, v:GetItemInfo(item:GetItemLink(), item.bag, item.slot))
						end
					end
					EasyDestroy.Cache.ItemCache[EasyDestroyID] = item
					tinsert(itemList, item)
				end
				break
			end
		end
	end
	return itemList
end

local function FindWhitelistItems()
	
	-- Applies the current Search(Whitelist) to all items in the users bags.
	
	local filter = EasyDestroy.CurrentFilter
	local matchfound = nil
	local typematch = false
	local items = {}
	local filterRegistry = EasyDestroyFilters.Registry

	for i, item in ipairs(EasyDestroy.GetBagItems()) do
		matchfound = nil
		typematch = false

		if item:GetStaticBackingItem() then

			--[[ a way to get "continue" statement functionality from break statements. ]]
			while (true) do

				-- Ignore items that are junk or > legendary.
				if item.quality and (item.quality < Enum.ItemQuality.Common or item.quality > Enum.ItemQuality.Epic) then
					matchfound = false
					break
				end

				-- can't typically disenchant cosmetic items. This filters them out (hopefully)
				-- Not sure about cosmetic weapons...
				if item.classID==LE_ITEM_CLASS_ARMOR and item.subclassID == LE_ITEM_ARMOR_COSMETIC then
					matchfound = false
					break
				end

				--[[ 
					If we're editing a filter/blacklist then we want to show the items it would catch.
						However if we're looking at a blacklist and the filter has a special blacklist function we use that.
						A "blacklist" function is essentially an inverse of the "check", but to make sure we can handle
						any weird situations that could crop  up in the future, it's a special function rather than just
						a direct inversion (not) of the check.

					If we're editing a filter/whitelist then we want to show the items it would catch.
				]]
				for k, v in pairs(filter.filter) do
					if not filterRegistry[k] then
						print("Unsupported filter: " .. k)
					else
						if filter.properties.type == ED_FILTER_TYPE_BLACKLIST and filterRegistry[k].Blacklist ~= nil and type(filterRegistry[k].Blacklist) == "function" then
							if not filterRegistry[k]:Blacklist(v, item) then
								matchfound = false
								break
							end
						elseif not filterRegistry[k]:Check(v, item) then
							matchfound = false
							break
						end	
					end
					matchfound = true
				end
				
				if not matchfound then break end

				--[[ Filter out types/subtypes that don't matter for the current action ]]--
				for k, v in ipairs(ED_ACTION_FILTERS[ED_ACTION_DISENCHANT]) do
					if v.itype == item.classID then
						if not v.stype then
							typematch = true
						elseif v.stype == item.subclassID then
							typematch = true
						end
					end
				end
				

				if not typematch then break end

				-- this is a check of the "item" blacklist
				if filter.properties.type ~= ED_FILTER_TYPE_BLACKLIST and EasyDestroy.ItemInBlacklist(item.itemID, item:GetItemName(), item.quality, item.level) then
					matchfound = false
					break
				end
				
				-- this is a check of blacklist type filters
				if filter.properties.type ~= ED_FILTER_TYPE_BLACKLIST and EasyDestroy:InFilterBlacklist(item) then 
					matchfound = false
					break
				end

				break
			end

			if matchfound and typematch then 
				tinsert(items, item)
			end
		end
	end
	return items
end

-- Unlike the whitelist, where an item just needs to fail at least one criteria (or)
-- the blacklist needs to fail an item based on all the criteria (and).
--[[
	for each blacklist:
	- reset the criteriaTable
	- if item matches a filter, insert true
	- if item fails to match a filter, insert false
	- if there are no false values in criteriaTable, an item matches the blacklist
	- if the item matches ANY blacklist, then the item is excluded (return true)
]]
function EasyDestroy:InFilterBlacklist(item)
	local filterRegistry = EasyDestroyFilters.Registry
	local criteriaTable = {}
	local matchesAny = false
	for fid, blacklist in pairs(EasyDestroy.Data.Filters) do
		if blacklist.properties.type == ED_FILTER_TYPE_BLACKLIST then
			wipe(criteriaTable)
			for k, v in pairs(blacklist.filter) do
				if filterRegistry[k].Blacklist ~= nil and type(filterRegistry[k].Blacklist == "function") then
					if filterRegistry[k]:Blacklist(v, item) then
						tinsert(criteriaTable, true)
					else
						tinsert(criteriaTable, false)
					end
				elseif filterRegistry[k]:Check(v, item) then
					--print(blacklist.properties.name, filterRegistry[k].name, v, item.link)
					tinsert(criteriaTable, true)
				else
					tinsert(criteriaTable, false)			
				end
			end
			if not tContains(criteriaTable, false) then 
				matchesAny = true	
			end
		end
		-- short circuit on a match
		if matchesAny then
			return true
		end
	end
	return matchesAny
end

function EasyDestroy:DisenchantItem()

	-- The actual process for disenchanting an item.
	if not EasyDestroyFrame:IsVisible() then
		EasyDestroyFrame:Show()
		return
	end

	local iteminfo = EasyDestroyItemsFrameItem1.item or nil
	local bag, slot
	
	if iteminfo ~= nil then
		bag, slot = iteminfo.bag, iteminfo.slot	
	end
	
	if not IsSpellKnown(13262) then
		print ("You must have disenchanting to disenchant this item.")
		return
	elseif EasyDestroyFilterSettings.Blacklist:GetChecked() then
		StaticPopup_Show("ED_CANT_DISENCHANT_BLACKLIST")
		return
	elseif not IsUsableSpell(13262) then
		print("You cannot disenchant that item right now.")
		return
	elseif #GetLootInfo() > 0 then
		if not EasyDestroy.Warnings.LootOpen then
			print("Unable to disenchant while loot window is open.")
				EasyDestroy.Warnings.LootOpen = true
			-- lets only warn people every so often, don't want to fill their chat logs if they spam click.
			C_Timer.After(30, function()
				EasyDestroy.Warnings.LootOpen = false
			end
			)
		end
		return
	elseif IsCurrentSpell(13262) then
		-- fail quietly as they are already casting
		return
	elseif iteminfo == nil then
		return
	end

	local spellname = GetSpellInfo(13262)
		
	if(GetContainerItemInfo(bag, slot) ~= nil)then
		EasyDestroy.Debug(format("Disenchanting item at (bag, slot): %d %d", bag, slot))
		EasyDestroyButton:SetAttribute("*type1", "macro")
		EasyDestroyButton:SetAttribute("macrotext", format("/cast %s\n/use %d %d", spellname, bag, slot))
	end	
	-- Disable the button while we process the item being destroyed.
	-- We'll reenable it when we update the item scroll frame via a
	-- callback
	EasyDestroyButton:Disable()
end

function EasyDestroy:IncludeBlacklists()
	return EasyDestroyFrameSearchTypes.Blacklist:GetChecked()
end

function EasyDestroy:IncludeSearches()
	return EasyDestroyFrameSearchTypes.Search:GetChecked()
end

function EasyDestroy:SelectAllFilterTypes()
	EasyDestroyFrameSearchTypes.Blacklist:SetChecked(true)
	EasyDestroyFrameSearchTypes.Search:SetChecked(true)
end

-- Function of the window drop down, moved from Main.
function EasyDestroy_DropDownSelect(self, arg1, arg2, checked)
	EasyDestroy.Debug("SetSelectedValue", self.value)
	UIDropDownMenu_SetSelectedValue(EasyDestroyDropDown, self.value)
	if self.value == 0 then
		EasyDestroy_ClearFilterFrame()
		EasyDestroy_ResetFilterStack()
		EasyDestroy.CurrentFilter = EasyDestroy.EmptyFilter
	else
		EasyDestroy_LoadFilter(self.value)
		EasyDestroy.CurrentFilter = EasyDestroy.Data.Filters[self.value]
		EasyDestroy.CurrentFilter.fid = self.value
	end
	EasyDestroy_Refresh()
end

function EasyDestroy:Initialize()
	--[[ Title Bar ]]--
	EasyDestroyFrame.Title:SetFontObject("GameFontHighlight");
	EasyDestroyFrame.Title:SetText("Easy Destroy");		
	
	--[[ Frame Movement Information ]]--
	EasyDestroyFrame.TitleBar:EnableMouse(true)
	EasyDestroyFrame.TitleBar:SetScript("OnMouseDown", function(self, button)
	  if button == "LeftButton" and not EasyDestroyFrame.isMoving then
	   EasyDestroyFrame:StartMoving();
	   EasyDestroyFrame.isMoving = true;
	  end
	end)
	EasyDestroyFrame.TitleBar:SetScript("OnMouseUp", function(self, button)
	  if button == "LeftButton" and EasyDestroyFrame.isMoving then
	   EasyDestroyFrame:StopMovingOrSizing();
	   EasyDestroyFrame.isMoving = false;
	  end
	end)
	EasyDestroyFrame.TitleBar:SetScript("OnHide", function(self)
	  if ( EasyDestroyFrame.isMoving ) then
	   EasyDestroyFrame:StopMovingOrSizing();
	   EasyDestroyFrame.isMoving = false;
	  end
	end)
	
	--[[ Item View Scrolling Area ]]--
	EasyDestroyItems:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize=16,
		tile=true, 
		tileEdge=false, 
		insets={left=4, right=4, top=4, bottom=4}
	})

	EasyDestroySelectedFilters:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", 
		edgeSize=8,
		tile=true, 
		tileEdge=false, 
		insets={left=4, right=4, top=4, bottom=4}
	})

	EasyDestroyItems:SetBackdropColor(0,0,0,0.5)
	EasyDestroySelectedFilters:SetBackdropColor(0,0,0,0.5)
		
	EasyDestroyFrameSearchTypes.Search.label:SetText("Searches")
	EasyDestroyFrameSearchTypes.Search:SetChecked(true)
	EasyDestroyFrameSearchTypes.Blacklist.label:SetText("Blacklists")

	--[[ Filter View Area ]]--
	UIDropDownMenu_SetWidth(EasyDestroyDropDown, EasyDestroyDropDown:GetWidth()-40)
		
	--[[ Test Button for debugging various information ]]--
	EasyDestroy.EasyDestroyTest = CreateFrame("Button", "EDTest", EasyDestroyFrame, "UIPanelButtonTemplate")
	EasyDestroy.EasyDestroyTest:SetSize(80, 22)
	EasyDestroy.EasyDestroyTest:SetPoint("BOTTOMLEFT", EasyDestroyFrame, "TOPLEFT", 0, 4)
	EasyDestroy.EasyDestroyTest:SetText("Test")
	EasyDestroy.EasyDestroyTest:SetScript("OnClick", function(self)
		print("CountItemsFound", #FindWhitelistItems() or 0)
		print("Filter", UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown))
		print("Filter ID", EasyDestroyFilters.CurrentFilterID)
		pprint(EasyDestroy.CurrentFilter)
	end)
	
	if EasyDestroy.DebugActive then
		EasyDestroy.EasyDestroyTest:Show()
	else
		EasyDestroy.EasyDestroyTest:Hide()
	end

    EasyDestroyItemsFrame:Initialize(FindWhitelistItems, 8, 24, nil)
	
	EasyDestroyItemsFrame.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        EasyDestroyItemsFrame:OnVerticalScroll(offset)
        --EasyDestroy.FilterChanged = true
    end)

end

function EasyDestroy_SaveOptionValue(key, val)
	if EasyDestroy.Data and EasyDestroy.Data.Options then
		EasyDestroy.Data.Options[key] = val
	end
end

function EasyDestroy_GetOptionValue(key)
	if EasyDestroy.Data and EasyDestroy.Data.Options then
		if EasyDestroy.Data.Options[key] ~= nil then
			return EasyDestroy.Data.Options[key]
		else
			return nil
		end
	end
	return nil
end