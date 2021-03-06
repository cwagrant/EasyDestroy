--[[
	Setup the "Environment"

	Additinally provides a few helper functions
]]

EasyDestroy = {}

EasyDestroy.Version = GetAddOnMetadata("EasyDestroy", "version")
EasyDestroy.Events = LibStub("CallbackHandler-1.0"):New(EasyDestroy)
EasyDestroy.AddonName = "EasyDestroy"
EasyDestroy.DebugActive = true
EasyDestroy.AddonLoaded = false

--[[ Modules ]]
EasyDestroy.Favorites = {}
EasyDestroy.Data = {}
EasyDestroy.UI = {}
EasyDestroy.API = {}
EasyDestroy.CallbackHandler = {}


--[[ Events Setup ]]
--[[
	Events:

	UpdateInventory - fires after bag updates when EasyDestroy is visible.
	UpdateInventoryDelayed - fires after Inventory is updated
	UpdateBlacklist - fires when modifications are made to Item and Session Blacklists
	UpdateCriteria - fires when filter criteria are changed
	UpdateFilters - fires when a filter is saved or deleted

	ED_NEW_CRITERIA_AVAILABLE - fires when criteria are registered
	ED_BLACKLIST_UPDATED - fires when an item as added or removed from the Item or Session Blacklists
	ED_INVENTORY_UPDATED_DELAYED - fires after the users inventory has been updated
	ED_FILTER_CRITERIA_CHANGED - fires when criteria are changed on a filter
	ED_FILTER_LOADED - fires when a filter is loaded
	ED_FILTERS_AVAILABLE_CHANGED - fires when a new filter is saved or an existing filter is deleted

]]
EasyDestroy.Events = LibStub("CallbackHandler-1.0"):New(EasyDestroy)

function EasyDestroy.Events:Call(...)

	-- Simple wrapper around fire that returns itself so that we can chain event firing

	EasyDestroy.Events:Fire(...)

	return self

end

-- This is the name of the frame that filter types attach to for scrolling
EDFILTER_SCROLL_CHILD = "EasyDestroySelectedFiltersScrollChild"

-- Category name for Interface Options menu item
EASY_DESTROY_CATEGORY = "EasyDestroy"

-- Setting up Key Binding capability for the Destroy Button
_G["BINDING_NAME_CLICK EasyDestroyButton:LeftButton"] = "Destroy Button"

-- For making sure item combines aren't called endlessly when the inventory is updating
EasyDestroy.ProcessingItemCombine = false

--[[ Utility Tables/Variables ]]
EasyDestroy.EmptyFilter = { filter={}, properties={} }
EasyDestroy.Cache = { ItemCache = {}, FilterCache = {}}
EasyDestroy.FrameRegistry = {}
EasyDestroy.SessionBlacklist = {}
EasyDestroy.FirstStartup = false
EasyDestroy.PlayerMoving = false

EasyDestroy.Warnings = {}
EasyDestroy.Warnings.LootOpen = false
EasyDestroy.DataLoaded = false

EasyDestroy.CriteriaRegistry = {}
EasyDestroy.CriteriaStack = {}

EasyDestroy.DebugFrame = nil

EasyDestroy.separatorInfo = {
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

-- borrowed from https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
function EasyDestroy.spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

-- table.getn doesn't work if the table has non-integer keys
function GetTableSize(t)
	local count = 0
	for k, v in pairs(t) do
		if k ~= nil then
			count = count + 1
		end
	end
	return count
end

function EasyDestroy.Keys(tbl)
	local rtn = {}
	for k, v in pairs(tbl) do
		tinsert(rtn, k)
	end
	return rtn
end

function EasyDestroy.Error(txt)
	print(string.format("|cFFFF0000%s|r", txt))
end

function EasyDestroy:UpdateDBFormat(data)
	local version, subversion, patch = strsplit(".", EasyDestroy.Version)
	version, subversion, patch = tonumber(version), tonumber(subversion), tonumber(patch)

	if not EasyDestroy.Data.Options and not EasyDestroy.Data.Filters and not EasyDestroy.Data.Blacklist then
		
		-- User has no data saved thus far, presume this is their first time using the addon.
		EasyDestroy.FirstStartup = true

	end

	if (version == 1 and subversion >=2) or (version>=1) then
		if data.Filters ~= nil then
			for k, v in pairs(data.Filters) do
				if v.properties.type == nil then
					v.properties.type = ED_FILTER_TYPE_SEARCH
				end
			end
		end
	end

	if (version == 1 and subversion >= 3)  or (version>=1) then
		if data.Blacklist ~= nil then 
			for k, v in ipairs(data.Blacklist) do
				if v then
					local item = Item:CreateFromItemID(v.itemid)
					item:ContinueOnItemLoad(function()
						if not v.link then v.link = item:GetItemLink() end
						if not v.name then v.name = item:GetItemName() end
					end)
				end
			end
		end
	end

	if (version > 1) then
		if data.Options and data.Options.CharacterFavorites == nil then
			data.Options.CharacterFavorites = false
		end
	end

	if (version > 1) then
		if data.Options and data.Options.Actions == nil then
			data.Options.Actions = EasyDestroy.Enum.Actions.Disenchant
		end
	end

	return data
end






