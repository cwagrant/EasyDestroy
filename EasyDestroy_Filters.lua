--[[
Not really sure how I want to make this work. I would like for a filter to be
highly customizable. E.g. ITEMNAME(list of item names) AND ITEMID(list of item ids)
would mean that an item must at least be a partial match of an itemname and the itemid
would be in the list of itemids.

ITEMID(list) AND ITEMQUALITY(list)
(ITEMQUALITY(list) AND ITEMID(list) OR ITEMQUALITY(list) AND ITEMID(list)) -- i want all rare bracers X and uncommon belts Y

will need to do setfenv to EasyDestroyFilters.Environment and then pcall the filters

]]--

EasyDestroyFilters = {}

EasyDestroyFilters.Object = {}



function EasyDestroyFilters:RegisterFilter(filterKey, filterFunction)
	EasyDestroyFilters.FilterRegistry[filterKey] = filterFunction
end

EasyDestroyFilters:RegisterFilter("id", EasyDestroyFilters.ItemID)
EasyDestroyFilters:RegisterFilter("name", EasyDestroyFilters.ItemID)
EasyDestroyFilters:RegisterFilter("quality", EasyDestroyFilters.ItemID)


function EasyDestroyFilters:ItemID(...)
	local argcount = select("#", ...)
	local itemID = EasyDestroyFilters.Object.itemID
	
	if argcount == 0 then
		error("No numbers provided for comparison.")
	end
	
	if type(itemID) ~= "number" then
		error("ItemID is not a number")
	end
	
	for i=1, argcount do
		local arg = select(i, ...)
		
		if not arg then
			error("Argument is nil")
		end
		
		if type(arg) == "number" then
			if itemID and itemID == arg then
				return true
			end
		elseif type(arg) == "string" then
			local n = string.tonumber(arg)
			if itemID and itemID == n then
				return true
			end
		else
			error("Argument is not a number or string")
		end
	end
	
	return false
end

function EasyDestroyFilters:ItemName(...)
	local argcount = select("#", ...)
	local itemName = string.lower(EasyDestroyFilters.Object.itemName)
	
	if argcount == 0 then
		error("No item names provided for comparison.")
	end
	
	if type(itemName) ~= "string" then
		error("Item name is not a string")
	end
	
	for i=1, argcount do
		local arg = select(i, ...)
		
		if not arg then
			error("Argument is nil")
		end
		
		if type(arg) ~= "string" then
			error("Item name is not a string")
		end
		
		if itemName and itemName == string.lower(arg) then
			return true
		end
	end
	
	return false
end

function EasyDestroyFilters:ItemQuality(...)
	local argcount = select('#', ...)
	local itemQuality = EasyDestroyFilters.Object.itemQuality
	
	if argcount == 0 then
		error("No item quality provided for comparison.")
	end
	
	if type(itemQuality) ~= "number" then
		error("Item quality is not a number")
	end
	
	for i=1, argcount do
		local arg = select(i, ...)
		
		if not arg then
			error("Argument is nil")
		end
		
		if type(arg) ~= "number" then
			error("Item quality is not a number")
		end
		
		if itemQuality and itemQuality == arg then
			return true
		end
	end
	
	return false
end

function EasyDestroyFilters:ItemType(...)
	local argcount = select('#', ...)
	local itemType = EasyDestroyFilters.Object.itemType
	
	if argcount == 0 then
		error("No item type provided for comparison.")
	end
	
	if type(itemQuality) ~= "number" then
		error("Item type is not a number")
	end
	
	for i=1, argcount do
		local arg = select(i, ...)
		
		if not arg then
			error("Argument is nil")
		end
		
		if type(arg) ~= "number" then
			error("Item quality is not a number")
		end
		
		if itemQuality and itemQuality == arg then
			return true
		end
	end
	
	return false
end




EasyDestroyFilters.Environment = {
	itemid = EasyDestroyFilters.ItemID,
	itemname = EasyDestroyFilters.ItemName,
	quality = EasyDestroyFilters.ItemQuality,
	type = EasyDestroyFilters.ItemType,
	subtype = EasyDestroyFilters.ItemSubType
}