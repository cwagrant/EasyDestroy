--[[

    Inventory API

    Events
        - UpdateInventory update the inventory cache
        - RestackItems starts the process for restacking items

    Exposed Functions
        - Initialize - should be called before you can do anything, but 
            we use a sort of "lazy initialization" to set this up if anything else is called first.
        - GetInventory
        - ItemNeedsRestacked
        - FindTradegoodInBags

]]

EasyDestroy.Inventory = {}

local playerInventory = {}
local initialized = false
local updatingInventory = false -- don't want to run multiple times at once
local protected = {}

local function FindTradegoods(dict, addToTable)

	-- Find Herbs/Ore based on which Dict is passed. 
	-- Inserts the matches into the passed table.

	-- EasyDestroy.Dict.Ores EasyDestroy.Dict.Herbs

	local item 
	for k, v in ipairs(dict) do
		
		if v.itemid then 
			local _, reagent = GetItemInfo(v.itemid)
			if reagent then 
				local EasyDestroyID = EasyDestroyItem.EasyDestroyCacheID(0, 0, reagent)

				if EasyDestroyID and EasyDestroy.Cache.ItemCache[EasyDestroyID] then
					item = EasyDestroy.Cache.ItemCache[EasyDestroyID]
				else
					item = EasyDestroyItem:New(nil, nil, reagent)
				end

				item.count = GetItemCount(item:GetItemLink(), false)

				if item.count > 4 then 
					tinsert(addToTable, item)					
				end
			end
		end
	end
end

local function GetBagItems(itemList)

    if updatingInventory then return end

    updatingInventory = true

	local filterRegistry = EasyDestroy.CriteriaRegistry

	for bag = 0, NUM_BAG_SLOTS do
		for slot=1, GetContainerNumSlots(bag) do
			local item, EasyDestroyID
			local itemlink = select(7, GetContainerItemInfo(bag, slot))
			
			while (true) do 

				if itemlink then 
					item = EasyDestroyItem:New(bag, slot)
				else 
					break
				end
			
				if item == nil then break end

				if item.classID ~= LE_ITEM_CLASS_ARMOR and item.classID ~= LE_ITEM_CLASS_WEAPON then break end 
				
				if item:GetItemID() and C_Item.IsItemKeystoneByID(item:GetItemID()) then break end

				if item:GetItemLink() then
					item.haveTransmog = item:HaveTransmog()

					for k, v in pairs(filterRegistry) do
						if v.GetItemInfo ~= nil and type(v.GetItemInfo) == "function" then
							item:SetValueByKey(k, v:GetItemInfo(item:GetItemLink(), item.bag, item.slot))
						end
					end
					tinsert(itemList, item)
				end
				break
			end
		end
	end

	FindTradegoods(EasyDestroy.Dict.Herbs, itemList)
	FindTradegoods(EasyDestroy.Dict.Ores, itemList)

    updatingInventory = false

end

local function GetItemsToCombine(item)

	-- Get a list of bag/slot locations for a given item, that can be combined into stacks.

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

local function CombineStacks()

	-- Combine stacks of items onto one another. 

	EasyDestroy.ProcessingItemCombine = true

	EasyDestroy.Debug("EasyDestroy.API.CombineStacks")
	local item 

	while true do 

		-- If the queue has an item and we're not actively combining then grab off queue
		if #API.toCombineQueue > 0 and #API.toCombine == 0 then

			EasyDestroy.Debug("EasyDestroy.API.CombineStacks", "GetItemFromQueue" )
			item = tremove(API.toCombineQueue, 1)
			GetItemsToCombine(item)

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

local function RestackItemsInQueue()

    if not initialized then EasyDestroy.Inventory.Initialize() end

	EasyDestroy.Thread = coroutine.create(CombineStacks)

end

local function UpdateInventory()

    if not initialized then EasyDestroy.Inventory.Initialize() end

    wipe(playerInventory)
    GetBagItems(playerInventory)

	-- fires once the players inventory has been updated

	EasyDestroy.Events:Fire("ED_INVENTORY_UPDATED_DELAYED")

end

function EasyDestroy.Inventory.GetInventory()

    if not initialized then EasyDestroy.Inventory.Initialize() end

    return playerInventory
end

function EasyDestroy.Inventory.ItemNeedsRestacked(item)

    if not initialized then EasyDestroy.Inventory.Initialize() end

	-- Find if at least 2 partial stacks of an item exists

	local incompleteStack = false

	if item and item.maxStackSize then 

		for bag = 0, NUM_BAG_SLOTS do
			for slot=1, GetContainerNumSlots(bag) do
	
				local _, count, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot)

				if item:GetItemID() == itemID and count < item.maxStackSize then
					
                    -- if we already found one partial stack then we've found all we need
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

function EasyDestroy.Inventory.FindTradegoodInBags(item)

    if not initialized then EasyDestroy.Inventory.Initialize() end

    -- finds you the first instance of a tradegood in your bag
    -- TODO: Probably need to make this ignore stacks < 5

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

function EasyDestroy.Inventory.Initialize()

    if initialized then return end

    EasyDestroy.RegisterCallback(EasyDestroy.Inventory, "ED_INVENTORY_UPDATED", UpdateInventory)
    EasyDestroy.RegisterCallback(EasyDestroy.Inventory, "ED_RESTACK_ITEMS", RestackItemsInQueue)

    initialized = true
    UpdateInventory()

end
