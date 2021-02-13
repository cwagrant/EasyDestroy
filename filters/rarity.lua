--[[
Registerable filters require 4 things.
1) A UI/Frame to show.
2) Either using available information about the item, or provide a function to get the information you want to check against.
3) A Check function to determine if the item meets the criteria of the filter.
4) A call to EasyDestroy/EasyDestroyFilters to register the filter as useable.


]]

local filter = {}

local EasyDestroyFilters = EasyDestroyFilters

filter.name="Item Quality"
filter.key = "quality"
filter.frame = nil
filter.height = 65
filter.parent = _G[EDFILTER_SCROLL_CHILD]

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:GetFilterFrame()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    filter.frame = filter.frame or CreateFrame("Frame", "EDFilterQuality", filter.parent, "EasyDestroyRarityFilter")
    filter.frame.label:SetText( filter.name)
	filter.frame.common.label:SetText("|c11ffffff" .. "Common" .. "|r")
	filter.frame.rare.label:SetText("|c110070dd" .. "Rare" .. "|r")
	filter.frame.uncommon.label:SetText("|c111eff00" .. "Uncommon" .. "|r")
	filter.frame.epic.label:SetText("|c11a335ee" .. "Epic" .. "|r")
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
function filter:Check(inputquality, item)
    local itemquality = item.quality
    if filter.frame then
        if tContains(inputquality, itemquality) then
            return true
        end
        return false
    end
    return false
end


function filter.GetRarityChecked(rarityType)
    rarityType = string.lower(rarityType)
    if filter.frame then
        if filter.frame[rarityType] then
            if filter.frame[rarityType]:GetChecked() then
                return true
            end
        end
        return false
    end
    return nil
end

function filter:GetValues()
    if filter.frame then
        local quality = {}
        for key, value in pairs(Enum.ItemQuality) do
            if filter.GetRarityChecked(key) then
                tinsert(quality, value)
            end
        end
        if next(quality) == nil then
            return nil
        else
            return quality
        end
    end
    return nil
    
end

function filter:SetValues(values)
    if filter.frame and values ~= nil then
        for iqname, iqvalue in pairs(Enum.ItemQuality) do
            if tContains(values, iqvalue) then 
                local quality = string.lower(iqname)
                if filter.frame[quality] then
                    filter.frame[quality]:SetChecked(true)
                end
            end
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
        for iqname, iqvalue in pairs(Enum.ItemQuality) do
            local quality = string.lower(iqname)
            if filter.frame[quality] then
                filter.frame[quality]:SetChecked(false)
            end
        end
    end
end


EasyDestroyFilters:RegisterFilter(filter)