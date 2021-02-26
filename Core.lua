EasyDestroy = {}

--[[
	TODO:
	Want to move everything over to these Enum's/Dicts.
	Want to move UI related functionality into a single file and/or structure.
	   e.g. EasyDestroy.UI.GetFilterName(), EasyDestroy.UI.<Button>Onclick, EasyDestroy.UI.Initialize()

	Clarify Whitelist v Blacklist v Filter Criteria (previously Filter Types). 

	Setup EasyDestroyButton to do Disenchants, Milling, and Prospecting.
		 - This will require an addition to the UI where a user can select the Destroy Action for a filter.
		 - Destroy Actions will determine what items show up for the user.
		 - What about stacking? Do we count all of the items together as one? Is there some kind of cleanup
		 for when they have odd numbers? What about mass milling/mass prospecting?
		 	- Maybe need some kind of "right click> temporary ignore" for the ItemWindow?
]]

--[[ Modules ]]
EasyDestroy.Favorites = {}
EasyDestroyFilters = {} -- Until 2.0 this was a frame
EasyDestroy.Enum = {}
EasyDestroy.Dict = {}
EasyDestroy.Data = {}
EasyDestroy.UI = {}
EasyDestroy.Handlers = {}

--[[ Settings/Info ]]
EasyDestroy.Version =  GetAddOnMetadata("EasyDestroy", "version")
EasyDestroy.DebugActive = false
EasyDestroy.AddonName = "EasyDestroy"
EasyDestroy.AddonLoaded = false
-- This is the name of the frame that filter types attach to for scrolling
EDFILTER_SCROLL_CHILD = "EasyDestroySelectedFiltersScrollChild"

--[[ Utility Tables/Variables ]]
EasyDestroy.CurrentFilter = {}
EasyDestroy.EmptyFilter = { filter={}, properties={} }
EasyDestroy.Cache = { ItemCache = {}, FilterCache = {}}
EasyDestroy.FrameRegistry = {}

EasyDestroy.FilterChanged = false
EasyDestroy.UpdateSkin = false
EasyDestroy.PlayerMoving = false

EasyDestroy.Warnings = {}
EasyDestroy.Warnings.LootOpen = false
EasyDestroy.WarnedLootOpen = false
EasyDestroy.DataLoaded = false

EasyDestroy.CriteriaRegistry = {}
EasyDestroy.CriteriaStack = {}


--[[ Enumerations/Lookup Tables ]]
EasyDestroy.Enum.FilterTypes = { Search=1, Blacklist=2 }
EasyDestroy.Enum.Errors = { None=1, Name=2, Favorite=3 }

EasyDestroy.Dict.Strings = {}
EasyDestroy.Dict.Strings.CriteriaSelectionDropdown = "Select filter criteria..."
EasyDestroy.Dict.Strings.FilterSelectionDropdownNew = "New filter..."

EasyDestroy.Dict.Actions = {}
EasyDestroy.Dict.Actions.Disenchant = {
	spellID = 13262,
	itemTypes = {{itype=LE_ITEM_CLASS_WEAPON, stype=nil}, {itype=LE_ITEM_CLASS_ARMOR, stype=nil}},
}

EasyDestroy.Dict.Actions.Mill = {
	spellID = 0,
	itemTypes = {{itype=LE_ITEM_CLASS_TRADEGOODS, stype=9}},
}

EasyDestroy.Dict.Actions.Prospect = {
	spellID = 0,
	itemTypes = {{itype=LE_ITEM_CLASS_TRADEGOODS, stype=7}},
}

-- ED_ACTION_FILTERS contains the different types of actions.
-- Additionally, each of those points to a table that is the 
-- basic item class/subclass filter for those actions.
ED_ACTION_FILTERS = {}
ED_ACTION_DISENCHANT = 1
ED_ACTION_MILL = 2
ED_ACTION_PROSPECT = 3

tinsert(ED_ACTION_FILTERS, ED_ACTION_DISENCHANT, {{itype=LE_ITEM_CLASS_WEAPON, stype=nil}, {itype=LE_ITEM_CLASS_ARMOR, stype=nil}})
tinsert(ED_ACTION_FILTERS, ED_ACTION_MILL, {{itype=LE_ITEM_CLASS_TRADEGOODS, stype=9}})
tinsert(ED_ACTION_FILTERS, ED_ACTION_PROSPECT, {{itype=LE_ITEM_CLASS_TRADEGOODS, stype=7}})


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

function EasyDestroy.RegisterFrame(frame, ftype)
    if EasyDestroy.FrameRegistry then
		if not EasyDestroy.FrameRegistry[ftype] then print("unable to find", ftype) end
        EasyDestroy.FrameRegistry[ftype] = EasyDestroy.FrameRegistry[ftype] or {}
        tinsert(EasyDestroy.FrameRegistry[ftype], frame)
    end
end

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
		print(date(), ...)
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
	local version, subversion, patch = strsplit(".", EasyDestroy.Version)
	version, subversion, patch = tonumber(version), tonumber(subversion), tonumber(patch)

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

	return data
end






