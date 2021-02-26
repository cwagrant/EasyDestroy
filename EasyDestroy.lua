
--[[ 
	This file is more about the state and actions of EasyDestroy. Almost an API.

	E.g. "IncludeSearches" means the addon should be currently including searches
	vs. if I were to explicitly check for "GetChecked" that's "less" information
	in that it just tells me whether or not the box is checked.

	The "grand scheme" is that UI should more or less handle the interfacing
	(GetChecked) and this file gives those things meaning when necessary (IncludeSearches)

	As for actions, this file covers more "API" type actions. Mostly for things that don't
	fall into a clean category such as 'Filter', 'Criteria', or 'Item'.

	E.g. "GetBagItems" will create the itemList for all items in the users bags. This information
	is used elsewhere.

	"EasyDestroyCacheID" generates a CacheID for an item based on the bag, slot, quality, and link.




]]

function EasyDestroy:IncludeBlacklists()

	return EasyDestroy.UI.FilterDropDown.BlacklistsCheckbutton:GetChecked()

end

function EasyDestroy:IncludeSearches()

	return EasyDestroy.UI.FilterDropDown.SearchesCheckbutton:GetChecked()

end

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
	local filterRegistry = EasyDestroy.CriteriaRegistry
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
	local filterRegistry = EasyDestroy.CriteriaRegistry

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
	local filterRegistry = EasyDestroy.CriteriaRegistry
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

function EasyDestroy:RegisterCriterion(filter)
    --[[ 
    Register a filter with the addon.
    This should be called by the filters themselves.
    ]]
	local filterKeys = EasyDestroy.Keys(filter)
	if not tContains(filterKeys, 'name') then
		EasyDestroy.Error('Error: Filter criterion found with no name. Unable to register.')
		return
	elseif not tContains(filterKeys, 'key') then 
		EasyDestroy.Error('Error: Filter criterion ' .. filter.name .. ' nunable to load. No key provided.')
		return
	end

	-- We want to generate the frame, but not show them.
	filter:GetFilterFrame()
	filter.frame:Hide()

	EasyDestroy.CriteriaRegistry[filter.key] = filter
	UIDropDownMenu_Initialize(EasyDestroyFilterTypes, EasyDestroy.UI.CriteriaDropdown.Initialize)
end

--[[ This generates our filter table from settings in the EasyDestroyFilters window. ]]
function EasyDestroy:GenerateFilter(fetchNewID)

	-- Needs to updated cached filters or create a brand new filter

	local FilterID = EasyDestroy.UI.GetSelectedFilter() --UIDropDownMenu_GetSelectedValue(EasyDestroyDropDown)
	local filter, ftype
	
	if EasyDestroy.Cache.FilterCache and EasyDestroy.Cache.FilterCache[FilterID] then
		filter = EasyDestroy.Cache.FilterCache[FilterID]
	else
		filter = EasyDestroyFilter:New(EasyDestroy.UI.GetFilterType(), EasyDestroy.UI.GetFilterName())
	end

	local temp = filter:ToTable()
	temp.filter = filter:GetCriteriaFromWindow()

	--filter:LoadCriteriaFromWindow()

	return temp, filter
	
end

function EasyDestroy.FindFilterWithName(filterName)

	-- This could maybe be moved to the filters class? But it's more of a static function

	if EasyDestroy.Data.Filters then
		for fid, filter in pairs(EasyDestroy.Data.Filters) do

			if filter.properties.name == filterName then

				return fid, filter

			end

		end
	end

	return nil
end

function EasyDestroy.UI.Initialize()
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

	EasyDestroy.UI.FilterName:SetLabel("Filter Name:")
	EasyDestroy.UI.SetFavoriteChecked(false)
	EasyDestroy.UI.FilterType:SetLabel("Blacklist")
	UIDropDownMenu_SetWidth(EasyDestroyFilterTypes, EasyDestroyFilterSettings:GetWidth()-50)

	EasyDestroyFilterSettings.FilterName.label:SetText("Filter Name:")
	EasyDestroyFilterSettings.Favorite:SetChecked(false);		
	EasyDestroyFilterSettings.Blacklist.label:SetText("Blacklist")

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