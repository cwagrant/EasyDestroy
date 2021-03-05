--[[
Registerable filters require 4 things.
1) A UI/Frame to show.
2) Either using available information about the item, or provide a function to get the information you want to check against.
3) A Check function to determine if the item meets the criteria of the filter.
4) A call to EasyDestroy/EasyDestroyFilters to register the filter as useable.


]]

local filter = EasyDestroyFilterCriteria:New("Item Level", "level", 20)

-- EasyDestroy passes 3 values to this function, itemlink, bag, and slot. 
-- function filter:GetItemInfo(ilink)
--     return select(1, GetDetailedItemLevelInfo(ilink))
-- end

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:Initialize()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    self.frame = self.frame or CreateFrame("Frame", "EDFilterItemLevel", self.parent, "EasyDestroyEditBoxRangeTemplate")
    self.frame.label:SetText( filter.name .. ":")
	self.frame.inputfrom:SetNumeric(true)
    self.frame.inputto:SetNumeric(true)

    self.scripts.OnEditFocusLost = { self.frame.inputfrom, self.frame.inputto }

    self.frame:Hide()


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
    if self.frame then
        local inputfrom = self.frame.inputfrom:GetNumber() or 0
	    local inputto = self.frame.inputto:GetNumber() or 0

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
    if self.frame then
        if type(values) == "table" then
            self.frame.inputfrom:SetText(values.levelfrom)
            self.frame.inputto:SetText(values.levelto)
        else
            self.frame.inputfrom:SetText(values)
        end
    end

end

function filter:Clear()
    if self.frame then
        self.frame.inputfrom:SetText("")
        self.frame.inputto:SetText("")
    end
end

EasyDestroy:RegisterCriterion(filter)