local filter = EasyDestroyFilterCriteria:New("Item Binding", "bind", 84)

local SOULBOUND = 0x01
local UNBOUND = 0x02
local WARBOUND = 0x04

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:Initialize()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    self.frame = self.frame or CreateFrame("Frame", nil, self.parent)

    self.label = self.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    self.label:SetPoint("CENTER", self.frame, "TOP", 0, -10)
    self.label:SetText(self.name)
    
    self.soulbound = self.soulbound or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
    self.soulbound:SetPoint("TOPLEFT", 24, -16)
    self.soulbound:SetLabel("Include Soulbound Items?")

    self.unbound = self.unbound or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
    self.unbound:SetPoint("TOPLEFT", self.soulbound, "BOTTOMLEFT")
    self.unbound:SetLabel("Include Unbound (BOE) Items?")

    self.warbound = self.warbound or CreateFrame("Frame", nil, self.frame, "EasyDestroyFramedCheckboxTemplate")
    self.warbound:SetPoint("TOPLEFT", self.unbound, "BOTTOMLEFT")
    self.warbound:SetLabel("Include Warbound Items?")

    self.frame:Hide()
    
    self.scripts.OnClick = { self.soulbound.Checkbutton, self.unbound.Checkbutton, self.warbound.Checkbutton }

end

-- check input vs item values
function filter:Check(input, item)
    if filter.frame then

        -- Warbound items are checked first since they may also report as bound.
        if item.warbound then
            return (bit.band(input, WARBOUND) > 0)
        elseif item.soulbound then
            return (bit.band(input, SOULBOUND) > 0)
        else
            return (bit.band(input, UNBOUND) > 0)
        end
    end
    return false
end

function filter:GetValues()
    if self.frame then

        local out = 0x00

        if self.soulbound:GetChecked() then out = bit.bor(out, SOULBOUND) end

        if self.unbound:GetChecked() then out = bit.bor(out, UNBOUND) end

        if self.warbound:GetChecked() then out = bit.bor(out, WARBOUND) end

        return out

    end
    return 0x00
end

function filter:SetValues(values)
    if self.frame then
        self.soulbound:SetChecked( bit.band(values, SOULBOUND)>0 )
        self.unbound:SetChecked( bit.band(values, UNBOUND)>0 )
        self.warbound:SetChecked( bit.band(values, WARBOUND)>0 )
    end
end

function filter:Clear()
    if self.frame then
        self.soulbound:SetChecked(false)
        self.unbound:SetChecked(false)
        self.warbound:SetChecked(false)
    end
end
EasyDestroy.Filters.RegisterCriteria(filter)