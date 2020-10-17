EasyDestroy = {}
EasyDestroy.Version =  1
EasyDestroy.DebugActive = true
EasyDestroy.AddonName = "EasyDestroy"
EasyDestroy.AddonLoaded = false
EasyDestroy.CurrentFilter = {}
EasyDestroy.FilterChanged = false

EasyDestroy.DestroyTypes = {}
EasyDestroy.DestroyTypes.DISENCHANT = "DISENCHANT"
EasyDestroy.DestroyTypes.MILL = "MILL"
EasyDestroy.DestroyTypes.PROSPECT = "PROSPECT"

EasyDestroy.DestroyFilters = {}
EasyDestroy.DestroyFilters[EasyDestroy.DestroyTypes.DISENCHANT] = {{itype=LE_ITEM_CLASS_WEAPON, stype=nil}, {itype=LE_ITEM_CLASS_ARMOR, stype=nil}}

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

EasyDestroy.Quality = {}
EasyDestroy.Quality.COMMON = 1
EasyDestroy.Quality.UNCOMMON = 2
EasyDestroy.Quality.RARE = 3
EasyDestroy.Quality.EPIC = 4

EasyDestroy.DataLoaded = false
EasyDestroy.Data = {}
EasyDestroy.FilterCount = 0
EasyDestroy.EmptyFilter = {filter={}, properties={}}

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

function EasyDestroy:Debug(...)
	if EasyDestroy.DebugActive then
		print(...)
	end
end

function EasyDestroy:CreateBG(frame, r, g, b)
	local bg = frame:CreateTexture(nil, "BACKGROUND");
	bg:SetAllPoints(true);
	bg:SetColorTexture(r, g, b, 0.5);
end

