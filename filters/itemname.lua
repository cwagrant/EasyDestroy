--[[
Registerable filters require 4 things.
1) A UI/Frame to show.
2) Either using available information about the item, or provide a function to get the information you want to check against.
3) A Check function to determine if the item meets the criteria of the filter.
4) A call to EasyDestroy/EasyDestroyFilters to register the filter as useable.


]]
local EasyDestroyFilters = EasyDestroyFilters
local filter = EasyDestroyFilterCriteria:New("Item Name", "name", 20)

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:GetFilterFrame()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    filter.frame = filter.frame or CreateFrame("Frame", "EDFilterItemName", filter.parent, "EasyDestroyEditBoxTemplate")
    filter.frame.label:SetText( filter.name .. ":")
    return filter.frame
end

-- check input vs item values
function filter:Check(inputname, item)
    local itemname = item.name
    if string.find(string.lower(itemname or ""), string.lower(inputname or "")) then 
        return true 
    end 
    
    return false 
end

function filter:GetValues()
    if filter.frame then
        if filter.frame.input:GetText() ~= "" then
            return filter.frame.input:GetText()    
        end   
    else
        return nil
    end
end

function filter:SetValues(setvalueinput)
    if filter.frame then
        filter.frame.input:SetText(setvalueinput or "")
    end
end

function filter:Clear()
    if filter.frame then
        filter.frame.input:SetText("")
    end
end

EasyDestroyFilters:RegisterFilterCriterion(filter)