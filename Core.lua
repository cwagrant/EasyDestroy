EasyDestroy = {}
EasyDestroy.Version =  GetAddOnMetadata("EasyDestroy", "version")
EasyDestroy.DebugActive = false
EasyDestroy.AddonName = "EasyDestroy"
EasyDestroy.AddonLoaded = false
EasyDestroy.CurrentFilter = {}
EasyDestroy.FilterChanged = false
EasyDestroy.FilterSaveWarned = false

EasyDestroy.DestroyTypes = {}
EasyDestroy.DestroyTypes.DISENCHANT = "DISENCHANT"
EasyDestroy.DestroyTypes.MILL = "MILL"
EasyDestroy.DestroyTypes.PROSPECT = "PROSPECT"
EasyDestroy.WarnedLootOpen = false
EasyDestroy.DestroyFilters = {}
EasyDestroy.DestroyFilters[EasyDestroy.DestroyTypes.DISENCHANT] = {{itype=LE_ITEM_CLASS_WEAPON, stype=nil}, {itype=LE_ITEM_CLASS_ARMOR, stype=nil}}

ED_FILTER_TYPES = {}
ED_FILTER_TYPE_SEARCH = 1
ED_FILTER_TYPE_BLACKLIST = 2
tinsert(ED_FILTER_TYPES, ED_FILTER_TYPE_SEARCH, 'Search')
tinsert(ED_FILTER_TYPES, ED_FILTER_TYPE_BLACKLIST, 'Blacklist')

ED_ERROR_TYPES = {}
ED_ERROR_NONE = 1
ED_ERROR_NAME = 2
ED_ERROR_FAVORITE = 3
tinsert(ED_ERROR_TYPES, ED_ERROR_NONE, 'None')
tinsert(ED_ERROR_TYPES, ED_ERROR_NAME, 'Name')
tinsert(ED_ERROR_TYPES, ED_ERROR_FAVORITE, 'Favorite')

StaticPopupDialogs["ED_CANT_DISENCHANT_BLACKLIST"] = {
	text = "You cannot disenchant items on the blacklist.|n|nYou are currently editing a blacklist filter.",
	button1 = "Okay",
	timeout = 30,
	whileDead = false,
	hideOnEscape = true,
	preferredIndex = 3,
}


--[[
	EasyDestroy.DestroyFunc.DISENCHANT = {
		{itype=LE_ITEM_CLASS_WEAPON, stype=nil},
		{itype=LE_ITEM_CLASS_ARMOR, stype=nil}
	},
	EasyDestroy.DestroyFunc.MILL = {
		{itype=LE_ITEM_TRADEGOODS, stype=9}
	},
	EasyDestroy.DestroyFunc.PROSPECT = {
		{itype=LE_ITEM_TRADEGOODS, stype=7}
	}
}]]--

EasyDestroy.DestroyAction = EasyDestroy.DestroyTypes.DISENCHANT

local ADDON_NAME = "EasyDestroy";
local ADDON_IS_LOADED = false;

EasyDestroy.DataLoaded = false
EasyDestroy.Data = {}
EasyDestroy.FilterCount = 0
EasyDestroy.EmptyFilter = {filter={}, properties={}}
EasyDestroy.Spells = {
	13262, --Disenchant
}

function pprint(tbl, level)
	local newlevel = level or 0
	newlevel = newlevel + 1
	if type(tbl) ~= "table" then
		print(tbl)
	else
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				print(k)
				pprint(v, newlevel)
			else
				print(string.rep('    ', newlevel), k, v)
			end
		end
	end
end

function EasyDestroy.Debug(...)
	if EasyDestroy.DebugActive then
		print(...)
	end
end

function EasyDestroy:CreateBG(frame, r, g, b)
	local bg = frame:CreateTexture(nil, "BACKGROUND");
	bg:SetAllPoints(true);
	bg:SetColorTexture(r, g, b, 0.5);
end

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

function EasyDestroy.InKeys(checkTable, checkValue)
	for k, v in pairs(checkTable) do
		if k == checkValue then
			return true
		end
	end
	return false
end

function EasyDestroy.Error(txt)
	print(string.format("|cFFFF0000%s|r", txt))
end

function EasyDestroy:UpdateDBFormat(data)
	version, subversion, patch = strsplit(".", EasyDestroy.Version)
	version, subversion, patch = tonumber(version), tonumber(subversion), tonumber(patch)

	if version >=1 and subversion >=2 and patch >=3 then
		if data.Filters ~= nil then
			for k, v in pairs(data.Filters) do
				if v.properties.type == nil then
					v.properties.type = ED_FILTER_TYPE_SEARCH
				end
			end
		end
	end

	return data
end






