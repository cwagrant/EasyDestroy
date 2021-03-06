local filter = EasyDestroyFilterCriteria:New("Ignore BOE Items By Quality", "boequality", 65)

function filter:GetItemInfo(itemLink, bag, slot)
    local itemLoc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    local isBound = C_Item.IsBound(itemLoc)
    return isBound
end

-- There's no reason a filter should show up more than once
-- So we can treat it as a singleton and just use this to
-- get any previous creations of the filter frame, or
-- create it if it's not yet been made
function filter:Initialize()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    self.frame = self.frame or CreateFrame("Frame", "EDFilterSoulbound", self.parent, "EasyDestroyRarityFilter")
    self.frame.label:SetText( self.name )
	self.frame.common:SetLabel("|c11ffffff" .. "Common" .. "|r")
	self.frame.rare:SetLabel("|c110070dd" .. "Rare" .. "|r")
	self.frame.uncommon:SetLabel("|c111eff00" .. "Uncommon" .. "|r")
	self.frame.epic:SetLabel("|c11a335ee" .. "Epic" .. "|r")

    self.frame:Hide()
    
    self.scripts.OnClick = { self.frame.common, self.frame.uncommon, self.frame.rare, self.frame.epic }
    
end

-- check input vs item values
function filter:Check(inputquality, item)
    if filter.frame then
        local itemquality = item.quality
        local itembound = item.boequality
        local bindtype = item.bindtype
        
        if bindtype == LE_ITEM_BIND_ON_EQUIP then
            if tContains(inputquality, itemquality) and not(item.boequality) then
                return false
            end
        end

    end
    return true
end

function filter:Blacklist(inputquality, item)
    if filter.frame then
        local itemquality = item.quality
        local itembound = item.boequality
        local bindtype = item.bindtype

        if bindtype == LE_ITEM_BIND_ON_EQUIP then
            if tContains(inputquality, itemquality) and not(item.boequality) then
                return true
            end
        end
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

EasyDestroy.Filters.RegisterCriteria(filter)