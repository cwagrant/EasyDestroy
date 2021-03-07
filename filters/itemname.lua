local filter = EasyDestroyFilterCriteria:New("Item Name", "name", 20)

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:Initialize()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    self.frame = self.frame or CreateFrame("Frame", "EDFilterItemName", self.parent, "EasyDestroyEditBoxTemplate")
    self.frame:SetLabel( filter.name .. ":")

    self.frame:Hide()
    
    self.scripts.OnEditFocusLost = { self.frame.input, }

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
    if self.frame then
        if self.frame.input:GetText() ~= "" then
            return self.frame.input:GetText()    
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

EasyDestroy.Filters.RegisterCriteria(filter)