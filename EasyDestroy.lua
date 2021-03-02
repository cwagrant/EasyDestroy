
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

local API = {}

API.toCombine = {}
API.toCombineQueue = {}

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

				if item.classID ~= LE_ITEM_CLASS_ARMOR and item.classID ~= LE_ITEM_CLASS_WEAPON then break end 
				
				if item:GetItemID() and C_Item.IsItemKeystoneByID(item:GetItemID()) then break end

				if item:GetItemLink() then
					item.haveTransmog = item:HaveTransmog()
					
					-- if item.classID == LE_ITEM_CLASS_TRADEGOODS then
					-- 	item.count = GetItemCount(item.itemLink)
					-- end

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

	EasyDestroy.API.FindTradegoods(EasyDestroy.Dict.Herbs, itemList)
	EasyDestroy.API.FindTradegoods(EasyDestroy.Dict.Ores, itemList)

	-- EasyDestroy.Dict.Ores EasyDestroy.Dict.Herbs

	return itemList
end

function EasyDestroy.API.FindWhitelistItems()
	
	-- Applies the current Search(Whitelist) to all items in the users bags.
	
	local activeFilter = EasyDestroy:GenerateFilter()

	-- The old way of getting filter information
	local filter = activeFilter:ToTable()
	filter.filter = EasyDestroy.UI.GetCriteria()

	local matchfound = nil
	local typematch = false
	local items = {}
	local filterRegistry = EasyDestroy.CriteriaRegistry
	local input = EasyDestroy.GetBagItems() 

	for i, item in ipairs(input) do
		matchfound = nil
		typematch = false

		if item:GetStaticBackingItem() then

			--[[ a way to get "continue" statement functionality from break statements. ]]
			while (true) do

				if item.classID ~= LE_ITEM_CLASS_ARMOR and item.classID ~= LE_ITEM_CLASS_WEAPON and item.count and item.count <= 0 then
					matchfound = false
					break
				end

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

				for k, v in pairs(EasyDestroy.UI.GetCriteria()) do
					if not filterRegistry[k] then
						print("Unsupported filter: " .. k or "UNK")
					else
						if activeFilter:GetType() == ED_FILTER_TYPE_BLACKLIST and filterRegistry[k].Blacklist ~= nil and type(filterRegistry[k].Blacklist) == "function" then
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

				-- A list of actions is generated based on bit flags. 0x00, 0x01, 0x02, 0x04 for none, DE, Mill, and Prospect
				--[[ Filter out types/subtypes that don't matter for the current action ]]--
				-- for k, v in ipairs(ED_ACTION_FILTERS[ED_ACTION_DISENCHANT]) do
				for k, v in ipairs(EasyDestroy.ItemTypeFilterByFlags(EasyDestroy.Data.Options.Actions)) do
					if v.itype == item.classID then
						if not v.stype then
							typematch = true
						elseif v.stype == item.subclassID then
							typematch = true
						end
					end
				end

				if EasyDestroy.API.Blacklist.HasSessionItem(item) then
					matchfound = false
					break
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

				-- queue up found trade good items in bags for restacking

				if EasyDestroy.API.ItemNeedsRestacked(item) then

					EasyDestroy.Debug("AddItemToQueue", item.itemLink)
					tinsert(API.toCombineQueue, item)
				end

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

--[[ 
	Probably the way to handle this will be to actually put itemlinks in the dictionary

	For now this seems to work. Will probably make it so that all herbs and ore come
	through this function and all other item types come the "normal" way. This way
	we can list them a single time w/ the count included.

	Do I want to make it so that the disenchant button gets stuff magically based on 
	if it's possible to mass mill/prospect? I could make a filter criteria for
	"allow regular milling", "allow mass milling". 

	if "allow regular milling" is not checked, then items with a count < 20 won't show

]]

function EasyDestroy.API.FindTradegoods(dict, addToTable)

	-- Find Herbs/Ore based on which Dict is passed. 
	-- Inserts the matches into the passed table.

	-- EasyDestroy.Dict.Ores EasyDestroy.Dict.Herbs

	local item 
	for k, v in ipairs(dict) do
		
		if v.itemid then 
			local _, reagent = GetItemInfo(v.itemid)
			if reagent then 
				local EasyDestroyID = EasyDestroy.EasyDestroyCacheID(0, 0, 1, reagent)

				if EasyDestroyID and EasyDestroy.Cache.ItemCache[EasyDestroyID] then
					item = EasyDestroy.Cache.ItemCache[EasyDestroyID]
				else
					item = EasyDestroyItem:New(nil, nil, reagent)
				end

				item.count = GetItemCount(item:GetItemLink(), false)

				-- placeholder, will need to look to see if mass destroying/regular destroying are enabled and handle approrpiately
				if item.count > 4 then 
					tinsert(addToTable, item)					
				end
			end
		end
	end
end

function EasyDestroy.API.ItemNeedsRestacked(item)

	-- Find if at least 2 partial stacks of an item exists

	local incompleteStack = false

	if item and item.maxStackSize then 

		for bag = 0, NUM_BAG_SLOTS do
			for slot=1, GetContainerNumSlots(bag) do
	
				local _, count, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot)

				if item:GetItemID() == itemID and count < item.maxStackSize then
					
					if incompleteStack then
						return true
					end

					incompleteStack = true

				end
			end
	
		end

	end

	return false

end


function EasyDestroy.API.GetDestroyActionForItem(item)

	if item then 
		if item.classID == LE_ITEM_CLASS_ARMOR or item.classID == LE_ITEM_CLASS_WEAPON then
			return EasyDestroy.Enum.Actions.Disenchant
		elseif item.classID == LE_ITEM_CLASS_TRADEGOODS and item.subclassID == 7 then
			return EasyDestroy.Enum.Actions.Prospect
		elseif item.classID == LE_ITEM_CLASS_TRADEGOODS and item.subclassID == 9 then
			return EasyDestroy.Enum.Actions.Mill
		end
	end

	return nil

end

function EasyDestroy.API.FindTradegoodInBags(item)

	for bag = 0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do

			local itemID = select(10, GetContainerItemInfo(bag, slot))

			if item:GetItemID() == itemID then
				return bag, slot, GetItemCount(itemID, false)
			end
		end

	end

	return nil

end

function EasyDestroy.API.CombineItemsInQueue()

	-- Called when doing filter change updates so that if an item that is included in the
	-- current search needs to be restacked, it gets restacked.

	EasyDestroy.Thread = coroutine.create(EasyDestroy.API.CombineStacks)

end



function EasyDestroy.API.GetItemsToCombine(item)

	-- Get a list of items, for a given item, that can be combined into stacks.


	for bag = 0, NUM_BAG_SLOTS do

		for slot=1, GetContainerNumSlots(bag) do

			local _, count, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot)

			if itemID == item.itemID then 

				if count < item.maxStackSize then 
					tinsert(API.toCombine, {bag=bag, slot=slot})
				end
			end
		end
	end

	
end
	
EasyDestroy.toCombineQueue = API.toCombineQueue

function EasyDestroy.API.CombineStacks()

	-- Combine stacks of items onto one another. 

	EasyDestroy.ProcessingItemCombine = true

	EasyDestroy.Debug("EasyDestroy.API.CombineStacks")
	local item 
	while true do 

		if #API.toCombineQueue > 0 and #API.toCombine == 0 then

			EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "GetItemFromQueue" )
			item = tremove(API.toCombineQueue, 1)
			EasyDestroy.API.GetItemsToCombine(item)

		elseif #API.toCombineQueue == 0 and #API.toCombine == 0 then

			EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "Close")
			break

		end


		ClearCursor()

		local sourceItem, destItem 
		while true do

			sourceItem = API.toCombine[#API.toCombine]
			destItem = API.toCombine[1]

			local _, _, locked1 = GetContainerItemInfo(sourceItem.bag, sourceItem.slot)
			local _, _, locked2 = GetContainerItemInfo(destItem.bag, destItem.slot)

			if locked1 or locked2 then
				coroutine.yield()
			else
				break
			end

		end

		EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "CombineItems")
		PickupContainerItem(sourceItem.bag, sourceItem.slot)
		PickupContainerItem(destItem.bag, destItem.slot)

		ClearCursor()

		local _, count = GetContainerItemInfo(destItem.bag, destItem.slot)

		table.remove(API.toCombine) -- pop

		if count >= item.maxStackSize then
			table.remove(API.toCombine, 1)
		end

		EasyDestroy.Debug(string.format("Count of items %d", #API.toCombine))

		EasyDestroy.Debug(#API.toCombine)
		if #API.toCombine <= 1 then
			EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "Clear list", #API.toCombine)
			wipe(API.toCombine)
			coroutine.yield()
		else
			EasyDestroy.Debug(#API.toCombine)
			coroutine.yield()
		end

	end

	EasyDestroy.Thread = nil
	EasyDestroy.ProcessingItemCombine = false

end

function EasyDestroy.API.DestroyItem(item)

	EasyDestroy.Debug("EasyDestroy.API.DestroyItem", item.itemLink)

	local action = EasyDestroy.API.GetDestroyActionForItem(item)

	if action then

		local ActionDict = EasyDestroy.Dict.Actions[action]
		local spellname = GetSpellInfo(ActionDict.spellID)

		local bag, slot = EasyDestroy.API.FindTradegoodInBags(item)

		EasyDestroyButton:SetAttribute("*type1", "macro")
		EasyDestroyButton:SetAttribute("macrotext", string.format(EasyDestroy.Dict.Strings.DestroyMacro, spellname, bag, slot))

	end

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

	filter:Initialize()

	if filter and filter.scripts then 
		for scriptType, frames in pairs(filter.scripts) do

			for _, frame in ipairs(frames) do
				EasyDestroy.UI.ItemWindow:RegisterScript(frame, scriptType)

			end
			
		end
	end


	EasyDestroy.CriteriaRegistry[filter.key] = filter
	UIDropDownMenu_Initialize(EasyDestroyFilterTypes, EasyDestroy.UI.CriteriaDropdown.Initialize)
end

--[[ This generates our filter table from settings in the EasyDestroyFilters window. ]]
--[[ 2021-02-26 Removed old table, now uses a proper Filter object for downstream work.]]
function EasyDestroy:GenerateFilter()

	-- Needs to updated cached filters or create a brand new filter

	local FilterID = EasyDestroy.UI.GetSelectedFilter()
	local filter, ftype
	
	if EasyDestroy.Cache.FilterCache and EasyDestroy.Cache.FilterCache[FilterID] then
		filter = EasyDestroy.Cache.FilterCache[FilterID]
	else
		filter = EasyDestroyFilter:New(EasyDestroy.UI.GetFilterType(), EasyDestroy.UI.GetFilterName())
	end

	return filter
	
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

EasyDestroy.API.Blacklist = {}

function EasyDestroy.API.Blacklist.AddSessionItem(item)
	
	tinsert(EasyDestroy.SessionBlacklist, item:ToTable())

	EasyDestroy.UI.ItemWindow.Update()
	EasyDestroy.UI.UpdateBlacklistWindow()

end

function EasyDestroy.API.Blacklist.HasSessionItem(item)
	EasyDestroy.Debug("EasyDestroy.API.Blacklist.HasSessionItem", item:GetItemName(), item.itemID)

    for k, v in ipairs(EasyDestroy.SessionBlacklist) do
        -- if regular item, match on itemid, quality, ilvl
        -- if legendary item, match on itemid and name
        if v and ((v.itemid == item.itemID and v.quality == item.quality and v.ilvl == item.level) or (v.legendary and v.itemid==item.itemID and v.legendary==item:GetItemName())) then
            return true
        end
    end

	return false
end

function EasyDestroy.API.Blacklist.AddItem(item)
	
	tinsert(EasyDestroy.Data.Blacklist, item:ToTable())

	EasyDestroy.UI.ItemWindow.Update()
	EasyDestroy.UI.UpdateBlacklistWindow()

end

function EasyDestroy.API.Blacklist.HasItem(item)
	EasyDestroy.Debug("EasyDestroy.API.GetItemInBlacklist", item:GetItemName(), item.itemID)

    for k, v in ipairs(EasyDestroy.Data.Blacklist) do
        -- if regular item, match on itemid, quality, ilvl
        -- if legendary item, match on itemid and name
        if v and ((v.itemid == item.itemID and v.quality == item.quality and v.ilvl == item.level) or (v.legendary and v.itemid==item.itemID and v.legendary==item:GetItemName())) then
            return true
        end
    end

	return false
end

function EasyDestroy.API.Blacklist.RemoveItem(item)
	for k, v in ipairs(EasyDestroy.Data.Blacklist) do
        -- if regular item, match on itemid, quality, ilvl
        -- if legendary item, match on itemid and name
        if v and ((v.itemid == item.itemID and v.quality == item.quality and v.ilvl == item.level) or (v.legendary and v.itemid==item.itemID and v.legendary==item:GetItemName())) then
            tremove(EasyDestroy.Data.Blacklist, k)
			EasyDestroy.UI.ItemWindow.Update()
			EasyDestroy.UI.UpdateBlacklistWindow()
        end
    end
end

function EasyDestroy.UI.ItemOnClick(self, button)
	if button == "RightButton" then 
		

		self.item.menu = {
			{ text = self.item:GetItemName(), notCheckable = true, isTitle = true},
			{ text = "Add Item to Blacklist", notCheckable = true, func = function() EasyDestroy.API.Blacklist.AddItem(self.item) end },
			{ text = "Ignore Item for Session", notCheckable = true, func = function() EasyDestroy.API.Blacklist.AddSessionItem(self.item) end},
		}


		EasyMenu(self.item.menu, EasyDestroy.ContextMenu, "cursor", 0, 0, "MENU")
	end
	
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

