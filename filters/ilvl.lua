--[[
Registerable filters require 4 things.
1) A UI/Frame to show.
2) Either using available information about the item, or provide a function to get the information you want to check against.
3) A Check function to determine if the item meets the criteria of the filter.
4) A call to EasyDestroy/EasyDestroyFilters to register the filter as useable.


]]

local filter = {}

local EasyDestroyFilters = EasyDestroyFilters

function filter:RegisterFilter()
    -- give the filter a name (not currently used), a key, and a blank frame.
    filter.name="Item Level"
    filter.key = "level"
    filter.frame = nil
    filter.height = 20
    filter.width = 100
    --filter.getiteminfo = filter.GetItemInfo
    EasyDestroyFilters[filter.key] = filter.Check
    EasyDestroyFilters.Registry[filter.key] = filter
    --quick and dirty, need to have some kind of function on the part of the addon to do this
    UIDropDownMenu_Initialize(EasyDestroyFilterTypes, EasyDestroy_InitFilterTypes)
end

-- EasyDestroy passes 3 values to this function, itemlink, bag, and slot. 
function filter:GetItemInfo(ilink)
    return select(1, GetDetailedItemLevelInfo(ilink))
end
-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:GetFilterFrame()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    filter.frame = filter.frame or CreateFrame("Frame", "EDFilterItemLevel", EasyDestroyFilters, "EasyDestroyEditBoxRangeTemplate")
    filter.frame.label:SetText( filter.name .. ":")
	filter.frame.inputfrom:SetNumeric(true)
    filter.frame.inputto:SetNumeric(true)
    return filter.frame
end

function filter:Toggle()
    if filter.frame:IsShown() then
        filter.frame:Hide()
    else
        filter.frame:Show()
    end
end


-- check input vs item values
function filter:Check(inputlevel, item)
    local itemlevel = item.level
	if itemlevel == nil then
		return false
	elseif type(inputlevel) ~= "table" then
		if inputlevel == itemlevel then
			return true
		end
	elseif itemlevel >= inputlevel['levelfrom'] and itemlevel <= inputlevel['levelto'] then
		return true
	end
	return false
end

function filter:GetValues()
    if filter.frame then
        local inputfrom = filter.frame.inputfrom:GetNumber() or 0
	    local inputto = filter.frame.inputto:GetNumber() or 0

        if inputto ~= 0 and inputto ~= nil then
            if inputfrom ~= nil then
                return {levelfrom=inputfrom, levelto=inputto}
            end
        end

        if inputfrom ~=0 and inputfrom ~= nil then
            return inputfrom
        end
    end
    return nil
    
end

function filter:SetValues(values)
    if filter.frame then
        if type(values) == "table" then
            filter.frame.inputfrom:SetText(values.levelfrom)
            filter.frame.inputto:SetText(values.levelto)
        else
            filter.frame.inputfrom:SetText(values)
        end
    end

end

function filter.IsShown()
    if filter.frame then
        return filter.frame:IsShown()
    end
    return false
end

function filter:Clear()
    if filter.frame then
        filter.frame.inputfrom:SetText("")
        filter.frame.inputto:SetText("")
    end
end

filter:RegisterFilter()