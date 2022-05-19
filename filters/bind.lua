local filter = EasyDestroyFilterCriteria:New("Item Binding", "bind", 60)

local SOULBOUND = 0x01
local UNBOUND = 0x02

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:Initialize()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    self.frame = self.frame or CreateFrame("Frame", nil, self.parent)

    self.label = self.frame:CreateFontString(self.frame, "OVERLAY", "GameFontNormalSmall")
    self.label:SetPoint("CENTER", self.frame, "TOP", 0, -10)
    self.label:SetText(self.name)
    
    self.soulbound = self.soulbound or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
    self.soulbound:SetPoint("TOPLEFT", 24, -16)
    self.soulbound:SetLabel("Include Soulbound Items?")

    self.unbound = self.unbound or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
    self.unbound:SetPoint("TOPLEFT", self.soulbound, "BOTTOMLEFT")
    self.unbound:SetLabel("Include Unbound (BOE) Items?")

    self.frame:Hide()
    
    self.scripts.OnClick = { self.soulbound.Checkbutton, self.unbound.Checkbutton}

end

-- check input vs item values
function filter:Check(input, item)
    if filter.frame then

        local includeBound = (bit.band(input, SOULBOUND) > 0)
        local includeUnbound = (bit.band(input, UNBOUND) > 0)

        if includeBound and includeUnbound then
            return true
        elseif includeBound then
            return (includeBound == item.soulbound)
        elseif includeUnbound then
            return ( includeUnbound == (not item.soulbound))
        else
            return false
        end
    end
    return false
end

function filter:GetValues()
    if self.frame then

        local out = 0x00

        if self.soulbound:GetChecked() then out = bit.bor(out, SOULBOUND) end

        if self.unbound:GetChecked() then out = bit.bor(out, UNBOUND) end

        return out

    end
    return 0x00
end

function filter:SetValues(values)
    if self.frame then
        self.soulbound:SetChecked( bit.band(values, SOULBOUND)>0 )
        self.unbound:SetChecked( bit.band(values, UNBOUND)>0 )
    end
end

function filter:Clear()
    if self.frame then
        self.soulbound:SetChecked(false)
        self.unbound:SetChecked(false)
    end
end
EasyDestroy.Filters.RegisterCriteria(filter)