
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
EasyDestroy.toCombine = API.toCombine
function EasyDestroy.API.CombineStacks()

	-- Combine stacks of items onto one another. 

	EasyDestroy.ProcessingItemCombine = true

	EasyDestroy.Debug("EasyDestroy.API.CombineStacks")
	local item 

	while true do 

		-- If the queue has an item and we're not actively combining then grab off queue
		if #API.toCombineQueue > 0 and #API.toCombine == 0 then

			EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "GetItemFromQueue" )
			item = tremove(API.toCombineQueue, 1)
			EasyDestroy.API.GetItemsToCombine(item)

		-- if queue is empty and we're not actively combining then end
		elseif #API.toCombineQueue == 0 and #API.toCombine == 0 then
			-- work's done!
			break
		end


		ClearCursor()

		local sourceItem, destItem, sourceCount, destCount

		sourceItem = API.toCombine[#API.toCombine]
		destItem = API.toCombine[1]

		EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "Check Locks", sourceItem.bag, sourceItem.slot, destItem.bag, destItem.slot)
		
		while true do

			local _, count1, locked1 = GetContainerItemInfo(sourceItem.bag, sourceItem.slot)
			local _, count2, locked2 = GetContainerItemInfo(destItem.bag, destItem.slot)

			sourceCount = count1
			destCount = count2
			-- suspend if either item is locked
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

		-- wait for process to finish before we determine what to do next
		EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "Recount Items")
		local finalCount1, finalCount2
		while true do 
			local _, count1, locked1 = GetContainerItemInfo(sourceItem.bag, sourceItem.slot)
			local _, count2, locked2 = GetContainerItemInfo(destItem.bag, destItem.slot)

			finalCount1 = count1
			finalCount2 = count2

			if not locked2 and (locked1 == nil or locked1 == false) then 
				break
			else
				coroutine.yield()
			end
		end

		-- remove completely moved items from table (e.g. whole stack has moved)
		if finalCount1 == nil or finalCount1 < 1 then
			EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "Remove empty slot")
			table.remove(API.toCombine)
		end

		-- remove full stack from table (e.g. our destination stack is full)
		if finalCount2 >= item.maxStackSize then
			EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "Remove full stack", destItem.bag, destItem.slot)
			table.remove(API.toCombine, 1)
		end

		EasyDestroy.Debug(string.format("Count of items Source: %d, Dest: %d, Final: %d", sourceCount, destCount, finalCount2))

		if #API.toCombine <= 1 then
			EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "Clear list", #API.toCombine)
			wipe(API.toCombine)
		end

	end


	EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "Item Combine Completed")
	EasyDestroy.Thread = nil
	EasyDestroy.ProcessingItemCombine = false

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
	UIDropDownMenu_Initialize(EasyDestroyFilterTypes, EasyDestroy.UI.Filters.Initialize_CriteriaDropDown)
end

--[[ This generates our filter table from settings in the EasyDestroyFilters window. ]]
--[[ 2021-02-26 Removed old table, now uses a proper Filter object for downstream work.]]
function EasyDestroy:GenerateFilter()

	-- Needs to updated cached filters or create a brand new filter

	local FilterID = EasyDestroy.UI.Filters.GetSelectedFilter()
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

