local EasyDestroyFilters = EasyDestroyFilters
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
function filter:GetFilterFrame()
    -- We create the frame here, we'll leave the details on size/anchors to the Filters window.
    filter.frame = filter.frame or CreateFrame("Frame", "EDFilterSoulbound", filter.parent, "EasyDestroyRarityFilter")
    filter.frame.label:SetText( filter.name)
	filter.frame.common.label:SetText("|c11ffffff" .. "Common" .. "|r")
	filter.frame.rare.label:SetText("|c110070dd" .. "Rare" .. "|r")
	filter.frame.uncommon.label:SetText("|c111eff00" .. "Uncommon" .. "|r")
	filter.frame.epic.label:SetText("|c11a335ee" .. "Epic" .. "|r")
    return filter.frame
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

function filter.GetRarityChecked(rarityType)
    rarityType = string.lower(rarityType)
    if filter.frame then
        if filter.frame[rarityType] then
            if filter.frame[rarityType]:GetChecked() then
                return true
            end
        end
        return false
    end
    return nil
end

function filter:GetValues()
    if filter.frame then
        local quality = {}
        for key, value in pairs(Enum.ItemQuality) do
            if filter.GetRarityChecked(key) then
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
    if filter.frame and values ~= nil then
        for iqname, iqvalue in pairs(Enum.ItemQuality) do
            if tContains(values, iqvalue) then 
                local quality = string.lower(iqname)
                if filter.frame[quality] then
                    filter.frame[quality]:SetChecked(true)
                end
            end
        end
    end
end

function filter:Clear()
    if filter.frame then
        for iqname, iqvalue in pairs(Enum.ItemQuality) do
            local quality = string.lower(iqname)
            if filter.frame[quality] then
                filter.frame[quality]:SetChecked(false)
            end
        end
    end
end

EasyDestroyFilters:RegisterFilterCriterion(filter)