local filter = EasyDestroyFilterCriteria:New("Item Quality", "quality", 65)

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made

function filter:Initialize()
    self.frame = self.frame or CreateFrame("Frame", "EDFilterQuality", filter.parent, "EasyDestroyRarityFilter")
    self.frame.label:SetText( filter.name)
	self.frame.common:SetLabel("|c11ffffff" .. "Common" .. "|r")
	self.frame.rare:SetLabel("|c110070dd" .. "Rare" .. "|r")
	self.frame.uncommon:SetLabel("|c111eff00" .. "Uncommon" .. "|r")
	self.frame.epic:SetLabel("|c11a335ee" .. "Epic" .. "|r")
    
    -- Don't want to show it yet
    self.frame:Hide()

    self.scripts.OnClick = { filter.frame.common, filter.frame.uncommon, filter.frame.rare, filter.frame.epic }

end

-- check input vs item values
function filter:Check(inputquality, item)
    local itemquality = item.quality
    if self.frame then
        if tContains(inputquality, itemquality) then
            return true
        end
        return false
    end
    return false
end


function filter:GetRarityChecked(rarityType)
    rarityType = string.lower(rarityType)
    if self.frame then
        if self.frame[rarityType] then
            if self.frame[rarityType]:GetChecked() then
                return true
            end
        end
        return false
    end
    return nil
end

function filter:GetValues()
    if self.frame then
        local quality = {}
        for key, value in pairs(Enum.ItemQuality) do
            if self:GetRarityChecked(key) then
                tinsert(quality, value)
            end
        end
        if next(quality) == nil then
            return nil
        else
            return quality
        end
    end
    return nil
    
end

function filter:SetValues(values)
    if self.frame and values ~= nil then
        for iqname, iqvalue in pairs(Enum.ItemQuality) do
            if tContains(values, iqvalue) then 
                local quality = string.lower(iqname)
                if self.frame[quality] then
                    self.frame[quality]:SetChecked(true)
                end
            end
        end
    end
end

function filter:Clear()
    if self.frame then
        for iqname, iqvalue in pairs(Enum.ItemQuality) do
            local quality = string.lower(iqname)
            if self.frame[quality] then
                self.frame[quality]:SetChecked(false)
            end
        end
    end
end


EasyDestroy:RegisterCriterion(filter)