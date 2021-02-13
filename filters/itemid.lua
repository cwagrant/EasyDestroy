--[[
Registerable filters require 4 things.
1) A UI/Frame to show.
2) Either using available information about the item, or provide a function to get the information you want to check against.
3) A Check function to determine if the item meets the criteria of the filter.
4) A call to EasyDestroy/EasyDestroyFilters to register the filter as useable.


]]

local filter = {}

EasyDestroyFilters = EasyDestroyFilters

filter.name="Item ID"
filter.key = "id"
filter.frame = nil
filter.height = 20
filter.parent = _G[EDFILTER_SCROLL_CHILD]

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:GetFilterFrame()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    filter.frame = filter.frame or CreateFrame("Frame", "EDFilterItemID", filter.parent, "EasyDestroyEditBoxTemplate")
    filter.frame.label:SetText( filter.name .. ":")
    filter.frame.input:SetNumeric(true)
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
function filter:Check(inputid, item)
    local itemid = item.id
    if inputid==itemid then 
        return true 
    end 
    
    return false 
end

function filter:GetValues()
    
    if filter.frame then
        if filter.frame.input:GetNumber() ~= 0 then
            return filter.frame.input:GetNumber()  
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

function filter.IsShown()
    if filter.frame then
        return filter.frame:IsShown()
    end
    return false
end

function filter:Clear()
    if filter.frame then
        filter.frame.input:SetText("")
    end
end

EasyDestroyFilters:RegisterFilter(filter)