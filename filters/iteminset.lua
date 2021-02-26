local EasyDestroyFilters = EasyDestroyFilters

local filter = EasyDestroyFilterCriteria:New("Ignore Items in Equipment Sets", "eqset", 20)

function filter:GetFilterFrame()
    filter.frame = filter.frame or CreateFrame("Frame", "EDFilterItemInSet", filter.parent)
    filter.checkbox = filter.checkbox or CreateFrame("CheckButton", "EDFilterItemInSetCheck", filter.frame, "EasyDestroyCheckboxTemplate")
    filter.checkbox:SetPoint("LEFT")
    filter.checkbox.label:SetText(filter.name)
    filter.checkbox:SetScript("OnClick", EasyDestroy_Refresh)
    return filter.frame
end

function filter:GetItemInfo(itemlink, bag, slot)
	local sets = C_EquipmentSet.GetEquipmentSetIDs();
	
	for _, setid in pairs(sets) do
		local items = C_EquipmentSet.GetItemLocations(setid)
		if items then
			for _, locid in pairs(items) do
				local equipped, bank, bags, void, slotnum, bagnum = EquipmentManager_UnpackLocation(locid);
				if bagnum==bag and slotnum==slot then
					return true
				end
			end
		end
	end
	return false
end

function filter:Check(excludeset, item)
    local inset = item.eqset
    if excludeset and inset then 
        return false
    else
        return true
    end

end

function filter:Blacklist(excludeset, item)
    local inset = item.eqset
    if excludeset and inset then
        return true
    else
        return false
    end
end


function filter:GetValues()
    if filter.frame then
        if filter.checkbox:GetChecked() then
            return true
        else
            return false
        end
    end
    return nil
end

function filter:SetValues(values)
    if filter.frame then
        if values == "" then
            filter.checkbox:SetChecked(false)
        else
            filter.checkbox:SetChecked(values)
        end
    end
end

function filter:Clear()
    if filter.frame then
        filter.checkbox:SetChecked(false)
    end
end

EasyDestroy:RegisterCriterion(filter)