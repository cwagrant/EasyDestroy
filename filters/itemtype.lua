
local filter = EasyDestroyFilterCriteria:New("Item Types", "type", 60)

local GEAR = 0x01
local HERB = 0x02 -- 9
local ORE = 0x04 -- 7

function filter:Initialize()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    self.frame = self.frame or CreateFrame("Frame", nil, self.parent)

    self.label = self.frame:CreateFontString(self.frame, "OVERLAY", "GameFontNormalSmall")
    self.label:SetPoint("CENTER", self.frame, "TOP", 0, -10)
    self.label:SetText(self.name)

    
    self.includeGear = self.includeGear or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
    self.includeGear:SetPoint("TOPLEFT", 24, -16)
    self.includeGear:SetLabel("Equipment")
    
    self.includeHerbs = self.includeHerbs or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
    self.includeHerbs:SetPoint("LEFT", self.frame, "CENTER", 24, 0)
    self.includeHerbs:SetLabel("Herbs")

    self.includeOre = self.includeOre or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
    self.includeOre:SetPoint("TOPLEFT", self.includeGear, "BOTTOMLEFT")
    self.includeOre:SetLabel("Ore") 
    
    self.scripts.OnClick = { self.includeGear.Checkbutton, self.includeHerbs.Checkbutton, self.includeOre.Checkbutton }

    self.frame:Hide()

end

-- check input vs item values
function filter:Check(input, item)

    if self.frame then
        if item.classID == LE_ITEM_CLASS_ARMOR or item.classID == LE_ITEM_CLASS_WEAPON then 
            return (bit.band(input, GEAR) > 0)
        elseif item.classID == LE_ITEM_CLASS_TRADEGOODS then
            if item.subclassID == 7 then
                return (bit.band(input, ORE) > 0)
            elseif item.subclassID == 9 then
                return (bit.band(input, HERB) > 0)
            end
        end
    end

    return false
end

function filter:GetValues()

    if self.frame then

        local out = 0x00

        if self.includeGear:GetChecked() then out = bit.bor(out, GEAR) end

        if self.includeHerbs:GetChecked() then out = bit.bor(out, HERB) end

        if self.includeOre:GetChecked() then out = bit.bor(out, ORE) end

        return out

    end

    return 0x00
    
end

function filter:SetValues(values)

    if self.frame then

        self.includeGear:SetChecked( bit.band(values, GEAR)>0 )
        self.includeHerbs:SetChecked( bit.band(values, HERB)>0 )
        self.includeOre:SetChecked( bit.band(values, ORE)>0 )

    end

end

function filter:Clear()
    if self.frame then
        
        self.includeGear:SetChecked(false)
        self.includeHerbs:SetChecked(false)
        self.includeOre:SetChecked(false)
    end
end

EasyDestroy.Filters.RegisterCriteria(filter)