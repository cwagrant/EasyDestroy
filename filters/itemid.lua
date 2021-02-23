--[[
Registerable filters require 4 things.
1) A UI/Frame to show.
2) Either using available information about the item, or provide a function to get the information you want to check against.
3) A Check function to determine if the item meets the criteria of the filter.
4) A call to EasyDestroy/EasyDestroyFilters to register the filter as useable.


]]
EasyDestroyFilters = EasyDestroyFilters
local filter = EasyDestroyFilterCriteria:New("Item ID", "id", 20)

function filter:GetFilterFrame()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    filter.frame = filter.frame or CreateFrame("Frame", "EDFilterItemID", filter.parent, "EasyDestroyEditBoxTemplate")
    filter.frame.label:SetText( filter.name .. ":")
    filter.frame.input:SetNumeric(true)
    return filter.frame
end

-- check input vs item values
function filter:Check(inputid, item)
    local itemid = item.itemID
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

function filter:Clear()
    if filter.frame then
        filter.frame.input:SetText("")
    end
end

EasyDestroyFilters:RegisterFilterCriterion(filter)