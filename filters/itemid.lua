local filter = EasyDestroyFilterCriteria:New("Item ID", "id", 20)

function filter:Initialize()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    self.frame = self.frame or CreateFrame("Frame", "EDFilterItemID", self.parent, "EasyDestroyEditBoxTemplate")
    self.frame.label:SetText( filter.name .. ":")
    self.frame.input:SetNumeric(true)

    self.scripts.OnEditFocusLost = { self.frame.input, }

    self.frame:Hide()

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
    
    if self.frame then
        if self.frame.input:GetNumber() ~= 0 then
            return self.frame.input:GetNumber()  
        end   
    else
        return nil
    end
end

function filter:SetValues(setvalueinput)
    if self.frame then
        self.frame.input:SetText(setvalueinput or "")
    end
end

function filter:Clear()
    if self.frame then
        self.frame.input:SetText("")
    end
end

EasyDestroy:RegisterCriterion(filter)