EasyDestroy = {}

--[[ Modules ]]
EasyDestroy.Favorites = {}
-- EasyDestroyFilters = {} -- Until 2.0 this was a frame, as of 3.0 this is no longer used.
EasyDestroy.Enum = {}
EasyDestroy.Dict = {}
EasyDestroy.Data = {}
EasyDestroy.UI = {}
EasyDestroy.Handlers = {}
EasyDestroy.API = {}


--[[ Settings/Info ]]
EasyDestroy.Version =  GetAddOnMetadata("EasyDestroy", "version")
EasyDestroy.DebugActive = false
EasyDestroy.AddonName = "EasyDestroy"
EasyDestroy.AddonLoaded = false
-- This is the name of the frame that filter types attach to for scrolling
EDFILTER_SCROLL_CHILD = "EasyDestroySelectedFiltersScrollChild"

EASY_DESTROY_CATEGORY = "EasyDestroy"
_G["BINDING_NAME_CLICK EasyDestroyButton:LeftButton"] = "Destroy Button"

EasyDestroy.ProcessingItemCombine = false

--[[ Utility Tables/Variables ]]
EasyDestroy.CurrentFilter = {}
EasyDestroy.EmptyFilter = { filter={}, properties={} }
EasyDestroy.Cache = { ItemCache = {}, FilterCache = {}}
EasyDestroy.FrameRegistry = {}
EasyDestroy.SessionBlacklist = {}

EasyDestroy.FilterChanged = false
EasyDestroy.UpdateSkin = false
EasyDestroy.PlayerMoving = false

EasyDestroy.Warnings = {}
EasyDestroy.Warnings.LootOpen = false
EasyDestroy.WarnedLootOpen = false
EasyDestroy.DataLoaded = false

EasyDestroy.CriteriaRegistry = {}
EasyDestroy.CriteriaStack = {}

EasyDestroy.DebugFrame = nil
EasyDestroy.DebugState = nil
ED_LOG_DEBUG = 0x01
ED_LOG_INFO = 0x02
ED_LOG_ERROR = 0x04


--[[ Enumerations/Lookup Tables ]]
EasyDestroy.Enum.FilterTypes = { Search=1, Blacklist=2 }
EasyDestroy.Enum.Errors = { None=1, Name=2, Favorite=3 }
EasyDestroy.Enum.Actions = { 
	None = 0x0000, 
	Disenchant=0x0001, Mill=0x0002, Prospect=0x0004, 
	MassDestroy=0x0010,
	IncludeBank=0x0100
}

EasyDestroy.Dict.Strings = {}
EasyDestroy.Dict.Strings.CriteriaSelectionDropdown = "Select filter criteria..."
EasyDestroy.Dict.Strings.FilterSelectionDropdownNew = "New filter..."




-- Do I want to allow a filter to be available to multiple actions?
-- If it is - what determines the "destroy" action.

function EasyDestroy.ItemTypeFilterByFlags(flag)

	local out = {}

	for k, v in pairs(EasyDestroy.Dict.Actions) do 
		local chk = bit.band(k, flag)
		if chk > 0 then
			for k,v in pairs(v.itemTypes) do
				tinsert(out, v)
			end
		end
	end

	return out

end

-- 773 = mill, 755 prospect
EasyDestroy.Dict.Strings.MassDestroyMacro = "/cast %1$s \n/run C_TradeSkillUI.CraftRecipe(%2$d, 1);\n/cast %1$s";
EasyDestroy.Dict.Strings.DestroyMacro = "/cast %s\n/use %d %d"

EasyDestroy.Dict.Actions = {}

EasyDestroy.Dict.Actions[1] = {
	spellID = 13262,
	itemTypes = {{itype=LE_ITEM_CLASS_WEAPON, stype=nil}, {itype=LE_ITEM_CLASS_ARMOR, stype=nil}},
}

EasyDestroy.Dict.Actions[2] = {
	spellID = 51005,
	itemTypes = {{itype=LE_ITEM_CLASS_TRADEGOODS, stype=9}},
	tradeskill = 773,
}

EasyDestroy.Dict.Actions[4] = {
	spellID = 31252,
	itemTypes = {{itype=LE_ITEM_CLASS_TRADEGOODS, stype=7}},
	tradeskill = 755,
	
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
		EasyDestroy.Debug("EasyDestroy.RegisterFrame", ftype, frame:GetName())
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

local function handler(...)
	local ret = ""
	for k, v in ipairs({...}) do
		if tostring(v) then v = tostring(v) end
		ret = ret .. v .. " "
	end

	return ret
end

function EasyDestroy.Debug(...)

	if EasyDestroy.DebugActive then
		if EasyDestroy.DebugFrame then
			EasyDestroy.DebugFrame:AddMessage(date("[%H:%M:%S]") .. " " .. handler(...) .. "\n")
		else
			print(date(), ...)
		end

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

	if (version > 1) then
		if data.Options and data.Options.Actions == nil then
			data.Options.Actions = EasyDestroy.Enum.Actions.Disenchant
		end
	end

	return data
end






