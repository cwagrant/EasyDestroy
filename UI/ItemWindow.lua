EasyDestroy.UI.ItemWindowFrame = EasyDestroyItems
EasyDestroy.UI.ItemWindow = EasyDestroyItemsFrame

local ItemWindow = EasyDestroy.UI.ItemWindow
ItemWindow.name = "EasyDestroy.UI.ItemWindow"


local initialized = false
local protected = {}

function protected.Update(event, arg)

    -- Update the Item Window (Item List)

	if ItemWindow:IsVisible(ItemWindow.name) then 

		if arg ~= nil and type(arg) == "table" then 
			EasyDestroy.UI.ItemWindow:ItemListUpdate(arg)
		end

		EasyDestroy.UI.ItemWindow:ScrollUpdate()

		EasyDestroy.UI.ItemCounter:SetText(EasyDestroy.UI.ItemWindow.ItemCount ..  " Item(s) Found")

	end

end

function ItemWindow:RegisterScript(frame, scriptType)

	-- Register a frame's script handler to additionally run the ItemWindow.Update
	-- Should be used by buttons/fields that will update a filter

	if frame:HasScript(scriptType) then
		frame:HookScript(scriptType, ItemWindow.OnCriteriaUpdate)
	else
		error("RegisterScript requires a valid scriptType", 2)
	end

end

function ItemWindow.__init()

	--[[ 
		ED_FILTER_CRITERIA_CHANGED should always send the filter 
		ED_FILTER_LOADED should always send the filter

		ED_INVENTORY_UPDATE_DELAYED will rely on the cached filter
		ED_BLACKLIST_UPDATED will rely on the cached filter
	]]

    if initialized then return end 

    -- EasyDestroy.RegisterCallback(ItemWindow, "UpdateItemWindow", protected.Update)	
	EasyDestroy.RegisterCallback(ItemWindow, "ED_BLACKLIST_UPDATED", protected.Update)
	EasyDestroy.RegisterCallback(ItemWindow, "ED_INVENTORY_UPDATED_DELAYED", protected.Update)

	EasyDestroy.RegisterCallback(ItemWindow, "ED_FILTER_CRITERIA_CHANGED", protected.Update)    
	EasyDestroy.RegisterCallback(ItemWindow, "ED_FILTER_LOADED", protected.Update)

	ItemWindow:Initialize(protected.FindWhitelistItems, 8, 24, protected.ItemOnClick)

    initialized = true

end

function protected.FindWhitelistItems(activeFilter)
	
	-- Applies the current Search(Whitelist) to all items in the users bags.
	
	if activeFilter == nil then return end
	
	-- The old way of getting filter information
	local filter = activeFilter:ToTable()
	filter.filter = EasyDestroy.UI.Filters.GetCriteria()

	local matchfound = nil
	local typematch = false
	local items = {}
	local filterRegistry = EasyDestroy.CriteriaRegistry

	for i, item in ipairs(EasyDestroy.API.Inventory.GetInventory()) do
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

				for k, v in pairs(EasyDestroy.UI.Filters.GetCriteria()) do
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
				if filter.properties.type ~= ED_FILTER_TYPE_BLACKLIST and EasyDestroy.API.Blacklist.HasItem(item) then
					matchfound = false
					break
				end
				
				-- this is a check of blacklist type filters
				if filter.properties.type ~= ED_FILTER_TYPE_BLACKLIST and EasyDestroy.API.Blacklist.InFilterBlacklist(item) then 
					matchfound = false
					break
				end

				break
			end

			if matchfound and typematch then 
				tinsert(items, item)

				-- queue up found trade good items in bags for restacking

				if EasyDestroy.API.Inventory.ItemNeedsRestacked(item) then
					EasyDestroy.Debug("AddItemToQueue", item.itemLink)
					tinsert(API.toCombineQueue, item)
				end

			end
		end
	end
	return items
end


-- ###########################################
-- UI Event Handlers
-- ###########################################

function protected.ItemOnClick(self, button)
	if button == "RightButton" then 
		

		self.item.menu = {
			{ text = self.item:GetItemName(), notCheckable = true, isTitle = true},
			{ text = "Add Item to Blacklist", notCheckable = true, func = function() EasyDestroy.API.Blacklist.AddItem(self.item) end },
			{ text = "Ignore Item for Session", notCheckable = true, func = function() EasyDestroy.API.Blacklist.AddSessionItem(self.item) end},
		}


		EasyMenu(self.item.menu, EasyDestroy.ContextMenu, "cursor", 0, 0, "MENU")
	end
	
end

function ItemWindow.OnCriteriaUpdate()

	-- If our filter was updated, we'll need to tell the system to update.

	EasyDestroy.Events:Call("ED_FILTER_CRITERIA_CHANGED", EasyDestroy.UI.Filters.GenerateFilter())
	-- EasyDestroy.Events:Call("UpdateItemWindow")


end