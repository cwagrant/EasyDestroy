local filter = EasyDestroyFilterCriteria:New("Item Count", "count", 20)

function filter:Initialize()
    
    self.frame = self.frame or CreateFrame("Frame", nil, self.parent, "EasyDestroyEditBoxTemplate")
    self.frame:SetLabel( filter.name .. ":")
    self.frame:SetNumeric(true)

    self.frame:Hide()
    
    self.scripts.OnEditFocusLost = { self.frame.input, }

end

-- check input vs item values
function filter:Check(input, item)

    if self.frame and item and item.count then
        return item.count >= input
    end
    
    return false 
end

function filter:GetValues()
    if self.frame then
        if self.frame.input:GetNumber() ~= "" then
            return self.frame.input:GetNumber()
        end   
    else
        return nil
    end
end

function filter:SetValues(setvalueinput)
    if self.frame then
        self.frame.input:SetNumber(setvalueinput or "")
    end
end

function filter:Clear()
    if self.frame then
        self.frame.input:SetNumber("")
    end
end

EasyDestroy:RegisterCriterion(filter)